// NSB Motors - PocketBase Bootstrap
// Run once: node bootstrap.js
// Creates all collections + machine users via PocketBase Admin API

const PB_URL = process.env.PB_URL || 'http://localhost:8090';
const ADMIN_EMAIL = process.env.PB_ADMIN_EMAIL || 'admin@nsbmotors.com';
const ADMIN_PASS  = process.env.PB_ADMIN_PASS  || 'nsb@admin2025';

const fetch = (...args) => import('node-fetch').then(({default: f}) => f(...args));

async function api(method, path, body, token) {
  const r = await fetch(`${PB_URL}/api/${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? {Authorization: token} : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const txt = await r.text();
  if (!r.ok) throw new Error(`${method} /api/${path} → ${r.status}: ${txt}`);
  return JSON.parse(txt);
}

// ── Collections schema ────────────────────────────────────────────────────────

const COLLECTIONS = [
  {
    name: 'machine_users',
    type: 'auth',
    schema: [
      {name: 'machine_id',   type: 'text',   required: true},
      {name: 'machine_name', type: 'text',   required: true},
      {name: 'location',     type: 'text'},
      {name: 'is_admin',     type: 'bool',   required: false},
    ],
    // Auth collection settings
    options: {
      allowEmailAuth: true,
      allowUsernameAuth: true,
      allowOAuth2Auth: false,
      requireEmail: false,
      minPasswordLength: 8,
    },
    listRule:   '@request.auth.id != ""',
    viewRule:   '@request.auth.id != ""',
    createRule: null, // only admin
    updateRule: '@request.auth.id = id',
    deleteRule: null,
  },
  {
    name: 'customers',
    type: 'base',
    schema: [
      {name: 'machine_id',      type: 'text',   required: true},
      {name: 'name',            type: 'text',   required: true},
      {name: 'email',           type: 'email'},
      {name: 'phone',           type: 'text'},
      {name: 'address',         type: 'text'},
      {name: 'city',            type: 'text'},
      {name: 'location',        type: 'text'},
      {name: 'company',         type: 'text'},
      {name: 'notes',           type: 'text'},
      {name: 'total_spent',     type: 'number'},
      {name: 'total_invoices',  type: 'number'},
      {name: 'balance',         type: 'number'},
      {name: 'is_active',       type: 'bool'},
    ],
    listRule:   '@request.auth.record.machine_id = machine_id',
    viewRule:   '@request.auth.record.machine_id = machine_id',
    createRule: '@request.auth.id != ""',
    updateRule: '@request.auth.record.machine_id = machine_id',
    deleteRule: '@request.auth.record.machine_id = machine_id',
  },
  {
    name: 'invoices',
    type: 'base',
    schema: [
      {name: 'machine_id',          type: 'text',   required: true},
      {name: 'invoice_number',      type: 'text',   required: true},
      {name: 'invoice_type',        type: 'text'},   // carSale | invoice | quotation
      {name: 'customer_id',         type: 'text',   required: true}, // PB record id
      {name: 'customer_name',       type: 'text'},   // denormalized
      {name: 'invoice_date',        type: 'text'},
      {name: 'due_date',            type: 'text'},
      {name: 'status',              type: 'text'},   // draft|pending|paid|overdue|cancelled
      // Vehicle
      {name: 'stock_no',            type: 'text'},
      {name: 'vehicle_make',        type: 'text'},
      {name: 'vehicle_model',       type: 'text'},
      {name: 'vehicle_model_suffix',type: 'text'},
      {name: 'vehicle_year',        type: 'number'},
      {name: 'chassis_no',          type: 'text'},
      {name: 'engine_size',         type: 'text'},
      {name: 'fuel_type',           type: 'text'},
      {name: 'transmission',        type: 'text'},
      {name: 'color',               type: 'text'},
      {name: 'country_of_origin',   type: 'text'},
      // Phase 1 USD
      {name: 'car_price_usd',       type: 'number'},
      {name: 'clearance_fee_usd',   type: 'number'},
      {name: 'exchange_rate',       type: 'number'},
      {name: 'first_installment_ugx',type: 'number'},
      // Phase 2 UGX
      {name: 'taxes_ura',           type: 'number'},
      {name: 'number_plates_fee',   type: 'number'},
      {name: 'third_party_insurance',type: 'number'},
      {name: 'agency_fees',         type: 'number'},
      {name: 'second_installment_ugx',type: 'number'},
      // Totals
      {name: 'total_amount',        type: 'number'},
      {name: 'paid_amount',         type: 'number'},
      {name: 'balance_amount',      type: 'number'},
      // Line items JSON
      {name: 'items',               type: 'json', options: {maxSize: 2000000}},
      {name: 'notes',               type: 'text'},
      {name: 'terms',               type: 'text'},
      {name: 'is_finalized',        type: 'bool'},
    ],
    listRule:   '@request.auth.record.machine_id = machine_id',
    viewRule:   '@request.auth.record.machine_id = machine_id',
    createRule: '@request.auth.id != ""',
    updateRule: '@request.auth.record.machine_id = machine_id',
    deleteRule: '@request.auth.record.machine_id = machine_id',
  },
  {
    name: 'payments',
    type: 'base',
    schema: [
      {name: 'machine_id',    type: 'text',   required: true},
      {name: 'invoice_id',    type: 'text',   required: true},
      {name: 'customer_id',   type: 'text',   required: true},
      {name: 'amount',        type: 'number', required: true},
      {name: 'payment_date',  type: 'text'},
      {name: 'method',        type: 'text'},   // cash|bank|mobile_money
      {name: 'reference',     type: 'text'},
      {name: 'notes',         type: 'text'},
    ],
    listRule:   '@request.auth.record.machine_id = machine_id',
    viewRule:   '@request.auth.record.machine_id = machine_id',
    createRule: '@request.auth.id != ""',
    updateRule: '@request.auth.record.machine_id = machine_id',
    deleteRule: '@request.auth.record.machine_id = machine_id',
  },
];

// ── Machine users ─────────────────────────────────────────────────────────────

const MACHINES = [
  {username: 'M001', password: 'reception2025', machine_id: 'M001', machine_name: 'Reception PC',  location: 'Front Desk'},
  {username: 'M002', password: 'sales2025',     machine_id: 'M002', machine_name: 'Sales Office',  location: 'Sales Room'},
  {username: 'M003', password: 'manager2025',   machine_id: 'M003', machine_name: 'Manager PC',    location: 'Manager Office', is_admin: true},
  {username: 'M004', password: 'accounts2025',  machine_id: 'M004', machine_name: 'Accounts PC',   location: 'Accounts'},
];

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  console.log('Authenticating as PocketBase admin...');
  const auth = await api('POST', 'admins/auth-with-password', {identity: ADMIN_EMAIL, password: ADMIN_PASS});
  const token = auth.token;
  console.log('Admin auth OK');

  // Create collections
  for (const col of COLLECTIONS) {
    try {
      await api('POST', 'collections', col, token);
      console.log(`Created collection: ${col.name}`);
    } catch (e) {
      if (e.message.includes('already exist') || e.message.includes('unique')) {
        console.log(`Collection already exists: ${col.name}`);
      } else {
        console.error(`Failed to create ${col.name}:`, e.message);
      }
    }
  }

  // Create machine users
  for (const m of MACHINES) {
    try {
      await api('POST', 'collections/machine_users/records', {
        username: m.username,
        password: m.password,
        passwordConfirm: m.password,
        machine_id: m.machine_id,
        machine_name: m.machine_name,
        location: m.location,
        is_admin: m.is_admin || false,
      }, token);
      console.log(`Created user: ${m.username} (${m.machine_name})`);
    } catch (e) {
      if (e.message.includes('unique') || e.message.includes('already')) {
        console.log(`User already exists: ${m.username}`);
      } else {
        console.error(`Failed to create user ${m.username}:`, e.message);
      }
    }
  }

  console.log('\nBootstrap complete!');
}

main().catch(e => {
  console.error('Fatal:', e.message);
  process.exit(1);
});
