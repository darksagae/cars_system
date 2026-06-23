'use strict';

const express = require('express');
const { WebSocketServer } = require('ws');
const http = require('http');
const fs = require('fs');
const path = require('path');

// ── Config ────────────────────────────────────────────────────────────────────

const CONFIG_PATH = path.join(__dirname, 'config.json');

function loadConfig() {
  return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
}

let config = loadConfig();

// ── HTTP + WS server ──────────────────────────────────────────────────────────

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

// ── In-memory state ───────────────────────────────────────────────────────────

/** machineId → { ws, cpu, mem, current_user, os, platform, ip, last_seen } */
const live = new Map();

/** Set of authenticated admin WebSocket connections (mobile app + web admins) */
const admins = new Set();

/** ws → { machineId } — web portal users viewing their own machine */
const portalSessions = new Map();

/** machineId → MachineActivity[] */
const activityStore = new Map();

/** invoiceNumber → invoice object (merged across all machines) */
const invoiceStore = new Map();

// ── Helpers ───────────────────────────────────────────────────────────────────

const ts = () => new Date().toISOString();
let _idSeq = 0;
const newId = () => `${Date.now()}-${(++_idSeq).toString(36)}`;

function cfgMachine(id) {
  return config.machines.find(m => m.id === id);
}

function send(ws, obj) {
  if (ws.readyState === 1) ws.send(JSON.stringify(obj));
}

function broadcastAdmins(obj) {
  const msg = JSON.stringify(obj);
  for (const ws of admins) {
    if (ws.readyState === 1) ws.send(msg);
  }
}

function machineList() {
  return config.machines.map(cfg => {
    const m = live.get(cfg.id);
    return {
      id: cfg.id,
      name: cfg.name,
      location: cfg.location || '',
      online: !!m,
      cpu: m?.cpu ?? null,
      mem: m?.mem ?? null,
      current_user: m?.current_user ?? null,
      os: m?.os ?? null,
      platform: m?.platform ?? null,
      ip: m?.ip ?? null,
      last_seen: m?.last_seen ?? null,
    };
  });
}

function pushActivity(machineId, action, username, status, details) {
  const activity = {
    id: newId(),
    machine_id: machineId,
    action,
    username: username || null,
    status,
    details: details || {},
    timestamp: ts(),
  };

  if (!activityStore.has(machineId)) activityStore.set(machineId, []);
  const list = activityStore.get(machineId);
  list.push(activity);
  if (list.length > 500) list.splice(0, list.length - 500);

  broadcastAdmins({ type: 'activity', activity });

  for (const [ws, sess] of portalSessions) {
    if (sess.machineId === machineId) send(ws, { type: 'activity', activity });
  }

  return activity;
}

function allActivities(limit = 200) {
  const all = [];
  for (const list of activityStore.values()) all.push(...list);
  all.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
  return all.slice(0, limit);
}

// ── WebSocket handler ─────────────────────────────────────────────────────────

