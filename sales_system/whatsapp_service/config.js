// Neon Postgres — use Vercel + Neon integration vars only (no hardcoded hosts).
// Copy to .env and fill from: cd web/NSB_Web && vercel env pull .env.local
//
// POSTGRES_PRISMA_URL=postgresql://...

function parseConnectionUrl(connectionString) {
  const url = new URL(connectionString.replace(/^postgresql:/, 'postgres:'));
  const database = url.pathname.replace(/^\//, '') || 'neondb';
  return {
    host: url.hostname,
    database,
    user: decodeURIComponent(url.username || ''),
    password: decodeURIComponent(url.password || ''),
    port: parseInt(url.port || '5432', 10),
    ssl: { rejectUnauthorized: false },
  };
}

function resolvePostgresConfig() {
  const connectionUrl =
    process.env.POSTGRES_PRISMA_URL?.trim() ||
    process.env.DATABASE_URL?.trim() ||
    '';

  if (connectionUrl) {
    return parseConnectionUrl(connectionUrl);
  }

  const host = process.env.PGHOST?.trim() || process.env.POSTGRES_HOST?.trim();
  const user = process.env.PGUSER?.trim() || process.env.POSTGRES_USER?.trim();
  const password = process.env.PGPASSWORD?.trim() || process.env.POSTGRES_PASSWORD?.trim();

  if (!host || !user || !password) {
    throw new Error(
      'Postgres not configured. Set POSTGRES_PRISMA_URL (from Vercel Neon integration) ' +
        'or PGHOST/PGUSER/PGPASSWORD.',
    );
  }

  return {
    host,
    database: process.env.PGDATABASE?.trim() || process.env.POSTGRES_DATABASE?.trim() || 'neondb',
    user,
    password,
    port: parseInt(process.env.PGPORT?.trim() || process.env.POSTGRES_PORT?.trim() || '5432', 10),
    ssl: { rejectUnauthorized: false },
  };
}

module.exports = {
  postgres: resolvePostgresConfig(),

  autoReplyMessage:
    process.env.AUTO_REPLY_MESSAGE ||
    'Thank you for your message! Let me connect you to your agent. 📞',

  companyName: process.env.COMPANY_NAME || 'NSB Motors Ug',
};
