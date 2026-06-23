# WhatsApp PDF Attachment Setup

## Overview

The system now supports sending PDF attachments (invoices, demand letters, etc.) via WhatsApp. When you send an invoice via WhatsApp, the PDF is automatically uploaded to Supabase Storage and then shared through the mobile app.

## How It Works

1. **Desktop App**: When you click "Send via WhatsApp" for an invoice:
   - The PDF is generated (if not already generated)
   - The PDF is uploaded to Supabase Storage bucket `whatsapp_attachments`
   - A message is queued in Supabase with the PDF URL
   
2. **Mobile App**: The queue processor automatically:
   - Downloads the PDF from the Supabase Storage URL
   - Opens WhatsApp share sheet with the PDF and message
   - User selects WhatsApp and the contact
   - PDF and message are sent

## Setup Instructions

### 1. Create Supabase Storage Bucket

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Navigate to **Storage** → **Buckets**
3. Click **New Bucket**
4. Configure:
   - **Name**: `whatsapp_attachments`
   - **Public bucket**: ✅ **Yes** (checked)
   - **File size limit**: 50 MB (or as needed)
   - **Allowed MIME types**: `application/pdf` (optional, for security)

### 2. Configure Storage Policies (RLS)

1. Go to **Storage** → **Policies** → `whatsapp_attachments`
2. Create policies:

   **Policy 1: Allow authenticated users to upload**
   - Policy name: `Allow authenticated uploads`
   - Allowed operation: `INSERT`
   - Target roles: `authenticated`
   - Policy definition:
     ```sql
     (bucket_id = 'whatsapp_attachments'::text) AND (auth.role() = 'authenticated'::text)
     ```

   **Policy 2: Allow public read access**
   - Policy name: `Allow public read`
   - Allowed operation: `SELECT`
   - Target roles: `anon`, `authenticated`
   - Policy definition:
     ```sql
     (bucket_id = 'whatsapp_attachments'::text)
     ```

   **Policy 3: Allow authenticated users to delete (optional, for cleanup)**
   - Policy name: `Allow authenticated delete`
   - Allowed operation: `DELETE`
   - Target roles: `authenticated`
   - Policy definition:
     ```sql
     (bucket_id = 'whatsapp_attachments'::text) AND (auth.role() = 'authenticated'::text)
     ```

### 3. Verify Setup

1. Try sending an invoice via WhatsApp from the desktop app
2. Check the mobile app logs to see if the PDF is downloaded successfully
3. Verify the PDF appears in the WhatsApp share sheet

## File Structure

PDFs are stored in the bucket with the following path structure:
```
whatsapp_pdfs/{timestamp}_{original_filename}.pdf
```

Example:
```
whatsapp_pdfs/1704123456789_invoice_INV-2024-001.pdf
```

## Troubleshooting

### Error: "Storage bucket 'whatsapp_attachments' does not exist"
- **Solution**: Create the bucket in Supabase Dashboard (see step 1 above)

### Error: "row-level security policy" or "RLS policy error"
- **Solution**: Configure the storage policies (see step 2 above)

### Error: "Failed to download PDF" on mobile
- **Solution**: 
  - Check that the bucket is public
  - Verify the public read policy is configured
  - Check the PDF URL in the queue table

### PDF not appearing in WhatsApp share sheet
- **Solution**:
  - Ensure `share_plus` package is installed in mobile app
  - Check mobile app logs for download errors
  - Verify internet connection on mobile device

## Notes

- PDFs are stored permanently in Supabase Storage (consider implementing cleanup for old files)
- Each PDF gets a unique filename based on timestamp to avoid conflicts
- The mobile app downloads PDFs to temporary storage and cleans them up after 5 seconds
- User must manually select the contact in WhatsApp (phone number is included in message text for easy searching)

## Future Improvements

- Automatic cleanup of old PDFs (e.g., delete after 30 days)
- Direct WhatsApp contact selection (requires native Android code)
- Support for other file types (images, documents)
- Batch PDF sending





