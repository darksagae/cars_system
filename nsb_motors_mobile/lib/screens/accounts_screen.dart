import 'dart:math';
import 'package:flutter/material.dart';
import '../services/cloud_control_service.dart';
import '../theme/leon_theme.dart';
import '../widgets/leon/leon_bezel_card.dart';
import '../widgets/leon/leon_section_header.dart';
import '../widgets/leon/leon_brand_header.dart';
import 'account_detail_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _cloud = CloudControlService();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;
  final Map<int, TextEditingController> _usernameCtrls = {};
  final Map<int, TextEditingController> _passwordCtrls = {};
  final Map<String, bool> _revealed = {};
  int? _savingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _usernameCtrls.values) {
      c.dispose();
    }
    for (final c in _passwordCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _cloud.fetchUsers();
      for (final old in _usernameCtrls.values) {
        old.dispose();
      }
      for (final old in _passwordCtrls.values) {
        old.dispose();
      }
      _usernameCtrls.clear();
      _passwordCtrls.clear();

      for (final u in users) {
        final id = u['id'] as int;
        _usernameCtrls[id] = TextEditingController(text: '${u['username'] ?? ''}');
        _passwordCtrls[id] = TextEditingController(text: '${u['password'] ?? ''}');
      }

      setState(() => _users = users);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(int id) async {
    final user = _users.firstWhere((u) => u['id'] == id);
    final username = _usernameCtrls[id]?.text.trim() ?? '';
    final password = _passwordCtrls[id]?.text ?? '';

    setState(() => _savingId = id);
    try {
      await _cloud.updateUser(
        id,
        username: username != user['username'] ? username : null,
        password: password.isNotEmpty && password != (user['password'] ?? '') ? password : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account updated')),
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
      if (mounted) setState(() => _savingId = null);
    }
  }

  String _generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    final rnd = Random.secure();
    return List.generate(10, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<void> _resetPassword(int id) async {
    final user = _users.firstWhere((u) => u['id'] == id);
    final name = user['displayName']?.toString() ?? user['username']?.toString() ?? 'User';
    final ctrl = TextEditingController(text: _generatePassword());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset password — $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set a new password for this account. Share it with the user securely.'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'New password', isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );

    if (confirmed != true) {
      ctrl.dispose();
      return;
    }

    final newPassword = ctrl.text.trim();
    ctrl.dispose();
    if (newPassword.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 6 characters')),
        );
      }
      return;
    }

    setState(() => _savingId = id);
    try {
      await _cloud.updateUser(id, password: newPassword);
      _passwordCtrls[id]?.text = newPassword;
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Password reset'),
            content: SelectableText(
              'New password for $name:\n\n$newPassword\n\nTell the user to sign in with this password.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
            ],
          ),
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
      if (mounted) setState(() => _savingId = null);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final id = user['id'] as int;
    setState(() => _savingId = id);
    try {
      await _cloud.updateUser(id, isActive: !(user['isActive'] == true));
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _savingId = null);
    }
  }

  void _openAccountDetail(Map<String, dynamic> user) {
    final id = user['id'] as int;
    final name = user['displayName']?.toString() ?? user['username']?.toString() ?? 'User';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountDetailScreen(userId: id, displayName: name),
      ),
    );
  }

  String _formatWhen(dynamic iso) {
    if (iso == null) return 'Never';
    try {
      final dt = DateTime.parse(iso.toString());
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LeonColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LeonBrandHeader(
                      title: 'Account Control',
                      subtitle: 'Registered sales accounts on access.nsbmotors.com',
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Row(
                        children: [
                          _statChip(
                            '${_users.where((u) => u['online'] == true).length}',
                            'Online',
                            LeonColors.success,
                          ),
                          const SizedBox(width: 10),
                          _statChip('${_users.length}', 'Total', LeonColors.accent),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_loading && _users.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_error != null && _users.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = _users[index];
                        final id = user['id'] as int;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _accountCard(user, id),
                        );
                      },
                      childCount: _users.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: LeonTypography.num(fontSize: 16, color: color)),
          const SizedBox(width: 6),
          Text(label, style: LeonTypography.mono(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _accountCard(Map<String, dynamic> user, int id) {
    final online = user['online'] == true;
    final active = user['isActive'] != false;
    final nameKey = 'name-$id';
    final passKey = 'pass-$id';
    final showName = _revealed[nameKey] == true;
    final showPass = _revealed[passKey] == true;

    return LeonBezelCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: online ? LeonColors.success : LeonColors.muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _openAccountDetail(user),
                  child: Text(
                    user['displayName']?.toString() ?? user['username']?.toString() ?? 'User',
                    style: LeonTypography.sans(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openAccountDetail(user),
                child: const Text('Manage'),
              ),
              if (!active)
                Text('DISABLED', style: LeonTypography.mono(fontSize: 9, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Last seen ${_formatWhen(user['lastSeenAt'])} · ${user['invoiceCount'] ?? 0} invoices',
            style: LeonTypography.sans(fontSize: 11, color: LeonColors.secondary),
          ),
          const SizedBox(height: 14),
          const LeonSectionHeader('Username', color: LeonColors.secondary),
          const SizedBox(height: 6),
          _credentialField(
            controller: _usernameCtrls[id]!,
            obscure: !showName,
            onToggle: () => setState(() => _revealed[nameKey] = !showName),
            revealed: showName,
          ),
          const SizedBox(height: 12),
          const LeonSectionHeader('Password', color: LeonColors.secondary),
          const SizedBox(height: 6),
          _credentialField(
            controller: _passwordCtrls[id]!,
            obscure: !showPass,
            onToggle: () => setState(() => _revealed[passKey] = !showPass),
            revealed: showPass,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _savingId == id ? null : () => _save(id),
                  child: Text(_savingId == id ? 'Saving…' : 'Save'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _savingId == id ? null : () => _resetPassword(id),
                child: const Text('Reset password'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _savingId == id ? null : () => _toggleActive(user),
                  child: Text(active ? 'Disable' : 'Enable'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _credentialField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required bool revealed,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: LeonTypography.mono(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        suffixIcon: IconButton(
          icon: Icon(revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
