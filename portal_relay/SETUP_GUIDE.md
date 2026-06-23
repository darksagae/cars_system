# NSB Motors Portal — Setup Guide

## Architecture
```
Internet → Cloudflare Tunnel → Master PC:8090 (PocketBase)
                             → Master PC:3002 (Relay WebSocket)
```

## Step 1 — Download & Install PocketBase

Run on the master desktop PC (the one that stays on):

```bash
cd /path/to/portal_relay
chmod +x pb_setup.sh
./pb_setup.sh
```

This downloads PocketBase and starts it on port 8090.

## Step 2 — First-Time Admin Setup

1. Open http://localhost:8090/_/ in a browser
2. Create your admin account (e.g. admin@nsbmotors.com / nsb@admin2025)

## Step 3 — Bootstrap Database Collections

```bash
cd portal_relay/pb_portal
npm install node-fetch   # one-time
node bootstrap.js
```

This creates the collections (customers, invoices, payments, machine_users)
and the 4 machine user accounts.

## Step 4 — Copy Web Portal

```bash
cp portal_relay/pb_portal/index.html portal_relay/pocketbase/pb_public/index.html
```

Or set PocketBase to serve from `pb_portal/` directly:
```bash
./pocketbase serve --http="0.0.0.0:8090" --publicDir="../pb_portal"
```

## Step 5 — Cloudflare Tunnel

If you already have a tunnel pointing to port 3002 (relay), add a second
service or update the tunnel to point to port 8090 (PocketBase):

```yaml
# ~/.cloudflared/config.yml
tunnel: <your-tunnel-id>
credentials-file: /home/user/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: portal.nsbmotors.com
    service: http://localhost:8090
  - hostname: ws.nsbmotors.com
    service: http://localhost:3002
  - service: http_status:404
```

Then restart the tunnel:
```bash
cloudflared tunnel run <tunnel-name>
```

## Machine User Credentials

| Machine ID | Name          | Location       | Password       |
|-----------|---------------|----------------|----------------|
| M001      | Reception PC  | Front Desk     | reception2025  |
| M002      | Sales Office  | Sales Room     | sales2025      |
| M003      | Manager PC    | Manager Office | manager2025    |
| M004      | Accounts PC   | Accounts       | accounts2025   |

## Access

- Web Portal: https://portal.nsbmotors.com
- PocketBase Admin: https://portal.nsbmotors.com/_/
- Relay WebSocket: wss://ws.nsbmotors.com (or wss://portal.nsbmotors.com if single domain)

## Data Isolation

Each machine user only sees their own records. The PocketBase rules enforce:
- `machine_id = @request.auth.record.machine_id`

So Reception PC (M001) cannot see Sales Office (M002) invoices or clients.

## Running Both Services

```bash
# Terminal 1 — PocketBase
cd portal_relay/pocketbase && ./pocketbase serve --http="0.0.0.0:8090" --publicDir="../pb_portal"

# Terminal 2 — Relay (for mobile app machine monitoring)
cd portal_relay && node server.js

# Terminal 3 — Cloudflare Tunnel
cloudflared tunnel run nsb-motors
```

Or use a process manager like PM2:
```bash
npm install -g pm2
pm2 start server.js --name relay
pm2 start "cd pocketbase && ./pocketbase serve --http=0.0.0.0:8090 --publicDir=../pb_portal" --name pocketbase
pm2 save
pm2 startup   # auto-start on boot
```
