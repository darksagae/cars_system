# WhatsApp Sender Tracking

## Overview

The system now tracks **who sent each WhatsApp message** (including PDFs) so you can see "This PDF was sent by darksagae" when viewing messages or replies.

## How It Works

### 1. When Sending a Message (Desktop App)

When you send a WhatsApp message (with or without PDF) from any machine:

1. **Machine ID** is automatically generated/retrieved (unique per computer)
2. **User Profile** is retrieved from settings (name, user ID)
3. **Message is queued** with sender information:
   - `sent_by_machine_id`: Unique machine identifier
   - `sent_by_user_id`: User ID from profile
   - `sent_by_user_name`: Display name (e.g., "darksagae")
   - `message_type`: Type of message (e.g., "invoice", "payment_reminder", "media")

### 2. Mobile App Processing

When the mobile app processes the queued message:

1. Downloads PDF (if attached) from Supabase Storage
2. Shares via WhatsApp
3. **Stores in `whatsapp_messages` table** with all sender info:
   ```sql
   {
     message_id: "...",
     client_phone: "256751234567",
     message_content: "...",
     message_type: "invoice",
     sent_by_machine_id: "desktop_hostname_123456",
     sent_by_user_id: "user123",
     sent_by_user_name: "darksagae",
     sent_at: "2025-11-06T10:00:00Z"
   }
   ```

### 3. When Client Replies

When a client replies to a message:

1. Reply is stored in `whatsapp_replies` table
2. System looks up the **original message** using phone number
3. Links reply to original message via `original_message_id`
4. **Sender information is preserved** from the original message

## Database Schema

### whatsapp_message_queue
Stores messages waiting to be sent:
- `sent_by_machine_id` ✅
- `sent_by_user_id` ✅
- `sent_by_user_name` ✅
- `message_type` ✅

### whatsapp_messages
Stores successfully sent messages:
- `sent_by_machine_id` ✅
- `sent_by_user_id` ✅
- `sent_by_user_name` ✅
- `message_type` ✅

### whatsapp_replies
Stores incoming replies:
- `original_message_id` (links to whatsapp_messages)
- Can join with `whatsapp_messages` to get sender info

## Example Query: Get Replies with Sender Info

```sql
SELECT 
  r.*,
  m.sent_by_user_name,
  m.sent_by_machine_id,
  m.message_type
FROM whatsapp_replies r
LEFT JOIN whatsapp_messages m 
  ON r.original_message_id = m.message_id
WHERE r.client_phone = '256751234567'
ORDER BY r.received_at DESC;
```

This will show:
- Reply content
- **"Sent by: darksagae"**
- **"Message type: invoice"**
- **"From machine: desktop_hostname_123456"**

## UI Display

When displaying replies, you can show:

```
📱 Reply from Client: 256751234567
💬 "Thank you, I'll pay tomorrow"

📎 Original Message:
   📄 Invoice sent by: darksagae
   🖥️ Machine: desktop_hostname_123456
   📅 Sent: 2025-11-06 10:00 AM
```

## Current Status

✅ **Completed:**
- Sender tracking in queue
- Sender tracking in whatsapp_messages
- Message type tracking (invoice, payment_reminder, etc.)
- Machine ID generation
- User profile integration

⚠️ **Note:**
- Replies are currently only captured if using WhatsApp Web automation (Node.js server)
- With mobile app share_plus method, replies need to be manually forwarded or captured via notification listener (future enhancement)

## Testing

1. Send an invoice via WhatsApp from Machine A (user: darksagae)
2. Check `whatsapp_messages` table:
   ```sql
   SELECT sent_by_user_name, message_type, client_phone 
   FROM whatsapp_messages 
   ORDER BY sent_at DESC 
   LIMIT 1;
   ```
3. Should show: `sent_by_user_name: "darksagae"`, `message_type: "invoice"`

## Future Enhancements

- [ ] UI screen to view all messages with sender info
- [ ] Filter messages by sender
- [ ] Show "Sent by: [name]" in reply notifications
- [ ] Automatic reply capture via mobile notification listener


