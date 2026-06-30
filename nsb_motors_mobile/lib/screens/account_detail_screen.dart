import 'package:flutter/material.dart';
import 'account_invoice_detail_screen.dart';
import '../services/cloud_control_service.dart';
import '../theme/leon_theme.dart';
import '../widgets/leon/leon_bezel_card.dart';
import '../widgets/leon/leon_section_header.dart';

class AccountDetailScreen extends StatefulWidget {
  final int userId;
  final String displayName;

  const AccountDetailScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen>
    with SingleTickerProviderStateMixin {
  final _cloud = CloudControlService();
  late TabController _tabs;

  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _activities = [];
  bool _loading = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _cloud.fetchUserDetail(widget.userId);
      setState(() {
        _user = Map<String, dynamic>.from(data['user'] as Map);
        _invoices = (data['invoices'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _customers = (data['customers'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _activities = (data['activities'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runCommand(String command, {Map<String, dynamic>? payload}) async {
    setState(() => _busy = true);
    try {
      await _cloud.sendUserCommand(widget.userId, command, payload: payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Command sent: $command')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeleteInvoice(Map<String, dynamic> invoice) async {
    final number = invoice['invoiceNumber']?.toString() ?? '';
    if (number.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete invoice'),
        content: Text(
          'Delete invoice $number from cloud and queue removal on the user\'s machine?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await _cloud.deleteUserInvoice(widget.userId, number);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $number')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _lockMachine() async {
    final messageCtrl = TextEditingController(
      text: 'You are temporarily banned. Contact NSB Motors administrator.',
    );
    final hoursCtrl = TextEditingController(text: '24');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lock machine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageCtrl,
              decoration: const InputDecoration(
                labelText: 'Message shown on machine',
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hoursCtrl,
              decoration: const InputDecoration(
                labelText: 'Ban duration (hours, 0 = until unlocked)',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lock')),
        ],
      ),
    );

    final message = messageCtrl.text.trim();
    final hours = int.tryParse(hoursCtrl.text.trim()) ?? 24;
    messageCtrl.dispose();
    hoursCtrl.dispose();
    if (ok != true) return;

    await _runCommand('lock_machine', payload: {
      'message': message,
      'hours': hours,
    });
  }

  Future<void> _clearLocalData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear local data'),
        content: const Text(
          'Wipe all invoices, customers, and payments on this user\'s machine?\n\nCloud data is not affected.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _runCommand('clear_local_data');
  }

  Future<void> _pushInvoice(Map<String, dynamic> invoice) async {
    final number = invoice['invoiceNumber']?.toString() ?? '';
    if (number.isEmpty) return;
    await _runCommand('push_invoice', payload: {'invoiceNumber': number});
  }

  Future<void> _transferMachine() async {
    final deviceName = _user?['assignedMachineName']?.toString() ?? 'current device';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transfer to new machine'),
        content: Text(
          'Unlink $deviceName and allow this user to sign in on a replacement PC?\n\n'
          '• The old PC will be logged out and local data cleared\n'
          '• The user must sign in on the new PC and tap "Link this device"\n'
          '• Invoices will download from the cloud\n'
          '• The old PC cannot be used again for this account',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Transfer', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await _cloud.transferUserMachine(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Machine transfer started — waiting for new PC link')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatWhen(dynamic iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = _user?['machineLocked'] == true;

    return Scaffold(
      backgroundColor: LeonColors.canvas,
      appBar: AppBar(
        backgroundColor: LeonColors.surface,
        foregroundColor: LeonColors.ink,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/logo/logo.png', width: 28, height: 28, fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NSBMotors Ug', style: LeonTypography.mono(fontSize: 9, color: LeonColors.secondary)),
                  Text(widget.displayName, style: LeonTypography.sans(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: LeonColors.accent,
          unselectedLabelColor: LeonColors.secondary,
          indicatorColor: LeonColors.accent,
          tabs: const [
            Tab(text: 'Invoices'),
            Tab(text: 'Customers'),
            Tab(text: 'Activity'),
            Tab(text: 'Remote'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _invoicesTab(),
                    _customersTab(),
                    _activityTab(),
                    _remoteTab(locked),
                  ],
                ),
    );
  }

  Widget _invoicesTab() {
    if (_invoices.isEmpty) {
      return Center(
        child: Text('No invoices', style: LeonTypography.sans(color: LeonColors.secondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        itemCount: _invoices.length,
        itemBuilder: (context, i) {
          final inv = _invoices[i];
          final number = inv['invoiceNumber']?.toString() ?? '—';
          final customer = inv['consigneeName']?.toString() ??
              (inv['customer'] as Map?)?['name']?.toString() ??
              '—';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LeonBezelCard(
              padding: const EdgeInsets.all(14),
              child: InkWell(
                onTap: _busy
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => AccountInvoiceDetailScreen(
                              userId: widget.userId,
                              invoiceNumber: number,
                            ),
                          ),
                        );
                      },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(number, style: LeonTypography.mono(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(customer, style: LeonTypography.sans(fontSize: 12, color: LeonColors.secondary)),
                          Text(
                            _formatWhen(inv['updatedAt'] ?? inv['createdAt']),
                            style: LeonTypography.mono(fontSize: 10, color: LeonColors.muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'View invoice',
                      onPressed: _busy
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => AccountInvoiceDetailScreen(
                                    userId: widget.userId,
                                    invoiceNumber: number,
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                    ),
                    IconButton(
                      tooltip: 'Push to machine for edit',
                      onPressed: _busy ? null : () => _pushInvoice(inv),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: _busy ? null : () => _confirmDeleteInvoice(inv),
                      icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _customersTab() {
    if (_customers.isEmpty) {
      return Center(
        child: Text('No customers', style: LeonTypography.sans(color: LeonColors.secondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: _customers.length,
      itemBuilder: (context, i) {
        final c = _customers[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LeonBezelCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c['name']?.toString() ?? '—',
                  style: LeonTypography.sans(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                if (c['phone'] != null)
                  Text(c['phone'].toString(), style: LeonTypography.mono(fontSize: 12, color: LeonColors.secondary)),
                if (c['email'] != null)
                  Text(c['email'].toString(), style: LeonTypography.mono(fontSize: 11, color: LeonColors.muted)),
                const SizedBox(height: 4),
                Text(
                  '${c['invoiceCount'] ?? 0} invoice(s)',
                  style: LeonTypography.mono(fontSize: 10, color: LeonColors.accent),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _activityTab() {
    if (_activities.isEmpty) {
      return Center(
        child: Text('No activity', style: LeonTypography.sans(color: LeonColors.secondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: _activities.length,
      itemBuilder: (context, i) {
        final a = _activities[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: LeonBezelCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    a['action']?.toString() ?? '—',
                    style: LeonTypography.mono(fontSize: 12),
                  ),
                ),
                Text(
                  _formatWhen(a['createdAt']),
                  style: LeonTypography.mono(fontSize: 10, color: LeonColors.muted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _remoteTab(bool locked) {
    final assignedMachineId = _user?['assignedMachineId']?.toString();
    final transferPending = _user?['transferPending'] == true;
    final blockedMachineName = _user?['blockedMachineName']?.toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        LeonBezelCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LeonSectionHeader('Machine assignment', color: LeonColors.secondary),
              const SizedBox(height: 8),
              if (transferPending) ...[
                Text(
                  'Waiting for user to link a new PC',
                  style: LeonTypography.mono(
                    fontSize: 13,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (blockedMachineName != null && blockedMachineName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Previous device: $blockedMachineName',
                    style: LeonTypography.sans(fontSize: 12, color: LeonColors.secondary),
                  ),
                ],
              ] else if (_user?['assignedMachineName'] != null) ...[
                Text(
                  'Device: ${_user!['assignedMachineName']}',
                  style: LeonTypography.sans(fontSize: 12, color: LeonColors.secondary),
                ),
              ] else ...[
                Text(
                  'No machine linked',
                  style: LeonTypography.sans(fontSize: 12, color: LeonColors.muted),
                ),
              ],
              if (assignedMachineId != null && assignedMachineId.isNotEmpty && !transferPending) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _transferMachine,
                  icon: Icon(Icons.swap_horiz, size: 18, color: Colors.orange.shade800),
                  label: Text(
                    'Transfer to new machine',
                    style: LeonTypography.sans(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    foregroundColor: Colors.orange.shade800,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        LeonBezelCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LeonSectionHeader('Machine status', color: LeonColors.secondary),
              const SizedBox(height: 8),
              Text(
                locked ? 'LOCKED' : 'Active',
                style: LeonTypography.mono(
                  fontSize: 14,
                  color: locked ? Colors.red : LeonColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (locked && _user?['lockMessage'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  _user!['lockMessage'].toString(),
                  style: LeonTypography.sans(fontSize: 12, color: LeonColors.secondary),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const LeonSectionHeader('Remote control', color: LeonColors.secondary),
        const SizedBox(height: 8),
        _remoteButton(
          locked ? 'Unlock machine' : 'Lock machine (temporary ban)',
          locked ? Icons.lock_open_outlined : Icons.block,
          locked ? () => _runCommand('unlock_machine') : _lockMachine,
          danger: !locked,
        ),
        _remoteButton('Clear all local data on machine', Icons.delete_sweep_outlined, _clearLocalData, danger: true),
        _remoteButton('Force logout on machine', Icons.logout, () => _runCommand('logout_user')),
        const SizedBox(height: 16),
        Text(
          'Tip: use the edit icon on an invoice to sync it to the user\'s machine and open it for editing.',
          style: LeonTypography.sans(fontSize: 11, color: LeonColors.muted),
        ),
      ],
    );
  }

  Widget _remoteButton(String label, IconData icon, VoidCallback onTap, {bool danger = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: _busy ? null : onTap,
        icon: Icon(icon, size: 18, color: danger ? Colors.red.shade700 : LeonColors.accent),
        label: Text(label, style: LeonTypography.sans(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          foregroundColor: danger ? Colors.red.shade700 : LeonColors.ink,
        ),
      ),
    );
  }
}
