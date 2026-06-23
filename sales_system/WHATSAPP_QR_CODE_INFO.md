# WhatsApp QR Code - One Time Setup

## ✅ QR Code Scanning is ONE-TIME ONLY

Once you scan the QR code, the session is **saved permanently** and you won't need to scan again unless:

### ✅ Session Persists Through:
- ✅ App restarts
- ✅ Service restarts  
- ✅ Computer reboots
- ✅ Desktop shutdowns
- ✅ Network disconnections
- ✅ Service crashes (auto-restart)

### ❌ Need to Rescan ONLY If:
1. **Session expires** (WhatsApp security, ~30-60 days of inactivity)
2. **`.wwebjs_auth` folder is deleted** (manual deletion)
3. **Logged out manually** from WhatsApp Web
4. **WhatsApp security check** (rare, if suspicious activity detected)

## How It Works

The WhatsApp session is saved in the `.wwebjs_auth` directory:
- Location: `whatsapp_service/.wwebjs_auth/`
- Contains encrypted authentication data
- Automatically loaded when service starts
- Persists across all restarts

## For Multi-Machine Setup

**Important:** Only the **SERVER MACHINE** needs QR code scanning!

- **Server Machine (Machine A):** Scans QR code once
- **Client Machines (B, C, D):** No QR code needed
- They connect to server via network API

---

**Bottom Line:** Scan once, use forever (until session expires)!





