// Neon Postgres Database Configuration

module.exports = {
  postgres: {
    host: process.env.PGHOST || 'ep-bitter-fire-a81vc85m.eastus2.azure.neon.tech',
    database: process.env.PGDATABASE || 'neondb',
    user: process.env.PGUSER || 'neondb_owner',
    password: process.env.PGPASSWORD || '',
    port: parseInt(process.env.PGPORT || '5432'),
    ssl: {
      rejectUnauthorized: false
    }
  },
  
  // Auto-reply message
  autoReplyMessage: process.env.AUTO_REPLY_MESSAGE || 
    'Thank you for your message! Let me connect you to your agent. 📞',
  
  // Company info
  companyName: process.env.COMPANY_NAME || 'NSB Motors Ug',
};