wss.on('connection', (ws, req) => {
  const ip = req.socket.remoteAddress || '?';
  let role = null;       // 'machine' | 'admin' | 'portal'
  let myMachineId = null;

  ws.on('message', raw => {
    let msg;
    try { msg = JSON.parse(raw.toString()); } catch { return; }
    const { type } = msg;

    // ── Machine register ──────────────────────────────────────────────────────
    if (type === 'machine_register') {
      const cfg = cfgMachine(msg.machine_id);
      if (!cfg || msg.password !== cfg.password) {
        send(ws, { type: 'error', message: 'Invalid machine credentials' });
        return;
      }
      role = 'machine';
      myMachineId = msg.machine_id;
      live.set(myMachineId, {
        ws, cpu: null, mem: null,
        current_user: msg.current_user || null,
        os: msg.os || null,
        platform: msg.platform || 'Windows',
        ip, last_seen: ts(),
      });
      send(ws, { type: 'registered', machine_id: myMachineId });
      broadcastAdmins({ type: 'machines', machines: machineList() });
      pushActivity(myMachineId, 'connected', msg.current_user, 'success', { ip });
      console.log(`[+] Machine connected: ${cfg.name} (${myMachineId}) from ${ip}`);
      return;
    }

    // ── Admin auth (mobile app / web admin) ───────────────────────────────────
    if (type === 'admin_auth') {
      if (msg.password !== config.admin_password) {
        send(ws, { type: 'error', message: 'Wrong admin password' });
        return;
      }
      role = 'admin';
      admins.add(ws);
      send(ws, { type: 'admin_ok', machines: machineList() });
      send(ws, { type: 'activities_snapshot', activities: allActivities() });
      console.log(`[+] Admin connected from ${ip}`);
      return;
    }

    // ── Portal auth (per-machine web login) ───────────────────────────────────
    if (type === 'portal_auth') {
      const cfg = cfgMachine(msg.machine_id);
      if (!cfg || msg.password !== cfg.password) {
        send(ws, { type: 'error', message: 'Invalid credentials' });
        return;
      }
      role = 'portal';
      myMachineId = msg.machine_id;
      portalSessions.set(ws, { machineId: myMachineId });
      const m = live.get(myMachineId);
      send(ws, {
        type: 'portal_ok',
        machine: {
          id: cfg.id,
          name: cfg.name,
          location: cfg.location || '',
          online: !!m,
          cpu: m?.cpu ?? null,
          mem: m?.mem ?? null,
          current_user: m?.current_user ?? null,
        },
        activities: (activityStore.get(myMachineId) || []).slice(-100).reverse(),
      });
      return;
    }

    if (!role) {
      send(ws, { type: 'error', message: 'Authenticate first' });
      return;
    }

    // ── Machine: heartbeat ────────────────────────────────────────────────────
    if (type === 'heartbeat' && role === 'machine') {
      const m = live.get(myMachineId);
      if (m) {
        m.cpu = msg.cpu ?? m.cpu;
        m.mem = msg.mem ?? m.mem;
        m.current_user = msg.current_user ?? m.current_user;
        m.last_seen = ts();
      }
      broadcastAdmins({ type: 'machines', machines: machineList() });
      for (const [pws, sess] of portalSessions) {
        if (sess.machineId === myMachineId) {
          const updated = live.get(myMachineId);
          send(pws, {
            type: 'machine_status',
            online: true,
            cpu: updated?.cpu,
            mem: updated?.mem,
            current_user: updated?.current_user,
          });
        }
      }
      return;
    }

    // ── Machine: activity report ──────────────────────────────────────────────
    if (type === 'activity' && role === 'machine') {
      pushActivity(myMachineId, msg.action, msg.username, msg.status || 'success', msg.details);
      return;
    }

    // ── Machine: invoice sync ─────────────────────────────────────────────────
    if (type === 'invoice_sync' && role === 'machine') {
      const inv = msg.invoice;
      if (!inv || !inv.invoiceNumber) return;
      const operation = msg.operation || 'upsert';
      if (operation === 'delete') {
        invoiceStore.delete(inv.invoiceNumber);
        broadcastAdmins({ type: 'invoice_deleted', invoiceNumber: inv.invoiceNumber });
      } else {
        const enriched = { ...inv, _machineId: myMachineId, _syncedAt: ts() };
        invoiceStore.set(inv.invoiceNumber, enriched);
        broadcastAdmins({ type: 'invoice_upserted', invoice: enriched });
      }
      return;
    }

    // ── Machine: command result ───────────────────────────────────────────────
    if (type === 'command_result' && role === 'machine') {
      pushActivity(myMachineId, `cmd:${msg.command}`, null,
        msg.success ? 'success' : 'failed', { output: msg.output });
      return;
    }

    // ── Admin: send command to specific machine ────────────────────────────────
    if (type === 'command' && role === 'admin') {
      const target = live.get(msg.machine_id);
      if (target) {
        send(target.ws, { type: 'command', command: msg.command, data: msg.data });
        send(ws, { type: 'command_sent', machine_id: msg.machine_id, ok: true });
      } else {
        send(ws, { type: 'command_sent', machine_id: msg.machine_id, ok: false, reason: 'offline' });
      }
      return;
    }

    // ── Admin: broadcast to all machines ──────────────────────────────────────
    if (type === 'broadcast' && role === 'admin') {
      let count = 0;
      for (const [, m] of live) {
        send(m.ws, { type: 'command', command: msg.command, data: msg.data });
        count++;
      }
      send(ws, { type: 'broadcast_sent', count });
      return;
    }

    // ── Admin: clear activities ───────────────────────────────────────────────
    if (type === 'clear_activities' && role === 'admin') {
      if (msg.machine_id) {
        activityStore.delete(msg.machine_id);
      } else {
        activityStore.clear();
      }
      broadcastAdmins({ type: 'activities_cleared', machine_id: msg.machine_id || null });
      return;
    }
  });

  ws.on('close', () => {
    if (role === 'machine' && myMachineId) {
      const cfg = cfgMachine(myMachineId);
      live.delete(myMachineId);
      broadcastAdmins({ type: 'machines', machines: machineList() });
      pushActivity(myMachineId, 'disconnected', null, 'info', {});
      console.log(`[-] Machine disconnected: ${cfg?.name || myMachineId}`);
    }
    if (role === 'admin') admins.delete(ws);
    if (role === 'portal') portalSessions.delete(ws);
  });

  ws.on('error', () => {
    if (role === 'machine' && myMachineId) live.delete(myMachineId);
    if (role === 'admin') admins.delete(ws);
    if (role === 'portal') portalSessions.delete(ws);
  });
});

