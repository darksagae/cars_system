-- WhatsApp Routing System - Supabase Migration
-- Run this in your Supabase SQL editor

-- 1. WhatsApp Messages Table (Track sent messages)
CREATE TABLE IF NOT EXISTS whatsapp_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id TEXT UNIQUE NOT NULL, -- WhatsApp message ID
  client_phone TEXT NOT NULL,
  message_content TEXT,
  message_type TEXT, -- 'invoice', 'reminder', 'payment_confirmation', etc.
  sent_by_machine_id TEXT NOT NULL, -- Machine identifier
  sent_by_user_id TEXT, -- User name/ID
  sent_by_user_name TEXT, -- User display name
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'sent', -- 'sent', 'delivered', 'read', 'failed'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. WhatsApp Replies Table (Store incoming replies)
CREATE TABLE IF NOT EXISTS whatsapp_replies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reply_id TEXT UNIQUE NOT NULL, -- WhatsApp reply ID
  client_phone TEXT NOT NULL,
  message_content TEXT NOT NULL,
  received_at TIMESTAMPTZ DEFAULT NOW(),
  original_message_id TEXT, -- Links to whatsapp_messages.message_id
  processed BOOLEAN DEFAULT FALSE,
  auto_reply_sent BOOLEAN DEFAULT FALSE,
  auto_reply_sent_at TIMESTAMPTZ,
  contact_forwarded BOOLEAN DEFAULT FALSE,
  forwarded_to_machine_id TEXT,
  forwarded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. WhatsApp Contacts Table (Forwarded contacts)
CREATE TABLE IF NOT EXISTS whatsapp_contacts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_phone TEXT NOT NULL,
  client_name TEXT, -- From customer database if available
  forwarded_to_machine_id TEXT NOT NULL,
  forwarded_to_user_id TEXT,
  forwarded_to_user_name TEXT,
  forwarded_at TIMESTAMPTZ DEFAULT NOW(),
  acknowledged BOOLEAN DEFAULT FALSE,
  acknowledged_at TIMESTAMPTZ,
  conversation_started BOOLEAN DEFAULT FALSE,
  conversation_started_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Machine Profiles Table (Store machine/user profiles)
CREATE TABLE IF NOT EXISTS machine_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  machine_id TEXT UNIQUE NOT NULL, -- Unique machine identifier
  machine_name TEXT,
  user_id TEXT,
  user_name TEXT,
  user_phone TEXT, -- Phone number for this machine/user
  user_email TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_client_phone ON whatsapp_messages(client_phone);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_sent_by ON whatsapp_messages(sent_by_machine_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_message_id ON whatsapp_messages(message_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_sent_at ON whatsapp_messages(sent_at);

CREATE INDEX IF NOT EXISTS idx_whatsapp_replies_client_phone ON whatsapp_replies(client_phone);
CREATE INDEX IF NOT EXISTS idx_whatsapp_replies_processed ON whatsapp_replies(processed);
CREATE INDEX IF NOT EXISTS idx_whatsapp_replies_received_at ON whatsapp_replies(received_at);
CREATE INDEX IF NOT EXISTS idx_whatsapp_replies_original_message ON whatsapp_replies(original_message_id);

CREATE INDEX IF NOT EXISTS idx_whatsapp_contacts_machine ON whatsapp_contacts(forwarded_to_machine_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_contacts_acknowledged ON whatsapp_contacts(acknowledged);
CREATE INDEX IF NOT EXISTS idx_whatsapp_contacts_client ON whatsapp_contacts(client_phone);

CREATE INDEX IF NOT EXISTS idx_machine_profiles_machine_id ON machine_profiles(machine_id);
CREATE INDEX IF NOT EXISTS idx_machine_profiles_active ON machine_profiles(is_active);

-- Enable Row Level Security (RLS)
ALTER TABLE whatsapp_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE machine_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies (allow all for now - adjust based on your security needs)
CREATE POLICY "Allow all operations on whatsapp_messages" ON whatsapp_messages
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all operations on whatsapp_replies" ON whatsapp_replies
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all operations on whatsapp_contacts" ON whatsapp_contacts
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all operations on machine_profiles" ON machine_profiles
  FOR ALL USING (true) WITH CHECK (true);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_whatsapp_messages_updated_at
  BEFORE UPDATE ON whatsapp_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_whatsapp_replies_updated_at
  BEFORE UPDATE ON whatsapp_replies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_whatsapp_contacts_updated_at
  BEFORE UPDATE ON whatsapp_contacts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_machine_profiles_updated_at
  BEFORE UPDATE ON machine_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();





