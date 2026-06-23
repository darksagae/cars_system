# Email Queue System - Implementation Complete

## Overview

The email system now works **without SMTP/API**! Desktop machines queue emails, and the mobile app automatically sends them.

## How It Works

### 1. Desktop Machine (Sends Email)

When you click "Send Email" from any desktop machine:

1. **PDF is uploaded** to Supabase Storage (if attached)
2. **Email is queued** in Supabase with:
   - Recipient email
   - Subject and body (HTML)
   - PDF URL (if attached)
   - Sender info (machine ID, user name)
3. **Status**: `pending`

### 2. Mobile App (Processes Queue)

The mobile app automatically:

1. **Polls Supabase** every 10 seconds for pending emails
2. **Downloads PDF** from Supabase Storage (if attached)
3. **Opens email client** via share sheet:
   - Shows email apps (Gmail, Outlook, etc.)
   - Pre-fills subject and body
   - Attaches PDF (if provided)
4. **User taps Send** in their email app
5. **Status updated**: `sent` or `failed`

### 3. Tracking

All sent emails are stored in `email_messages` table with:
- Who sent it (user name, machine ID)
- When it was sent
- PDF URL (if attached)
- Status

## Database Tables

### `email_queue`
Stores pending emails waiting to be sent:
- `to_email`, `subject`, `body`
- `pdf_url` (Supabase Storage URL)
- `sent_by_machine_id`, `sent_by_user_name`
- `status` (pending, processing, sent, failed)

### `email_messages`
Stores successfully sent emails for tracking:
- All queue fields
- `sent_at` timestamp
- `status` (sent, failed)

## Code Structure

### Desktop App

**`lib/services/email_queue_service.dart`**
- Queues emails to Supabase
- Tracks sender information

**`lib/services/email_service.dart`**
- Updated to use queue by default
- Uploads PDFs to Supabase Storage
- Falls back to SMTP if `useQueue: false`

### Mobile App

**`lib/services/email_queue_processor.dart`**
- Polls Supabase for pending emails
- Downloads PDFs from Supabase Storage
- Opens email client with share_plus
- Updates queue status

**`lib/main.dart`**
- Starts email queue processor on app launch
- Stops processor on logout

## Usage

### Sending Invoice Email

```dart
await EmailService().sendInvoiceEmail(
  recipientEmail: 'customer@example.com',
  recipientName: 'John Doe',
  invoiceNumber: 'INV-2024-001',
  invoiceDate: '2024-11-06',
  totalAmount: 1000000.0,
  companyName: 'NSB Motors',
  pdfPath: '/path/to/invoice.pdf',
  useQueue: true, // Use queue (default)
);
```

### Sending Payment Reminder

```dart
await EmailService().sendPaymentReminderEmail(
  recipientEmail: 'customer@example.com',
  recipientName: 'John Doe',
  invoiceNumber: 'INV-2024-001',
  amount: 1000000.0,
  companyName: 'NSB Motors',
  pdfPath: '/path/to/reminder.pdf',
  useQueue: true, // Use queue (default)
);
```

## Benefits

✅ **No SMTP Required** - Works without email server configuration  
✅ **No Browser Sign-in** - Uses native email apps  
✅ **PDF Attachments** - Automatically attached via share sheet  
✅ **Multi-Machine** - Any desktop can queue emails  
✅ **Sender Tracking** - Records who sent each email  
✅ **Works Anywhere** - No WiFi requirement (uses Supabase)  

## User Experience

1. **Desktop**: Click "Send Email" → Email queued instantly
2. **Mobile**: Email client opens automatically with PDF attached
3. **User**: Tap "Send" in email app → Done!

## Notes

- Mobile app polls every 10 seconds (configurable)
- PDFs are stored in `whatsapp_attachments` bucket (reused)
- Email body is HTML formatted
- Temporary PDF files are cleaned up after 5 seconds
- Queue status can be checked via `EmailQueueService.getEmailStatus()`

## Future Enhancements

- [ ] Email templates
- [ ] Batch email sending
- [ ] Email delivery status tracking
- [ ] Retry failed emails
- [ ] Email scheduling