// ── HTTP endpoints ────────────────────────────────────────────────────────────

app.get('/health', (_, res) => {
  res.json({
    ok: true,
    online_machines: live.size,
    configured_machines: config.machines.length,
    admin_connections: admins.size,
  });
});

// ── Invoice API ───────────────────────────────────────────────────────────────

function requireAdminKey(req, res) {
  const key = req.headers['x-admin-key'] || req.query.key;
  if (key !== config.admin_password) {
    res.status(401).json({ error: 'Unauthorized' });
    return false;
  }
  return true;
}

// GET /api/invoices — full list, newest first
app.get('/api/invoices', (req, res) => {
  if (!requireAdminKey(req, res)) return;
  const list = Array.from(invoiceStore.values())
    .sort((a, b) => new Date(b._syncedAt) - new Date(a._syncedAt));
  res.json({ ok: true, count: list.length, invoices: list });
});

// GET /api/invoices/:number — single invoice by invoice number
app.get('/api/invoices/:number', (req, res) => {
  if (!requireAdminKey(req, res)) return;
  const inv = invoiceStore.get(req.params.number);
  if (!inv) return res.status(404).json({ error: 'Not found' });
  res.json({ ok: true, invoice: inv });
});

// GET /api/stats — dashboard summary
app.get('/api/stats', (req, res) => {
  if (!requireAdminKey(req, res)) return;
  const list = Array.from(invoiceStore.values());
  const totalCount = list.length;
  const totalAmount = list.reduce((s, i) => s + (parseFloat(i.totalAmount) || 0), 0);
  const paidAmount  = list.reduce((s, i) => s + (parseFloat(i.paidAmount)  || 0), 0);
  const balance     = list.reduce((s, i) => s + (parseFloat(i.balanceAmount) || 0), 0);

  // Status breakdown using numeric index (0=draft,1=sent,2=pending,3=paid,4=overdue,5=cancelled)
  const statusNames = ['draft','sent','pending','paid','overdue','cancelled'];
  const byStatus = {};
  for (const inv of list) {
    const label = statusNames[inv.status] || 'unknown';
    byStatus[label] = (byStatus[label] || 0) + 1;
  }

  // Monthly totals (by invoiceDate, last 6 months)
  const monthly = {};
  for (const inv of list) {
    const d = inv.invoiceDate ? inv.invoiceDate.slice(0, 7) : null; // YYYY-MM
    if (d) monthly[d] = (monthly[d] || 0) + (parseFloat(inv.totalAmount) || 0);
  }

  res.json({ ok: true, totalCount, totalAmount, paidAmount, balance, byStatus, monthly });
});

// Reload config.json without restarting (add new machines live)
app.post('/reload', (_, res) => {
  try {
    config = loadConfig();
    broadcastAdmins({ type: 'machines', machines: machineList() });
    res.json({ ok: true, machines: config.machines.length });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Start ─────────────────────────────────────────────────────────────────────

const PORT = process.env.PORT || 3002;
server.listen(PORT, '0.0.0.0', () => {
  console.log('');
  console.log('  ╔═══════════════════════════════════════╗');
  console.log('  ║   NSB Motors Relay Server  v1.0       ║');
  console.log(`  ║   Listening on port ${PORT}               ║`);
  console.log('  ╚═══════════════════════════════════════╝');
  console.log('');
  console.log(`  Web portal : http://localhost:${PORT}`);
  console.log(`  Health     : http://localhost:${PORT}/health`);
  console.log(`  Machines   : ${config.machines.length} configured`);
  console.log('');
});
