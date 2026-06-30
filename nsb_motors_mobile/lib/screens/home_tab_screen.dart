import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/cloud_api_config.dart';
import '../services/cloud_control_service.dart';
import '../theme/leon_theme.dart';
import '../widgets/leon/leon_bezel_card.dart';
import '../widgets/leon/leon_section_header.dart';
import '../widgets/leon/leon_brand_header.dart';
import 'login_screen.dart';

class HomeTabScreen extends StatefulWidget {
  final VoidCallback? onGoToAccounts;

  const HomeTabScreen({super.key, this.onGoToAccounts});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final _cloud = CloudControlService();
  Map<String, dynamic>? _overview;
  bool _loading = true;
  String? _error;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _load();
    _autoRefresh = Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _cloud.fetchOverview();
      if (mounted) {
        setState(() {
          _overview = data;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        setState(() {
          _error = msg;
          _loading = false;
        });
        if (msg.contains('Session expired') || msg.contains('Not signed in')) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    }
  }

  Future<void> _disableUser(int userId) async {
    try {
      await _cloud.updateUser(userId, isActive: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account disabled')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _openWebAdmin() async {
    final url = Uri.parse(CloudApiConfig.baseUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LeonColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: LeonColors.accent,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              if (_loading && _overview == null)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
              if (_error != null && _overview == null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                ),
              if (_overview != null) ...[
                if (_overview!['fallbackNote'] != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        _overview!['fallbackNote'].toString(),
                        style: LeonTypography.mono(fontSize: 10, color: LeonColors.warning),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: _buildCommandBar()),
                SliverToBoxAdapter(child: _buildLiveSessions()),
                SliverToBoxAdapter(child: _buildIntegrityRow()),
                SliverToBoxAdapter(child: _buildIncidents()),
                SliverToBoxAdapter(child: _buildRecentActivity()),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LeonBrandHeader(
      title: 'Control Center',
      subtitle: CloudApiConfig.baseUrl.replaceAll('https://', ''),
      trailing: IconButton(
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded),
        color: LeonColors.accent,
      ),
    );
  }

  Widget _buildCommandBar() {
    final cloud = _overview!['cloud'] as Map<String, dynamic>? ?? {};
    final fleet = _overview!['fleet'] as Map<String, dynamic>? ?? {};
    final incidents = (_overview!['incidents'] as List?)?.length ?? 0;
    final cloudOk = cloud['status'] == 'ok';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: LeonBezelCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusDot(cloudOk),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cloudOk ? 'Cloud online' : 'Cloud issue',
                    style: LeonTypography.sans(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                if (incidents > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$incidents alerts',
                      style: LeonTypography.mono(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _miniStat('${fleet['liveTotal'] ?? 0}', 'Live'),
                const SizedBox(width: 16),
                _miniStat('${fleet['registered'] ?? 0}', 'Registered'),
                const SizedBox(width: 16),
                _miniStat('${cloud['invoiceCount'] ?? 0}', 'Invoices'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openWebAdmin,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open web admin'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveSessions() {
    final sessions = (_overview!['sessions'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: LeonBezelCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LeonSectionHeader('Live logins', color: LeonColors.accent),
            const SizedBox(height: 10),
            if (sessions.isEmpty)
              Text('No registered users', style: LeonTypography.sans(color: LeonColors.secondary, fontSize: 13))
            else ...[
              _sessionTableHeader(),
              const Divider(height: 16, color: LeonColors.border),
              ...sessions.map(_sessionRow),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sessionTableHeader() {
    return Row(
      children: [
        const SizedBox(width: 18),
        Expanded(flex: 3, child: Text('Name', style: _colHeader())),
        Expanded(flex: 3, child: Text('Machine', style: _colHeader())),
        Expanded(flex: 2, child: Text('Net', style: _colHeader())),
      ],
    );
  }

  TextStyle _colHeader() => LeonTypography.mono(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: LeonColors.secondary,
        letterSpacing: 0.8,
      );

  Widget _sessionRow(Map<String, dynamic> s) {
    final online = s['online'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _statusDot(online),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['name']?.toString() ?? s['username']?.toString() ?? '—',
                  style: LeonTypography.sans(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${s['channel'] ?? '—'} · ${s['role'] ?? 'user'}',
                  style: LeonTypography.mono(fontSize: 9, color: LeonColors.muted),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              s['machine']?.toString() ?? '—',
              style: LeonTypography.mono(fontSize: 11, color: LeonColors.ink),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              s['net']?.toString() ?? 'Offline',
              style: LeonTypography.mono(
                fontSize: 11,
                color: online ? LeonColors.success : LeonColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrityRow() {
    final cloud = _overview!['cloud'] as Map<String, dynamic>? ?? {};
    final fleet = _overview!['fleet'] as Map<String, dynamic>? ?? {};
    final sync = _overview!['sync'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(child: _integrityCard('Web', [
            'Invoices: ${cloud['invoiceCount'] ?? 0}',
            'MV: ${cloud['mvDatabaseMonth'] ?? '—'}',
            cloud['mvDatabaseLocked'] == true ? 'Locked' : 'Unlocked',
          ])),
          const SizedBox(width: 10),
          Expanded(child: _integrityCard('Sync', [
            'Today: ${sync['invoicesToday'] ?? 0}',
            'Stale: ${fleet['stale'] ?? 0}',
            'Never login: ${fleet['neverLoggedIn'] ?? 0}',
          ])),
          const SizedBox(width: 10),
          Expanded(child: _integrityCard('Fleet', [
            'Desktop: ${fleet['liveDesktop'] ?? 0}',
            'Web: ${fleet['liveWeb'] ?? 0}',
            'Disabled: ${fleet['disabled'] ?? 0}',
          ])),
        ],
      ),
    );
  }

  Widget _integrityCard(String title, List<String> lines) {
    return LeonBezelCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LeonTypography.mono(fontSize: 10, fontWeight: FontWeight.w700, color: LeonColors.accent)),
          const SizedBox(height: 8),
          ...lines.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(l, style: LeonTypography.mono(fontSize: 9, color: LeonColors.secondary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidents() {
    final incidents = (_overview!['incidents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (incidents.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: LeonBezelCard(
        padding: const EdgeInsets.all(14),
        accentBorder: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LeonSectionHeader('Incidents', color: Colors.red),
            const SizedBox(height: 8),
            ...incidents.take(5).map((inc) {
              final userId = inc['userId'] as int?;
              final isPasswordReset = inc['type'] == 'password_reset';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isPasswordReset ? Icons.lock_reset_rounded : Icons.warning_amber_rounded,
                      size: 16,
                      color: isPasswordReset ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inc['title']?.toString() ?? 'Alert',
                              style: LeonTypography.sans(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(inc['detail']?.toString() ?? '',
                              style: LeonTypography.sans(fontSize: 11, color: LeonColors.secondary)),
                        ],
                      ),
                    ),
                    if (isPasswordReset && widget.onGoToAccounts != null)
                      TextButton(
                        onPressed: widget.onGoToAccounts,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Reset', style: LeonTypography.mono(fontSize: 10)),
                      )
                    else if (userId != null)
                      TextButton(
                        onPressed: () => _disableUser(userId),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Disable', style: LeonTypography.mono(fontSize: 10)),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final items = (_overview!['recentActivity'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: LeonBezelCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LeonSectionHeader('Recent activity', color: LeonColors.secondary),
            const SizedBox(height: 8),
            ...items.take(5).map((item) {
              final user = item['user'] as Map<String, dynamic>? ?? {};
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item['action']}'.replaceAll('_', ' '),
                        style: LeonTypography.sans(fontSize: 12),
                      ),
                    ),
                    Text(
                      user['username']?.toString() ?? '',
                      style: LeonTypography.mono(fontSize: 10, color: LeonColors.muted),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _statusDot(bool ok) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: ok ? LeonColors.success : Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (ok ? LeonColors.success : Colors.red).withValues(alpha: 0.4),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: LeonTypography.num(fontSize: 18, color: LeonColors.accent)),
        Text(label, style: LeonTypography.mono(fontSize: 9, color: LeonColors.secondary)),
      ],
    );
  }
}
