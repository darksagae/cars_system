import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/machine_management_service.dart';
import '../providers/app_provider.dart';

class MachinesScreen extends StatefulWidget {
  const MachinesScreen({Key? key}) : super(key: key);

  @override
  State<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends State<MachinesScreen> {
  final _service = MachineManagementService();
  bool _connecting = false;
  final _urlCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();

  static const _canvas = Color(0xFFF8FAFC);
  static const _ink = Color(0xFF0F172A);
  static const _secondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _accent = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = _service.relayUrl;
    if (!_service.isConnected) _service.loadAndConnect();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _urlCtrl.text.trim();
    final pwd = _pwdCtrl.text.trim();
    if (url.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter relay URL and admin password')));
      return;
    }
    setState(() => _connecting = true);
    await _service.connectToRelay(url: url, password: pwd);
    if (mounted) setState(() => _connecting = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _canvas,
          appBar: _buildAppBar(),
          body: _service.isConnected
              ? _buildBody()
              : _buildOfflineState(),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Machine Control'),
      backgroundColor: Colors.white,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: _border),
      ),
      actions: [
        if (_service.isConnected)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _showBroadcastSheet,
              icon: const Icon(Icons.broadcast_on_personal_rounded, size: 16),
              label: const Text('Broadcast'),
              style: TextButton.styleFrom(foregroundColor: _accent),
            ),
          ),
      ],
    );
  }

  Widget _buildOfflineState() {
    final isConnecting = _service.status == RelayStatus.connecting || _connecting;
    final isError = _service.status == RelayStatus.error;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isError
                          ? const Color(0xFFFEF2F2)
                          : isConnecting
                              ? const Color(0xFFFFFBEB)
                              : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isConnecting
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isError
                                ? Icons.cloud_off_rounded
                                : Icons.cloud_sync_rounded,
                            size: 20,
                            color: isError
                                ? const Color(0xFFDC2626)
                                : _accent,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnecting
                              ? 'Connecting to relay…'
                              : isError
                                  ? 'Connection failed'
                                  : 'Not connected',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
                        ),
                        Text(
                          isConnecting
                              ? 'Reaching portal.nsbmotors.com'
                              : 'Enter your relay URL below',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: _secondary),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Text('RELAY URL',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        letterSpacing: 1.2, color: _secondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _urlCtrl,
                  decoration: InputDecoration(
                    hintText: 'https://portal.nsbmotors.com',
                    prefixIcon: const Icon(Icons.link_rounded, size: 18),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                Text('ADMIN PASSWORD',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        letterSpacing: 1.2, color: _secondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _pwdCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Admin password from config.json',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isConnecting ? null : _connect,
                    icon: isConnecting
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: Text(isConnecting ? 'Connecting…' : 'Connect to Relay'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Setup Guide',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669))),
                const SizedBox(height: 8),
                _setupStep('1', 'Run server.js on the master desktop PC'),
                _setupStep('2', 'Set up Cloudflare Tunnel → portal.nsbmotors.com'),
                _setupStep('3', 'Enter relay URL above and connect'),
                _setupStep('4', 'Each desktop machine connects to the relay'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupStep(String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(n,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: const Color(0xFF166534))),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final machines = _service.machines;
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: _accent,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  _buildServerCard(),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _buildQuickBroadcasts(),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Connected Machines'),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (machines.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyMachines())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMachineCard(machines[index]),
                  ),
                  childCount: machines.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServerCard() {
    final url = _service.relayUrl.isEmpty ? 'portal.nsbmotors.com' : _service.relayUrl;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Relay Connected',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(url,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: Colors.white.withOpacity(0.75)),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Server URL copied')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('COPY',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard('${_service.onlineCount}', 'Online Now',
              Icons.wifi_rounded, const Color(0xFF059669), const Color(0xFFECFDF5)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard('${_service.totalCount}', 'Total Machines',
              Icons.computer_rounded, _accent, const Color(0xFFEFF6FF)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard('${_service.globalActivities.length}', 'Activities',
              Icons.timeline_rounded, const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
        ),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w800, color: _ink)),
          Text(label,
              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _secondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildQuickBroadcasts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Broadcast to All'),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _broadcastChip(
                  Icons.currency_exchange_rounded,
                  'Update Prices',
                  const Color(0xFFD97706),
                  const Color(0xFFFFFBEB),
                  _showUpdatePricesSheet),
              const SizedBox(width: 8),
              _broadcastChip(
                  Icons.storage_rounded,
                  'Push MV Database',
                  const Color(0xFF059669),
                  const Color(0xFFECFDF5),
                  _showPushDatabaseSheet),
              const SizedBox(width: 8),
              _broadcastChip(
                  Icons.refresh_rounded,
                  'Restart All',
                  const Color(0xFF7C3AED),
                  const Color(0xFFF5F3FF),
                  () => _broadcastCommand('restart_application', 'Restart All Machines')),
              const SizedBox(width: 8),
              _broadcastChip(
                  Icons.delete_sweep_rounded,
                  'Clear Activities',
                  const Color(0xFFDC2626),
                  const Color(0xFFFEF2F2),
                  _confirmClearAll),
            ],
          ),
        ),
      ],
    );
  }

  Widget _broadcastChip(
      IconData icon, String label, Color color, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.2),
    );
  }

  Widget _buildEmptyMachines() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.computer_rounded,
                    size: 32, color: Color(0xFF1D4ED8)),
              ),
              const SizedBox(height: 16),
              Text('No machines connected',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
              const SizedBox(height: 8),
              Text(
                'Desktop clients should connect to:\n${_service.serverUrl ?? "—"}',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: _secondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                'WebSocket port: ${_service.port}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMachineCard(ConnectedMachine machine) {
    final isOnline = machine.isOnline;
    final statusColor = isOnline ? const Color(0xFF059669) : const Color(0xFF94A3B8);
    final statusBg = isOnline ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? const Color(0xFF059669).withOpacity(0.2) : _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.computer_rounded, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(machine.clientName,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
                      Text(
                        (machine.platform ?? 'Unknown') + (machine.os != null ? '  •  ${machine.os}' : ''),
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _secondary),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOnline ? 'ONLINE' : 'OFFLINE',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _infoPill(Icons.location_on_outlined, machine.ipAddress),
                if (machine.currentUser != null)
                  _infoPill(Icons.person_rounded, machine.currentUser!),
                _infoPill(Icons.schedule_rounded, _lastSeenText(machine.lastSeen)),
                if (machine.cpuUsage != null)
                  _infoPill(Icons.memory_rounded,
                      'CPU ${machine.cpuUsage!.toStringAsFixed(0)}%'),
              ],
            ),
          ),

          // Monitoring bar
          if (isOnline && machine.cpuUsage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildMonitorBar(machine),
            ),

          Divider(height: 1, color: _border),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: _actionBtn(Icons.tune_rounded, 'Control', _accent, const Color(0xFFEFF6FF), isOnline, () => _showMachineControlSheet(machine))),
                const SizedBox(width: 8),
                Expanded(child: _actionBtn(Icons.timeline_rounded, 'Activity', const Color(0xFF7C3AED), const Color(0xFFF5F3FF), true, () => _showActivitiesSheet(machine))),
                const SizedBox(width: 8),
                Expanded(child: _actionBtn(Icons.monitor_rounded, 'Monitor', const Color(0xFF0891B2), const Color(0xFFE0F2FE), isOnline, () => _showMonitorSheet(machine))),
                const SizedBox(width: 8),
                Expanded(child: _actionBtn(Icons.delete_outline_rounded, 'Remove', const Color(0xFFDC2626), const Color(0xFFFEF2F2), true, () => _confirmRemoveMachine(machine))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitorBar(ConnectedMachine machine) {
    final cpu = (machine.cpuUsage ?? 0).clamp(0.0, 100.0) / 100;
    final mem = (machine.memUsage ?? 0).clamp(0.0, 100.0) / 100;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CPU ${(cpu * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _secondary)),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: cpu,
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: cpu > 0.8 ? const Color(0xFFDC2626) : _accent,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        if (machine.memUsage != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MEM ${(mem * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _secondary)),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: mem,
                    backgroundColor: const Color(0xFFF1F5F9),
                    color: mem > 0.85 ? const Color(0xFFD97706) : const Color(0xFF059669),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _secondary),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _secondary)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, Color bg,
      bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sheets ────────────────────────────────────────────────────────────────

  void _showMachineControlSheet(ConnectedMachine machine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _MachineControlSheet(machine: machine, service: _service),
    );
  }

  void _showActivitiesSheet(ConnectedMachine machine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ActivitiesSheet(machine: machine, service: _service),
    );
  }

  void _showMonitorSheet(ConnectedMachine machine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AnimatedBuilder(
        animation: _service,
        builder: (ctx, _) {
          final m = _service.getMachine(machine.clientId) ?? machine;
          return _MonitorSheet(machine: m);
        },
      ),
    );
  }

  void _showBroadcastSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BroadcastSheet(service: _service),
    );
  }

  void _showUpdatePricesSheet() {
    final rateCtrl = TextEditingController();
    final phase1Ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const SizedBox(height: 8),
            Text('Update Exchange Rate',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
            Text('Broadcast to all connected machines',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _secondary)),
            const SizedBox(height: 20),
            TextField(
              controller: rateCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Tax Rate (USD → UGX)', hintText: '3700'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phase1Ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Phase 1 Rate (optional)', hintText: 'Leave empty'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final rate = double.tryParse(rateCtrl.text.trim());
                  if (rate == null || rate <= 0) return;
                  final p1 = double.tryParse(phase1Ctrl.text.trim());
                  Navigator.pop(ctx);
                  final ok =
                      await _service.updateExchangeRate(rate, phase1Rate: p1);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? 'Exchange rate broadcast to ${_service.onlineCount} machine(s)'
                          : 'No machines online'),
                    ));
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Broadcast Rate'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPushDatabaseSheet() {
    final appProvider = context.read<AppProvider>();
    final updates = appProvider.uraUpdates;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 8),
                  Text('Push MV Database',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
                  Text('Broadcast to all connected machines',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: _secondary)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: updates.isEmpty
                  ? Center(
                      child: Text('No database updates available',
                          style: GoogleFonts.plusJakartaSans(color: _secondary)))
                  : ListView.separated(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      itemCount: updates.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final u = updates[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.storage_rounded,
                                color: Color(0xFF059669), size: 20),
                          ),
                          title: Text(u['month'] ?? '—',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(u['file_name'] ?? '—',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: _secondary)),
                          trailing: Text('${u['record_count'] ?? 0} rec.',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: _secondary)),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final fileUrl = u['file_url'] as String? ?? '';
                            if (fileUrl.isEmpty) return;
                            final n = await _service.updateMvDatabase(
                              fileUrl: fileUrl,
                              month: u['month'] ?? '—',
                              recordCount: (u['record_count'] as num?)?.toInt() ?? 0,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('MV Database pushed to $n machine(s)'),
                              ));
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _broadcastCommand(String command, String description) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(description,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
            'This will send "$command" to all ${_service.onlineCount} online machine(s).',
            style: GoogleFonts.plusJakartaSans(color: _secondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send')),
        ],
      ),
    );
    if (confirmed != true) return;
    final n = await _service.broadcastCommand(command);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Command sent to $n machine(s)')),
      );
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear All Activities?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('This will clear activity logs for all machines.',
            style: GoogleFonts.plusJakartaSans(color: _secondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) _service.clearAllActivities();
  }

  Future<void> _confirmRemoveMachine(ConnectedMachine machine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove Machine?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Remove ${machine.clientName} from the list?',
            style: GoogleFonts.plusJakartaSans(color: _secondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) _service.removeMachine(machine.clientId);
  }

  String _lastSeenText(String? iso) {
    if (iso == null) return 'Never';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Unknown';
    return _timeAgo(dt);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _sheetHandle() => Center(
        child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: _border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

// ─── Machine Control Sheet ────────────────────────────────────────────────────

class _MachineControlSheet extends StatefulWidget {
  final ConnectedMachine machine;
  final MachineManagementService service;
  const _MachineControlSheet({required this.machine, required this.service});

  @override
  State<_MachineControlSheet> createState() => _MachineControlSheetState();
}

class _MachineControlSheetState extends State<_MachineControlSheet> {
  static const _ink = Color(0xFF0F172A);
  static const _secondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  Future<void> _send(String command, String label,
      {Map<String, dynamic>? data}) async {
    final ok = await widget.service
        .sendCommand(widget.machine.clientId, command, data: data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '$label sent' : 'Machine is offline'),
        backgroundColor: ok ? const Color(0xFF059669) : const Color(0xFFDC2626),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Machine Control',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
                      Text(widget.machine.clientName,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, color: _secondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _sectionLabel('Power & System'),
            const SizedBox(height: 10),
            _controlGroup([
              _ctrlTile(Icons.refresh_rounded, const Color(0xFFD97706),
                  const Color(0xFFFFFBEB), 'Restart Application',
                  'Restart the desktop app', () => _send('restart_application', 'Restart')),
              _ctrlTile(Icons.logout_rounded, const Color(0xFFDC2626),
                  const Color(0xFFFEF2F2), 'Logout User',
                  'Force logout current user', () => _send('logout_user', 'Logout')),
              _ctrlTile(Icons.lock_rounded, const Color(0xFF64748B),
                  const Color(0xFFF1F5F9), 'Lock Screen',
                  'Lock the machine screen', () => _send('lock_screen', 'Lock')),
            ]),

            const SizedBox(height: 20),
            _sectionLabel('Database & Prices'),
            const SizedBox(height: 10),
            _controlGroup([
              _ctrlTile(Icons.storage_rounded, const Color(0xFF059669),
                  const Color(0xFFECFDF5), 'Refresh Database',
                  'Force database refresh', () => _send('refresh_database', 'DB Refresh')),
              _ctrlTile(Icons.currency_exchange_rounded, const Color(0xFF1D4ED8),
                  const Color(0xFFEFF6FF), 'Update Exchange Rate',
                  'Set new exchange rate', _showRateDialog),
              _ctrlTile(Icons.cloud_download_rounded, const Color(0xFF7C3AED),
                  const Color(0xFFF5F3FF), 'Push MV Database',
                  'Send used MV database file', _showDbDialog),
            ]),

            const SizedBox(height: 20),
            _sectionLabel('User & Email Settings'),
            const SizedBox(height: 10),
            _controlGroup([
              _ctrlTile(Icons.password_rounded, const Color(0xFF0891B2),
                  const Color(0xFFE0F2FE), 'Reset Password',
                  'Reset a user password', _showResetPasswordDialog),
              _ctrlTile(Icons.email_rounded, const Color(0xFF7C3AED),
                  const Color(0xFFF5F3FF), 'Update Email Config',
                  'Configure SMTP settings', _showEmailConfigDialog),
            ]),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
            letterSpacing: 1.2),
      );

  Widget _controlGroup(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(children: children),
      );

  Widget _ctrlTile(IconData icon, Color color, Color bg, String title,
      String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
      subtitle: Text(subtitle,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _secondary)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Color(0xFFCBD5E1), size: 20),
    );
  }

  void _showRateDialog() {
    final ctrl = TextEditingController();
    final p1ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Exchange Rate',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Tax Rate (UGX)', hintText: '3700'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: p1ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Phase 1 Rate (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final rate = double.tryParse(ctrl.text.trim());
              if (rate == null) return;
              final p1 = double.tryParse(p1ctrl.text.trim());
              Navigator.pop(ctx);
              await _send('update_exchange_rate', 'Rate Update',
                  data: {'rate': rate, 'tax_rate': rate, if (p1 != null) 'phase1_rate': p1});
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showDbDialog() {
    // Show MV database list from AppProvider
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Use Broadcast → Push MV Database to push files')),
    );
  }

  void _showResetPasswordDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (userCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              await widget.service.resetUserPassword(
                widget.machine.clientId,
                username: userCtrl.text.trim(),
                newPassword: passCtrl.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset command sent')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showEmailConfigDialog() {
    final hostCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '587');
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Email Config',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: hostCtrl,
                  decoration: const InputDecoration(labelText: 'SMTP Host', hintText: 'smtp.gmail.com')),
              const SizedBox(height: 10),
              TextField(controller: portCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'SMTP Port')),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address')),
              const SizedBox(height: 10),
              TextField(controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'App Password')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (hostCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              await widget.service.updateEmailConfig(
                widget.machine.clientId,
                smtpHost: hostCtrl.text.trim(),
                smtpPort: portCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                password: passCtrl.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email config sent')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

// ─── Activities Sheet ─────────────────────────────────────────────────────────

class _ActivitiesSheet extends StatelessWidget {
  final ConnectedMachine machine;
  final MachineManagementService service;
  const _ActivitiesSheet({required this.machine, required this.service});

  static const _ink = Color(0xFF0F172A);
  static const _secondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (ctx, _) {
        final activities = service.globalActivities
            .where((a) => a.machineId == machine.clientId)
            .toList();
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scroll) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Activities',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
                          Text(machine.clientName,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, color: _secondary)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        service.clearActivitiesForMachine(machine.clientId);
                      },
                      child: Text('Clear',
                          style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFDC2626))),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: _border),
              Expanded(
                child: activities.isEmpty
                    ? Center(
                        child: Text('No activities recorded',
                            style: GoogleFonts.plusJakartaSans(color: _secondary)),
                      )
                    : ListView.separated(
                        controller: scroll,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        itemCount: activities.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: _border),
                        itemBuilder: (_, i) => _activityRow(activities[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'success': return const Color(0xFF059669);
      case 'failed': case 'error': return const Color(0xFFDC2626);
      case 'sent': return const Color(0xFF1D4ED8);
      default: return const Color(0xFF94A3B8);
    }
  }

  Widget _activityRow(MachineActivity a) {
    final color = _statusColor(a.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.bolt_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.displayAction,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
                Row(
                  children: [
                    Text(a.status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                    if (a.username != null) ...[
                      Text('  •  ${a.username}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, color: _secondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(_timeAgo(a.timestamp),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Monitor Sheet ────────────────────────────────────────────────────────────

class _MonitorSheet extends StatelessWidget {
  final ConnectedMachine machine;
  const _MonitorSheet({required this.machine});

  static const _ink = Color(0xFF0F172A);
  static const _secondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _accent = Color(0xFF1D4ED8);

  @override
  Widget build(BuildContext context) {
    final cpu = (machine.cpuUsage ?? 0).clamp(0.0, 100.0);
    final mem = (machine.memUsage ?? 0).clamp(0.0, 100.0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _border, borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Machine Monitor',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
          Text(machine.clientName,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _secondary)),
          const SizedBox(height: 20),

          _infoRow('Platform', machine.platform ?? 'Unknown'),
          _infoRow('IP Address', machine.ipAddress),
          _infoRow('Version', machine.version),
          if (machine.currentUser != null)
            _infoRow('Current User', machine.currentUser!),
          if (machine.os != null) _infoRow('OS', machine.os!),
          _infoRow('Status', machine.isOnline ? 'Online' : 'Offline'),
          _infoRow('Last Seen', _lastSeenText(machine.lastSeen)),

          const SizedBox(height: 16),
          if (machine.cpuUsage != null) ...[
            _monitorBar('CPU Usage', cpu, _accent),
            const SizedBox(height: 12),
          ],
          if (machine.memUsage != null) ...[
            _monitorBar('Memory Usage', mem, const Color(0xFF059669)),
            const SizedBox(height: 12),
          ],
          if (machine.cpuUsage == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Text(
                'No monitoring data yet. The desktop client needs to send heartbeats with CPU/memory stats.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _secondary),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _secondary)),
            ),
            Expanded(
              child: Text(value,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _ink)),
            ),
          ],
        ),
      );

  Widget _monitorBar(String label, double value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
              Text('${value.toStringAsFixed(0)}%',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: const Color(0xFFF1F5F9),
              color: value > 85 ? const Color(0xFFDC2626) : color,
              minHeight: 10,
            ),
          ),
        ],
      );

  String _lastSeenText(String? iso) {
    if (iso == null) return 'Never';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ─── Broadcast Sheet ──────────────────────────────────────────────────────────

class _BroadcastSheet extends StatelessWidget {
  final MachineManagementService service;
  const _BroadcastSheet({required this.service});

  static const _ink = Color(0xFF0F172A);
  static const _secondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Broadcast Command',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
          Text('Send to all ${service.onlineCount} online machine(s)',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _secondary)),
          const SizedBox(height: 20),
          _broadcastTile(context, Icons.refresh_rounded, const Color(0xFFD97706),
              const Color(0xFFFFFBEB), 'Restart All Applications',
              () => _broadcast(context, 'restart_application')),
          _broadcastTile(context, Icons.storage_rounded, const Color(0xFF059669),
              const Color(0xFFECFDF5), 'Refresh Database on All',
              () => _broadcast(context, 'refresh_database')),
          _broadcastTile(context, Icons.logout_rounded, const Color(0xFFDC2626),
              const Color(0xFFFEF2F2), 'Logout All Users',
              () => _broadcast(context, 'logout_user')),
          _broadcastTile(context, Icons.lock_rounded, const Color(0xFF64748B),
              const Color(0xFFF1F5F9), 'Lock All Screens',
              () => _broadcast(context, 'lock_screen')),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _broadcastTile(BuildContext context, IconData icon, Color color,
      Color bg, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
      trailing: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF94A3B8)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _broadcast(BuildContext context, String command) async {
    final n = await service.broadcastCommand(command);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Command sent to $n machine(s)')),
      );
    }
  }
}
