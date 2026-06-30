import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import 'scan_client_screen.dart';
import 'client_users_screen.dart';
import '../services/supabase_service.dart';
import '../theme/leon_theme.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({Key? key}) : super(key: key);

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  Timer? _refreshTimer;

  static const _primary = LeonColors.accent;
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _bgColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) context.read<AppProvider>().refreshDesktopClients();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Desktop Clients'),
        actions: [
          IconButton(
            onPressed: () => context.read<AppProvider>().refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'clear_all') await _clearAllClients();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 10),
                    Text('Clear All Clients',
                        style: GoogleFonts.plusJakartaSans(color: _textPrimary, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading && appProvider.desktopClients.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appProvider.desktopClients.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => appProvider.refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: appProvider.desktopClients.length,
              itemBuilder: (context, index) {
                return _buildClientCard(context, appProvider.desktopClients[index], appProvider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ScanClientScreen()),
          );
          if (ok == true && mounted) {
            context.read<AppProvider>().refresh();
          }
        },
        backgroundColor: _primary,
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: Text(
          'Add Client',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _clearAllClients() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Clients?'),
        content: Text(
          'This will permanently remove all desktop clients.',
          style: GoogleFonts.plusJakartaSans(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove All',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFFDC2626))),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final removed = await SupabaseService.deleteAllDesktopClients();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed $removed clients'),
          backgroundColor: const Color(0xFF1F2937),
        ),
      );
      await context.read<AppProvider>().refresh();
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.computer_outlined, size: 40, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 20),
            Text(
              'No Desktop Clients',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Clients will appear here once they connect to the system.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _textSecondary),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _showAddClientDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Client'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(
    BuildContext context,
    Map<String, dynamic> client,
    AppProvider appProvider,
  ) {
    final lastSeen = client['last_seen'] ?? '';
    bool isOnline = false;
    try {
      if (lastSeen is String && lastSeen.isNotEmpty) {
        final dt = DateTime.parse(lastSeen);
        isOnline = DateTime.now().toUtc().difference(dt.toUtc()).inSeconds <= 60;
      }
    } catch (_) {}

    final statusColor = isOnline ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final statusBg = isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.computer_rounded, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client['client_name'] ?? 'Unknown Client',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      Text(
                        client['client_id'] ?? '',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
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
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'ONLINE' : 'OFFLINE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildInfoChip(Icons.devices_rounded, client['platform'] ?? 'Unknown'),
                _buildInfoChip(Icons.location_on_outlined, client['ip_address'] ?? 'Unknown'),
                _buildInfoChip(Icons.schedule_rounded, _formatLastSeen(lastSeen)),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _iconBtn(Icons.info_outline_rounded, 'Details', _primary, const Color(0xFFEFF6FF), () => _showClientDetails(context, client))),
                    const SizedBox(width: 8),
                    Expanded(child: _iconBtn(Icons.admin_panel_settings_outlined, 'Users', const Color(0xFF0891B2), const Color(0xFFE0F2FE), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClientUsersScreen(clientId: (client['client_id'] ?? '').toString(), clientName: (client['client_name'] ?? 'Client').toString()))))),
                    const SizedBox(width: 8),
                    Expanded(child: _iconBtn(Icons.settings_remote_rounded, 'Control', const Color(0xFF7C3AED), const Color(0xFFF5F3FF), () => _showRemoteActions(context, client, appProvider))),
                    const SizedBox(width: 8),
                    Expanded(child: _iconBtn(Icons.delete_outline_rounded, 'Delete', const Color(0xFFDC2626), const Color(0xFFFEF2F2), () => _deleteClient(context, client))),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showClientActivities(context, client),
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text('View Recent Activities'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      side: const BorderSide(color: Color(0xFFFBBF24)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _textSecondary),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
          minimumSize: const Size(0, 36),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
      );
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
        minimumSize: const Size(0, 36),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String label, Color color, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(String lastSeen) {
    if (lastSeen.isEmpty) return 'Never';
    try {
      final dateTime = DateTime.parse(lastSeen);
      final difference = DateTime.now().difference(dateTime);
      if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatTimeAgo(String dateStr) {
    if (dateStr.isEmpty) return 'Unknown';
    try {
      final dateTime = DateTime.parse(dateStr);
      final difference = DateTime.now().difference(dateTime);
      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'Unknown';
    try {
      final dateTime = DateTime.parse(dateStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showAddClientDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Desktop Client'),
        content: Text(
          'Desktop clients automatically register when they start up and connect to the system.',
          style: GoogleFonts.plusJakartaSans(color: _textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showClientDetails(BuildContext context, Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Client Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Name', client['client_name'] ?? 'Unknown'),
              _detailRow('ID', client['client_id'] ?? 'Unknown'),
              _detailRow('Platform', client['platform'] ?? 'Unknown'),
              _detailRow('Version', client['version'] ?? 'Unknown'),
              _detailRow('IP Address', client['ip_address'] ?? 'Unknown'),
              _detailRow('Status', client['status'] ?? 'Unknown'),
              _detailRow('Last Seen', _formatLastSeen(client['last_seen'] ?? '')),
              _detailRow('Created', _formatDate(client['created_at'] ?? '')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClient(BuildContext context, Map<String, dynamic> client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client?'),
        content: Text(
          'Client: ${client['client_name'] ?? client['client_id']}\nThis cannot be undone.',
          style: GoogleFonts.plusJakartaSans(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFFDC2626))),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await SupabaseService.deleteDesktopClient(client['client_id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Client deleted' : 'Failed to delete'),
          backgroundColor: ok ? const Color(0xFF059669) : const Color(0xFFDC2626),
        ),
      );
      if (ok) await context.read<AppProvider>().refresh();
    }
  }

  void _showRemoteActions(BuildContext context, Map<String, dynamic> client, AppProvider appProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RemoteActionsSheet(
        client: client,
        appProvider: appProvider,
        onResult: (success, message) => _showResult(context, success, message),
        onShowExchangeRateDialog: (ctx) =>
            _showExchangeRateDialog(ctx, client, appProvider),
        onShowMvDatabaseDialog: (ctx) =>
            _showMvDatabaseDialog(ctx, client, appProvider),
      ),
    );
  }

  void _showResult(BuildContext context, bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF059669) : const Color(0xFFDC2626),
      ),
    );
  }

  void _showExchangeRateDialog(
      BuildContext context, Map<String, dynamic> client, AppProvider appProvider) {
    final currentRate = appProvider.currentExchangeRate;
    final currentTaxRate = currentRate != null
        ? (currentRate['rate'] ?? currentRate['tax_rate'])
        : null;
    final currentPhase1Rate = currentRate?['phase1_rate'];

    final rateTaxController =
        TextEditingController(text: currentTaxRate?.toString() ?? '');
    final ratePhase1Controller =
        TextEditingController(text: currentPhase1Rate?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Exchange Rates'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rates will be saved as defaults and sent to the desktop client.',
                style: GoogleFonts.plusJakartaSans(color: _textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateTaxController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Tax Rate (USD → UGX)',
                  hintText: 'e.g., 3700',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ratePhase1Controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Phase 1 Rate (optional)',
                  hintText: 'Leave empty to use Tax Rate',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final rateTaxText = rateTaxController.text.trim();
              if (rateTaxText.isEmpty) return;
              final rateTax = double.tryParse(rateTaxText);
              if (rateTax == null || rateTax <= 0) return;

              double? ratePhase1;
              final phase1Text = ratePhase1Controller.text.trim();
              if (phase1Text.isNotEmpty) {
                ratePhase1 = double.tryParse(phase1Text);
              }

              Navigator.pop(context);

              BuildContext? loadingCtx;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  loadingCtx = ctx;
                  return AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Updating exchange rates...',
                            style: GoogleFonts.plusJakartaSans()),
                      ],
                    ),
                  );
                },
              );

              try {
                final updateSuccess = await SupabaseService.updateExchangeRate(
                  rate: rateTax,
                  source: 'Admin Update',
                  phase1Rate: ratePhase1,
                ).timeout(const Duration(seconds: 10), onTimeout: () => false);

                if (loadingCtx != null && Navigator.canPop(loadingCtx!)) {
                  Navigator.pop(loadingCtx!);
                }

                if (!updateSuccess) {
                  if (context.mounted) {
                    _showResult(context, false, 'Failed to update exchange rates');
                  }
                  return;
                }

                try {
                  await appProvider.refreshExchangeRate();
                } catch (_) {}

                bool commandSuccess = false;
                try {
                  final params = <String, dynamic>{'rate': rateTax, 'tax_rate': rateTax};
                  if (ratePhase1 != null) params['phase1_rate'] = ratePhase1;
                  commandSuccess = await appProvider.sendRemoteCommand(
                    clientId: client['client_id'],
                    command: 'update_exchange_rate',
                    parameters: params,
                  ).timeout(const Duration(seconds: 10), onTimeout: () => false);
                } catch (_) {}

                if (context.mounted) {
                  _showResult(
                    context,
                    true,
                    commandSuccess
                        ? 'Exchange rates updated and sent to client!'
                        : 'Exchange rates saved. Client will sync on next connection.',
                  );
                }
              } catch (e) {
                if (loadingCtx != null && Navigator.canPop(loadingCtx!)) {
                  Navigator.pop(loadingCtx!);
                }
                if (context.mounted) {
                  _showResult(context, false, 'Error: $e');
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMvDatabaseDialog(
      BuildContext context, Map<String, dynamic> client, AppProvider appProvider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading database updates...', style: GoogleFonts.plusJakartaSans()),
          ],
        ),
      ),
    );

    try {
      await appProvider.refreshUraUpdates();
      await Future.delayed(const Duration(milliseconds: 200));
      final updates = appProvider.uraUpdates;

      if (context.mounted) Navigator.pop(context);

      if (updates.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No MV database updates available.')),
        );
        return;
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select MV Database Update'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Consumer<AppProvider>(
              builder: (context, provider, _) {
                final currentUpdates = provider.uraUpdates;
                if (currentUpdates.isEmpty) {
                  return Center(
                    child: Text('No updates available',
                        style: GoogleFonts.plusJakartaSans(color: _textSecondary)),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: currentUpdates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final update = currentUpdates[index];
                    final month = update['month'] ?? 'Unknown';
                    final fileName = update['file_name'] ?? 'Unknown';
                    final status = update['status'] ?? 'pending';
                    final fileUrl = update['file_url'] ?? '';

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.storage_rounded,
                            color: Color(0xFF7C3AED), size: 20),
                      ),
                      title: Text(month,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(fileName,
                          style: GoogleFonts.plusJakartaSans(
                              color: _textSecondary, fontSize: 12)),
                      trailing: status == 'completed'
                          ? const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF059669))
                          : const Icon(Icons.pending_rounded,
                              color: Color(0xFFD97706)),
                      onTap: () async {
                        Navigator.pop(context);
                        if (fileUrl.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('No file URL for this update')),
                          );
                          return;
                        }
                        final success = await appProvider.sendRemoteCommand(
                          clientId: client['client_id'],
                          command: 'update_mv_database',
                          parameters: {
                            'file_url': fileUrl,
                            'month': month,
                            'record_count': update['record_count'] ?? 0,
                          },
                        );
                        if (context.mounted) {
                          _showResult(
                            context,
                            success,
                            success
                                ? 'MV database update sent ($month)'
                                : 'Failed to send command',
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading updates: $e')),
      );
    }
  }

  void _showClientActivities(BuildContext context, Map<String, dynamic> client) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ClientActivitiesSheet(
        clientId: (client['client_id'] ?? '').toString(),
        clientName: (client['client_name'] ?? 'Client').toString(),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Remote actions bottom sheet
// ────────────────────────────────────────────────────────────────────────────

class _RemoteActionsSheet extends StatelessWidget {
  final Map<String, dynamic> client;
  final AppProvider appProvider;
  final void Function(bool, String) onResult;
  final void Function(BuildContext) onShowExchangeRateDialog;
  final void Function(BuildContext) onShowMvDatabaseDialog;

  const _RemoteActionsSheet({
    required this.client,
    required this.appProvider,
    required this.onResult,
    required this.onShowExchangeRateDialog,
    required this.onShowMvDatabaseDialog,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Remote Actions',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              client['client_name'] ?? '',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            _actionTile(
              context,
              icon: Icons.refresh_rounded,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              title: 'Restart Application',
              subtitle: 'Restart the desktop application',
              onTap: () async {
                Navigator.pop(context);
                final success = await appProvider.sendRemoteCommand(
                  clientId: client['client_id'],
                  command: 'restart_application',
                );
                onResult(success, 'Application restart command sent');
              },
            ),
            _actionTile(
              context,
              icon: Icons.storage_rounded,
              color: const Color(0xFF3B82F6),
              bgColor: const Color(0xFFEFF6FF),
              title: 'Refresh Database',
              subtitle: 'Force database refresh',
              onTap: () async {
                Navigator.pop(context);
                final success = await appProvider.sendRemoteCommand(
                  clientId: client['client_id'],
                  command: 'refresh_database',
                );
                onResult(success, 'Database refresh command sent');
              },
            ),
            _actionTile(
              context,
              icon: Icons.currency_exchange_rounded,
              color: const Color(0xFF059669),
              bgColor: const Color(0xFFECFDF5),
              title: 'Update Exchange Rate',
              subtitle: 'Set a new exchange rate',
              onTap: () {
                Navigator.pop(context);
                onShowExchangeRateDialog(context);
              },
            ),
            _actionTile(
              context,
              icon: Icons.cloud_download_rounded,
              color: const Color(0xFF7C3AED),
              bgColor: const Color(0xFFF5F3FF),
              title: 'Update MV Database',
              subtitle: 'Push used MV database to client',
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (context.mounted) onShowMvDatabaseDialog(context);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: const Color(0xFF6B7280)),
      ),
      onTap: onTap,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Client activities bottom sheet
// ────────────────────────────────────────────────────────────────────────────

class _ClientActivitiesSheet extends StatefulWidget {
  final String clientId;
  final String clientName;

  const _ClientActivitiesSheet({
    required this.clientId,
    required this.clientName,
  });

  @override
  State<_ClientActivitiesSheet> createState() => _ClientActivitiesSheetState();
}

class _ClientActivitiesSheetState extends State<_ClientActivitiesSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _activities = [];
  String _selectedFilter = '24h';
  Duration _timeFilter = const Duration(hours: 24);

  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _loading = true);
    try {
      List<Map<String, dynamic>> activities;
      if (_selectedFilter == 'all') {
        activities = await SupabaseService.getRemoteCommands(widget.clientId, limit: 100);
      } else {
        activities = await SupabaseService.getRecentActivities(
          widget.clientId,
          timeFilter: _timeFilter,
        );
      }
      setState(() {
        _activities = activities;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case '24h': _timeFilter = const Duration(hours: 24); break;
        case '7d': _timeFilter = const Duration(days: 7); break;
        case '30d': _timeFilter = const Duration(days: 30); break;
      }
    });
    _loadActivities();
  }

  String _formatTimeAgo(String dateStr) {
    if (dateStr.isEmpty) return 'Unknown';
    try {
      final dateTime = DateTime.parse(dateStr);
      final difference = DateTime.now().difference(dateTime);
      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  IconData _getCommandIcon(String command) {
    final cmd = command.toLowerCase();
    if (cmd.contains('restart') || cmd.contains('refresh')) return Icons.refresh_rounded;
    if (cmd.contains('database') || cmd.contains('db')) return Icons.storage_rounded;
    if (cmd.contains('exchange') || cmd.contains('rate')) return Icons.currency_exchange_rounded;
    if (cmd.contains('download') || cmd.contains('update')) return Icons.cloud_download_rounded;
    if (cmd.contains('invoice')) return Icons.receipt_rounded;
    if (cmd.contains('customer') || cmd.contains('client')) return Icons.person_rounded;
    if (cmd.contains('vehicle')) return Icons.directions_car_rounded;
    if (cmd.contains('login')) return Icons.login_rounded;
    return Icons.settings_rounded;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': case 'success': return const Color(0xFF059669);
      case 'pending': return const Color(0xFFD97706);
      case 'failed': case 'error': return const Color(0xFFDC2626);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activities',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary),
                      ),
                      Text(
                        widget.clientName,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('24h', 'Last 24h'),
                const SizedBox(width: 8),
                _filterChip('7d', 'Last 7d'),
                const SizedBox(width: 8),
                _filterChip('30d', 'Last 30d'),
                const SizedBox(width: 8),
                _filterChip('all', 'All'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: _loadActivities,
                  color: _textSecondary,
                ),
              ],
            ),
          ),
          const Divider(),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _activities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No activities found',
                                style: GoogleFonts.plusJakartaSans(color: _textSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _activities.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final activity = _activities[index];
                          final action =
                              activity['action'] ?? activity['command'] ?? 'Unknown';
                          final status = activity['status'] ?? 'unknown';
                          final createdAt = activity['created_at'] ?? '';
                          final username = activity['username'];
                          final isRemote = activity['type'] == 'remote_command';

                          final statusColor = _getStatusColor(status);
                          String actionTitle = action
                              .toString()
                              .replaceAll('_', ' ')
                              .split(' ')
                              .map((w) => w.isEmpty
                                  ? w
                                  : w[0].toUpperCase() + w.substring(1).toLowerCase())
                              .join(' ');

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_getCommandIcon(action),
                                  color: statusColor, size: 20),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  isRemote ? '📱 ' : '🖥️ ',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Expanded(
                                  child: Text(
                                    actionTitle,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                        color: _textPrimary),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      status.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor),
                                    ),
                                    if (username != null) ...[
                                      Text(' • ',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11, color: _textSecondary)),
                                      Text(username.toString(),
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11, color: _textSecondary)),
                                    ],
                                  ],
                                ),
                                Text(
                                  _formatTimeAgo(createdAt),
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => _changeFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? LeonColors.accent : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : _textSecondary,
          ),
        ),
      ),
    );
  }
}
