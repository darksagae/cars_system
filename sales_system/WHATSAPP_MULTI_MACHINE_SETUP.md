# WhatsApp Multi-Machine Setup Guide

## Quick Answers

### 1. QR Code Scanning
✅ **ONE-TIME ONLY!** 
- Scan once, use forever
- Session persists through restarts, reboots, shutdowns
- Only rescan if session expires (~30-60 days)

### 2. Multi-Machine Sharing
✅ **Centralized Service Solution**
- One machine runs WhatsApp service (SERVER)
- Other machines connect to server via network
- All machines can send messages from same WhatsApp number

---

## Setup Instructions

### Step 1: Choose Server Machine

**Select one machine as the SERVER:**
- This machine will have the WhatsApp connection
- Should be always-on or frequently available
- Other machines will connect to this server

### Step 2: Configure Server Machine (Machine A)

1. **Enable Network Mode:**
   ```bash
   cd sales_system/whatsapp_service
   ```

2. **Start service in network mode:**
   ```bash
   # Option 1: With environment variables
   HOST=0.0.0.0 API_KEY=your-secret-key-here npm start
   
   # Option 2: Create start script
   # Create file: start-network.sh
   #!/bin/bash
   export HOST=0.0.0.0
   export API_KEY=your-secret-key-here
   npm start
   ```

3. **Find Server IP Address:**
   ```bash
   # Linux
   hostname -I
   # or
   ip addr show
   
   # Windows
   ipconfig
   ```
   
   Example: `192.168.1.100`

4. **Configure Firewall:**
   - Allow port 3001 in firewall
   - Ensure port is accessible from other machines

5. **Scan QR Code:**
   - Open WhatsApp Setup screen in app
   - Scan QR code with your phone
   - **This is the ONLY time you need to scan!**

### Step 3: Configure Client Machines (Machine B, C, D...)

1. **Open Flutter App Settings**
   - Go to Settings → WhatsApp Configuration
   - Or use WhatsApp Setup screen

2. **Enter Server Details:**
   - Server URL: `http://192.168.1.100:3001` (use server IP)
   - API Key: `your-secret-key-here` (same as server)
   - Click Save

3. **Test Connection:**
   - App will try to connect to server
   - If successful, you'll see "Connected to Server"
   - **No QR code needed on client machines!**

### Step 4: Test Sending

1. **On any machine (A, B, C, or D):**
   - Open an invoice
   - Click "Send WhatsApp"
   - Message should send automatically!

---

## Architecture

```
┌─────────────────────────────────────┐
│  Machine A (Server)                 │
│  - WhatsApp Service Running         │
│  - Network Mode Enabled (0.0.0.0)   │
│  - QR Code Scanned (ONE TIME)       │
│  - IP: 192.168.1.100                │
└──────────────┬──────────────────────┘
               │
               │ Network (LAN)
               │
    ┌──────────┴──────────┬──────────┐
    │                     │          │
┌───▼────┐          ┌────▼───┐ ┌───▼───┐
│Machine B│          │Machine C│ │Machine D│
│(Client) │          │(Client) │ │(Client) │
│         │          │         │ │         │
│No QR    │          │No QR    │ │No QR    │
│Code     │          │Code     │ │Code     │
│Needed!  │          │Needed!  │ │Needed!  │
└─────────┘          └─────────┘ └─────────┘
```

---

## Security (Recommended)

### For Production Use:

1. **Set API Key:**
   ```bash
   export API_KEY=your-strong-secret-key-here
   ```

2. **Use Strong Key:**
   - At least 32 characters
   - Mix of letters, numbers, symbols
   - Example: `NSB-Motors-WhatsApp-2025-Secret-Key-9876`

3. **Firewall Rules:**
   - Only allow connections from your network
   - Block external access to port 3001

---

## Troubleshooting

### Client Can't Connect to Server

**Check:**
- Server is running: `http://192.168.1.100:3001/api/health`
- Server IP is correct
- Firewall allows port 3001
- All machines on same network

**Solution:**
- Ping server IP: `ping 192.168.1.100`
- Check server logs for errors
- Verify API key matches

### QR Code Needed Again

**Only if:**
- Session expired (30-60 days)
- `.wwebjs_auth` folder deleted
- Logged out manually

**Solution:**
- Rescan QR code on SERVER machine only
- Client machines don't need QR code

### Multiple Machines Can't Connect Simultaneously

**This is normal!** WhatsApp only allows:
- ✅ Multiple clients connecting to same server
- ❌ Multiple servers with same WhatsApp account

**Solution:**
- Use ONE server machine
- All other machines as clients

---

## Configuration Files

### Server Machine:
- Service runs with: `HOST=0.0.0.0 API_KEY=xxx npm start`
- QR code saved in: `whatsapp_service/.wwebjs_auth/`

### Client Machines:
- Server URL saved in: SharedPreferences (`whatsapp_server_url`)
- API Key saved in: SharedPreferences (`whatsapp_api_key`)

---

## Summary

✅ **QR Code:** One-time scan on SERVER machine only  
✅ **Multi-Machine:** One server, multiple clients  
✅ **Sharing:** All machines share same WhatsApp number  
✅ **Easy Setup:** Just configure server URL on clients  

---

**Need Help?** Check `WHATSAPP_MULTI_MACHINE_SOLUTION.md` for detailed explanation.





