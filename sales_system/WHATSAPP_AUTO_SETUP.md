# WhatsApp Automatic Sending Setup Guide

This guide explains how to set up automatic WhatsApp message sending without requiring manual intervention.

## Overview

The system now uses **Option 3: WhatsApp Desktop CLI Tools** with `whatsapp-web.js`. This provides:
- ✅ **Automatic sending** - Messages send automatically when you press "Send"
- ✅ **One-time QR scan** - Only need to scan QR code once during initial setup
- ✅ **No API costs** - Free solution using WhatsApp Web protocol
- ✅ **Session persistence** - Stays logged in after restart

## How It Works

1. A Node.js service runs in the background using `whatsapp-web.js`
2. During initial setup, you scan a QR code with your phone (one time only)
3. The session is saved locally and persists across restarts
4. Your Flutter app communicates with the Node.js service via HTTP
5. Messages are sent automatically without any manual clicking

## Setup Instructions

### Step 1: Install Node.js

Make sure Node.js is installed on your system:

```bash
node --version  # Should show v14 or higher
npm --version   # Should show version number
```

If not installed, download from: https://nodejs.org/

### Step 2: Install Dependencies

Navigate to the whatsapp_service directory and run setup:

```bash
cd sales_system/whatsapp_service
chmod +x setup.sh
./setup.sh
```

Or manually:
```bash
cd sales_system/whatsapp_service
npm install
```

### Step 3: Start the WhatsApp Service

Start the Node.js service:

```bash
cd sales_system/whatsapp_service
npm start
```

Or use the start script:
```bash
./start.sh
```

The service will start on `http://localhost:3001`

### Step 4: Initial QR Code Setup (One-Time)

1. When you first start the service, a QR code will appear in the terminal
2. Open WhatsApp on your phone
3. Go to **Settings → Linked Devices → Link a Device**
4. Scan the QR code displayed in the terminal
5. Once connected, the service saves your session automatically

**Alternative: Use the Flutter App Setup Screen**

1. In your Flutter app, navigate to **Settings → WhatsApp Setup**
2. The app will show the QR code on screen
3. Scan it with your phone as described above
4. Once connected, you'll see a "Connected & Ready" message

### Step 5: Use Automatic Sending

Once the service is running and connected:

1. Open any invoice in your Flutter app
2. Click "Send WhatsApp"
3. The message will be sent **automatically** - no manual clicking needed!
4. You'll see a success message: "✅ Invoice sent via WhatsApp automatically!"

## Running the Service in Background

### Linux (Terminal)

```bash
cd sales_system/whatsapp_service
nohup npm start > whatsapp-service.log 2>&1 &
```

### Linux (systemd Service)

Create `/etc/systemd/system/whatsapp-service.service`:

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

## Troubleshooting

### Service Won't Start

**Problem:** Node.js not found or npm install fails

**Solution:**
- Make sure Node.js is installed: `node --version`
- Make sure you're in the correct directory: `cd sales_system/whatsapp_service`
- Try installing dependencies again: `npm install`

### QR Code Not Appearing

**Problem:** QR code doesn't show up in terminal or app

**Solution:**
- Wait a few seconds after starting the service
- Check if the service is running: `curl http://localhost:3001/api/health`
- Try restarting the service: `npm start` again
- Check terminal for error messages

### Messages Not Sending

**Problem:** Clicking "Send WhatsApp" doesn't work

**Solution:**
1. Check if service is running: Open `http://localhost:3001/api/health` in browser
2. Check WhatsApp status: Open `http://localhost:3001/api/status` in browser
3. If status is not "ready", go to WhatsApp Setup screen and reconnect
4. Verify phone number format is correct (should include country code)

### Session Lost

**Problem:** Need to scan QR code again after restart

**Solution:**
- The session is saved in `.wwebjs_auth` directory
- If deleted or corrupted, you'll need to scan QR code again
- Make sure the `.wwebjs_auth` directory has proper permissions
- Don't delete the `.wwebjs_auth` folder!

### Port 3001 Already in Use

**Problem:** Service can't start because port is busy

**Solution:**
- Find what's using port 3001: `lsof -i :3001` or `netstat -tulpn | grep 3001`
- Kill the process or change the port in `server.js` (line 10)

## Integration with Flutter App

The Flutter app automatically detects if the service is running:

- **If service is running and connected:** Uses automatic sending
- **If service is not running:** Falls back to manual WhatsApp (opens WhatsApp app)
- **If service is running but not connected:** Shows setup dialog

### Manual Setup Access

To access WhatsApp Setup screen manually:
- Go to any invoice → Click "Send WhatsApp" → If not connected, click "Setup Auto"
- Or add a menu item in Settings to navigate to WhatsApp Setup

## API Endpoints

The service exposes these endpoints:

- `GET /api/health` - Check if service is running
- `GET /api/status` - Get WhatsApp connection status
- `GET /api/qr` - Get QR code for setup
- `POST /api/send` - Send a message
- `POST /api/send-media` - Send message with PDF attachment
- `POST /api/restart` - Restart WhatsApp client

## Security Notes

- The service runs **locally** on your machine only
- Session data is stored in `.wwebjs_auth` directory
- Don't share your `.wwebjs_auth` folder with anyone
- The service is only accessible from localhost (not exposed to internet)

## Phone Number Format

The service automatically formats phone numbers:
- Input: `0751234567` → Output: `256751234567@c.us`
- Input: `+256751234567` → Output: `256751234567@c.us`
- Input: `256751234567` → Output: `256751234567@c.us`

## Benefits vs Manual Method

| Feature | Manual (Old) | Automatic (New) |
|---------|-------------|-----------------|
| Setup | None | One-time QR scan |
| Sending | Manual click required | Automatic |
| PDF Attachment | Not supported | Supported |
| Speed | Slow (manual) | Fast (automatic) |
| Reliability | User dependent | Consistent |

## Next Steps

1. ✅ Complete the setup above
2. ✅ Test sending an invoice via WhatsApp
3. ✅ Set up service to start automatically on boot (optional)
4. ✅ Enjoy automatic WhatsApp sending! 🎉

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Check the terminal output for error messages
3. Check the service logs: `tail -f whatsapp-service.log`
4. Verify Node.js and dependencies are installed correctly





