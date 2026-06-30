import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/leon_theme.dart';
import '../widgets/leon/leon_bezel_card.dart';
import '../widgets/leon/leon_section_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _refreshTimer;

  static const _ink = LeonColors.ink;
  static const _secondary = LeonColors.secondary;
  static const _muted = LeonColors.muted;
  static const _canvas = LeonColors.canvas;
  static const _accent = LeonColors.accent;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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
      backgroundColor: _canvas,
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading && appProvider.systemStats == null) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          return RefreshIndicator(
            onRefresh: () => appProvider.refresh(),
            color: _accent,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(appProvider),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 24),
                      _buildBentoGrid(appProvider),
                      const SizedBox(height: 28),
                      _buildSectionHeader('Quick Actions'),
                      const SizedBox(height: 12),
                      _buildQuickActions(context),
                      const SizedBox(height: 28),
                      _buildSectionHeader('Recent Activity'),
                      const SizedBox(height: 12),
                      _buildRecentActivity(appProvider),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(AppProvider appProvider) {
    final stats = appProvider.systemStats ?? {};
    final activeClients = stats['active_clients'] ?? 0;
    final exchangeRate = (stats['current_exchange_rate'] ?? 3700.0);

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final fraction = (constraints.maxHeight - kToolbarHeight) /
              (200 - kToolbarHeight);
          final isExpanded = fraction > 0.5;

          return FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: leonHeroGradient,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 50,
                    bottom: -40,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'NSB Motors',
                            style: LeonTypography.sectionLabel(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Management Dashboard',
                            style: LeonTypography.heading(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _heroStat('$activeClients', 'Active\nClients'),
                              const SizedBox(width: 32),
                              _heroStat(
                                  'UGX ${(exchangeRate as num).toStringAsFixed(0)}',
                                  'Per\nUSD'),
                              const SizedBox(width: 32),
                              _heroStat('Online', 'System\nStatus'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () => context.read<AppProvider>().refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: LeonTypography.num(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: LeonTypography.sans(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return LeonSectionHeader(title, color: _muted);
  }

  Widget _buildBentoGrid(AppProvider appProvider) {
    final stats = appProvider.systemStats ?? {};
    final activeClients = stats['active_clients'] ?? 0;
    final exchangeRate = (stats['current_exchange_rate'] ?? 3700.0);
    final lastUpdateRaw = '${stats['last_database_update'] ?? 'Never'}';
    final lastUpdateDisplay = lastUpdateRaw.contains(' ')
        ? lastUpdateRaw.split(' ').first
        : lastUpdateRaw;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _bentoCard(
                title: 'Active Clients',
                value: '$activeClients',
                icon: Icons.computer_rounded,
                accent: LeonColors.accent,
                accentBg: LeonColors.accentLight,
                tall: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _bentoCard(
                    title: 'DB Status',
                    value: 'Online',
                    icon: Icons.cloud_done_rounded,
                    accent: LeonColors.success,
                    accentBg: LeonColors.successBg,
                    tall: false,
                  ),
                  const SizedBox(height: 12),
                  _bentoCard(
                    title: 'Last Update',
                    value: lastUpdateDisplay,
                    icon: Icons.update_rounded,
                    accent: const Color(0xFF7C3AED),
                    accentBg: const Color(0xFFF5F3FF),
                    tall: false,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _bentoCardWide(
          title: 'Exchange Rate',
          value: 'UGX ${(exchangeRate as num).toStringAsFixed(0)}',
          subtitle: 'per US Dollar',
          icon: Icons.currency_exchange_rounded,
          accent: const Color(0xFFD97706),
          accentBg: const Color(0xFFFFFBEB),
        ),
      ],
    );
  }

  Widget _bentoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    required Color accentBg,
    required bool tall,
  }) {
    return LeonBezelCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
      height: tall ? 160 : 82,
      child: Padding(
      padding: const EdgeInsets.all(16),
      child: tall
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: LeonTypography.num(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    Text(
                      title,
                      style: LeonTypography.sans(
                        fontSize: 12,
                        color: _secondary,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: LeonTypography.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        title,
                        style: LeonTypography.sans(
                          fontSize: 10,
                          color: _secondary,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
      ),
      ),
    );
  }

  Widget _bentoCardWide({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Color accentBg,
  }) {
    return LeonBezelCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: LeonTypography.num(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$title  •  $subtitle',
                  style: LeonTypography.sans(
                    fontSize: 12,
                    color: _secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'LIVE',
              style: LeonTypography.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accent,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickActionCard(
            'Update Database',
            'Upload URA data',
            Icons.cloud_upload_rounded,
            const Color(0xFF059669),
            const Color(0xFFECFDF5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickActionCard(
            'Manage Clients',
            'View desktop clients',
            Icons.computer_rounded,
            LeonColors.accent,
            LeonColors.accentLight,
          ),
        ),
      ],
    );
  }

  Widget _quickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color accent,
    Color accentBg,
  ) {
    return LeonBezelCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: LeonTypography.sans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: LeonTypography.sans(
              fontSize: 11,
              color: _secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(AppProvider appProvider) {
    final clients = appProvider.desktopClients;
    final stats = appProvider.systemStats ?? {};

    String? mostRecentClientTime;
    String? mostRecentClientName;
    if (clients.isNotEmpty) {
      final latestClient = clients.first;
      mostRecentClientName = latestClient['client_name'] ?? 'Unknown';
      final lastSeen = latestClient['last_seen'] ?? '';
      if (lastSeen.isNotEmpty) mostRecentClientTime = _formatTimeAgo(lastSeen);
    }

    final exchangeRate = stats['current_exchange_rate'] ?? 3700.0;
    final exchangeRateDate = stats['exchange_rate_date'];
    String? exchangeRateTime;
    if (exchangeRateDate != null) {
      exchangeRateTime = _formatTimeAgo(exchangeRateDate.toString());
    }

    final lastDbUpdate = stats['last_database_update'];
    final lastDbUpdateDate = stats['last_update_date'];
    String? dbUpdateTime;
    if (lastDbUpdateDate != null && lastDbUpdate != 'Never') {
      dbUpdateTime = _formatTimeAgo(lastDbUpdateDate.toString());
    }

    final List<_ActivityItem> items = [];

    if (mostRecentClientTime != null && mostRecentClientName != null) {
      items.add(_ActivityItem(
        icon: Icons.computer_rounded,
        title: 'Desktop Client Active',
        subtitle: '$mostRecentClientName is online',
        time: mostRecentClientTime,
        color: const Color(0xFF059669),
        accentBg: const Color(0xFFECFDF5),
      ));
    }

    if (exchangeRateTime != null) {
      items.add(_ActivityItem(
        icon: Icons.currency_exchange_rounded,
        title: 'Exchange Rate Updated',
        subtitle: 'USD to UGX: ${(exchangeRate as num).toStringAsFixed(0)}',
        time: exchangeRateTime,
        color: const Color(0xFFD97706),
        accentBg: const Color(0xFFFFFBEB),
      ));
    }

    if (dbUpdateTime != null && lastDbUpdate != 'Never') {
      items.add(_ActivityItem(
        icon: Icons.storage_rounded,
        title: 'URA Database',
        subtitle: '$lastDbUpdate database',
        time: dbUpdateTime,
        color: const Color(0xFF7C3AED),
        accentBg: const Color(0xFFF5F3FF),
      ));
    }

    if (items.isEmpty) {
      return LeonBezelCard(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: LeonColors.accentLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.history_rounded,
                    size: 26, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 14),
              Text(
                'No recent activity',
                style: LeonTypography.sans(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _ink),
              ),
              const SizedBox(height: 4),
              Text(
                'Activity will show up here',
                style: LeonTypography.sans(
                    fontSize: 12, color: _secondary),
              ),
            ],
          ),
        ),
      );
    }

    return LeonBezelCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildActivityRow(items[i]),
            if (i < items.length - 1)
              const Divider(height: 1, color: LeonColors.border, indent: 68),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityRow(_ActivityItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.accentBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: LeonTypography.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.subtitle,
                  style: LeonTypography.sans(
                      fontSize: 12, color: _secondary),
                ),
              ],
            ),
          ),
          Text(
            item.time,
            style: LeonTypography.mono(
                fontSize: 11, color: _muted),
          ),
        ],
      ),
    );
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
}

class _ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
  final Color accentBg;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
    required this.accentBg,
  });
}
