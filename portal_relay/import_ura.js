// NSB Motors — URA CIF Database Importer
// Usage: node import_ura.js mv_data.csv
// Reads a CSV of URA MV CIF records and upserts them into PocketBase.

const fs   = require('fs');
const path = require('path');

const PB_URL      = process.env.PB_URL       || 'http://localhost:8090';
const ADMIN_EMAIL = process.env.PB_ADMIN_EMAIL || 'admin@nsbmotors.com';
const ADMIN_PASS  = process.env.PB_ADMIN_PASS  || 'nsb@admin2025';
const BATCH_SIZE  = 50; // records per batch (to avoid PB timeouts)

const fetch = (...args) => import('node-fetch').then(({ default: f }) => f(...args));

// ── Helpers ───────────────────────────────────────────────────────────────────

async function api(method, endpoint, body, token) {
  const res = await fetch(`${PB_URL}/api/${endpoint}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: token } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  
  if (res.status === 204) return null;
  
  const txt = await res.text();
  if (!res.ok) throw new Error(`${method} /api/${endpoint} → ${res.status}: ${txt}`);
  return txt ? JSON.parse(txt) : null;
}

function parseCSV(filePath) {
  const raw = fs.readFileSync(filePath, 'utf-8');
  const lines = raw.trim().split('\n');
  const headers = lines[0].split(',').map(h => h.replace(/^"|"$/g, '').trim());
  return lines.slice(1).map(line => {
    // Handle quoted fields that may contain commas
    const values = [];
    let cur = '', inQ = false;
    for (const ch of line) {
      if (ch === '"') { inQ = !inQ; }
      else if (ch === ',' && !inQ) { values.push(cur); cur = ''; }
      else { cur += ch; }
    }
    values.push(cur);
    const row = {};
    headers.forEach((h, i) => { row[h] = (values[i] || '').replace(/^"|"$/g, '').trim(); });
    return row;
  });
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  const csvFile = process.argv[2];
  if (!csvFile) {
    console.error('Usage: node import_ura.js <path-to-csv>');
    process.exit(1);
  }
  if (!fs.existsSync(csvFile)) {
    console.error(`File not found: ${csvFile}`);
    process.exit(1);
  }

  console.log(`Reading CSV: ${path.resolve(csvFile)}`);
  const rows = parseCSV(csvFile);
  console.log(`Parsed ${rows.length} records`);

  // ── Admin auth ─────────────────────────────────────────────────────────────
  console.log('\nAuthenticating as PocketBase admin…');
  const auth = await api('POST', 'admins/auth-with-password', {
    identity: ADMIN_EMAIL,
    password: ADMIN_PASS,
  });
  const token = auth.token;
  console.log('Admin auth OK\n');

  // ── Ensure mv_database collection exists ───────────────────────────────────
  try {
    await api('GET', 'collections/mv_database', null, token);
    console.log('Collection mv_database already exists — skipping creation');
  } catch (_) {
    console.log('Creating collection mv_database…');
    await api('POST', 'collections', {
      name: 'mv_database',
      type: 'base',
      schema: [
        { name: 'serial_number',  type: 'text'   },
        { name: 'hsc_code',       type: 'text'   },
        { name: 'country_origin', type: 'text'   },
        { name: 'make',           type: 'text',   required: true },
        { name: 'model',          type: 'text',   required: true },
        { name: 'year',           type: 'number', required: true },
        { name: 'engine_cc',      type: 'number' },
        { name: 'description',    type: 'text'   },
        { name: 'cif_usd',        type: 'number', required: true },
        { name: 'database_month', type: 'text'   },
      ],
      // Anyone authenticated can read; only admin can write
      listRule:   '@request.auth.id != ""',
      viewRule:   '@request.auth.id != ""',
      createRule: null,
      updateRule: null,
      deleteRule: null,
    }, token);
    console.log('Collection mv_database created ✓\n');
  }

  // ── Delete existing records (full refresh) ─────────────────────────────────
  console.log('Clearing existing mv_database records…');
  let page = 1;
  let deleted = 0;
  while (true) {
    const existing = await api('GET', `collections/mv_database/records?page=${page}&perPage=200`, null, token);
    if (!existing.items || existing.items.length === 0) break;
    for (const rec of existing.items) {
      await api('DELETE', `collections/mv_database/records/${rec.id}`, null, token);
      deleted++;
    }
    if (existing.items.length < 200) break;
  }
  console.log(`Cleared ${deleted} old records ✓\n`);

  // ── Import in batches ──────────────────────────────────────────────────────
  console.log(`Importing ${rows.length} records in batches of ${BATCH_SIZE}…`);
  let imported = 0, failed = 0;

  for (let i = 0; i < rows.length; i += BATCH_SIZE) {
    const batch = rows.slice(i, i + BATCH_SIZE);
    for (const row of batch) {
      const year = parseInt(row.year, 10);
      const cc   = row.engine_cc ? parseInt(row.engine_cc, 10) : null;
      const cif  = parseFloat(row.cif_usd);

      if (!row.make || !row.model || isNaN(year) || isNaN(cif)) {
        failed++;
        continue;
      }

      try {
        await api('POST', 'collections/mv_database/records', {
          serial_number:  row.serial_number  || '',
          hsc_code:       row.hsc_code       || '',
          country_origin: row.country_origin || '',
          make:           row.make,
          model:          row.model,
          year,
          engine_cc:      isNaN(cc) ? null : cc,
          description:    row.description    || '',
          cif_usd:        cif,
          database_month: row.database_month || '',
        }, token);
        imported++;
      } catch (e) {
        console.error(`  ✗ Row ${i} (${row.make} ${row.model} ${year}): ${e.message}`);
        failed++;
      }
    }

    const pct = Math.round(((i + batch.length) / rows.length) * 100);
    process.stdout.write(`\r  Progress: ${i + batch.length}/${rows.length} (${pct}%)   `);
    await sleep(50); // small pause to avoid hammering PB
  }

  console.log(`\n\nImport complete!`);
  console.log(`  ✓ Imported : ${imported}`);
  console.log(`  ✗ Failed   : ${failed}`);
}

main().catch(e => {
  console.error('\nFatal error:', e.message);
  process.exit(1);
});
