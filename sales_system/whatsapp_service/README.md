# WhatsApp Auto Service

This Node.js service provides automatic WhatsApp message sending using `whatsapp-web.js`. It requires a **one-time QR code scan** during initial setup, then messages are sent automatically without any manual intervention.

## Features

- ✅ Automatic message sending (no manual click required)
- ✅ One-time QR code setup (no scanning every time)
- ✅ Session persistence (stays logged in after restart)
- ✅ PDF attachment support
- ✅ REST API for Flutter app integration

## Installation

### Prerequisites

- Node.js (version 14 or higher)
- npm (comes with Node.js)

### Setup Steps

1. **Navigate to the whatsapp_service directory:**
   ```bash
   cd whatsapp_service
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Start the service:**
   ```bash
   npm start
   ```

   The service will start on `http://localhost:3001`

4. **Initial Setup (One-time QR Scan):**
   - When you first start the service, it will generate a QR code in the terminal
   - Open WhatsApp on your phone
   - Go to Settings → Linked Devices → Link a Device
   - Scan the QR code displayed in the terminal
   - Once connected, the service will save your session and you won't need to scan again

## API Endpoints

### Health Check
```
GET /api/health
```
Returns the service status.

### Get Status
```
GET /api/status
```
Returns WhatsApp client status and connection state.

### Get QR Code
```
GET /api/qr
```
Returns QR code data for initial setup (if needed).

### Send Message
```
POST /api/send
Body: {
  "phoneNumber": "256751234567",
  "message": "Your message here"
}
```

### Send Message with PDF
```
POST /api/send-media
Body: {
  "phoneNumber": "256751234567",
  "message": "Your message here",
  "mediaPath": "/path/to/file.pdf"
}
```

### Restart Service
```
POST /api/restart
```
Restarts the WhatsApp client (generates new QR if needed).

## Usage in Flutter App

The Flutter app uses `WhatsAppAutoService` to communicate with this service:

```dart
final whatsappService = WhatsAppAutoService();

// Send a message
await whatsappService.sendMessage(
  phoneNumber: '0751234567',
  message: 'Hello from NSB Motors!',
);

// Send invoice with PDF
await whatsappService.sendInvoiceMessage(
  phoneNumber: '0751234567',
  customerName: 'John Doe',
  invoiceNumber: 'INV-001',
  invoiceDate: '2025-01-15',
  totalAmount: 1000000,
  pdfPath: '/path/to/invoice.pdf',
);
```

## Phone Number Format

The service automatically formats phone numbers:
- Input: `0751234567` → Output: `256751234567@c.us`
- Input: `+256751234567` → Output: `256751234567@c.us`
- Input: `256751234567` → Output: `256751234567@c.us`

## Troubleshooting

### Service won't start
- Make sure Node.js is installed: `node --version`
- Make sure all dependencies are installed: `npm install`
- Check if port 3001 is already in use

### QR code not appearing
- Wait a few seconds after starting the service
- Check the terminal output for any errors
- Try restarting the service: `POST /api/restart`

### Messages not sending
- Check if WhatsApp is connected: `GET /api/status`
- Ensure the service status is `ready`
- Check phone number format
- Verify the recipient has WhatsApp installed

### Session lost
- If the session is lost, the service will generate a new QR code
- Scan the new QR code to reconnect
- The session is saved in `.wwebjs_auth` directory

## Security Notes

- The service runs locally on your machine
- Session data is stored locally in `.wwebjs_auth` directory
- Keep your session directory secure
- Don't share your `.wwebjs_auth` folder

## Running as Background Service

### Linux (systemd)

Create a service file `/etc/systemd/system/whatsapp-service.service`:

```ini
[Unit]
Description=WhatsApp Auto Service
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/path/to/sales_system/whatsapp_service
ExecStart=/usr/bin/node server.js
Restart=always

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl enable whatsapp-service
sudo systemctl start whatsapp-service
```

### Manual Background (Linux)

```bash
nohup npm start > whatsapp-service.log 2>&1 &
```

## Notes

- The service must be running for the Flutter app to send messages
- The service will automatically reconnect if disconnected
- Session persists across service restarts
- Only one WhatsApp account can be connected at a time





