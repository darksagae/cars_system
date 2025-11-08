// Supabase Configuration
// Set these as environment variables or update with your values

module.exports = {
  supabase: {
    url: process.env.SUPABASE_URL || 'https://xjnrdzzwratspwmwridu.supabase.co',
    anonKey: process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhqbnJkenp3cmF0c3B3bXdyaWR1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzMTAwODksImV4cCI6MjA3NTg4NjA4OX0.06HmZgrd555DSRIPxZlTcGoOPjGa6ADgVtnWY5OtCsw',
  },
  
  // Auto-reply message
  autoReplyMessage: process.env.AUTO_REPLY_MESSAGE || 
    'Thank you for your message! Let me connect you to your agent. 📞',
  
  // Company info
  companyName: process.env.COMPANY_NAME || 'NSB Motors Ug',
};





