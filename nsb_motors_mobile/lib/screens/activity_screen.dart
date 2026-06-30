import 'package:flutter/material.dart';
import '../services/cloud_control_service.dart';
import '../theme/leon_theme.dart';
import '../widgets/leon/leon_bezel_card.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _cloud = CloudControlService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _cloud.fetchActivities();
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatWhen(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text('Activity', style: LeonTypography.heading(fontSize: 26)),
                ),
              ),
              if (_loading && _items.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_error != null && _items.isEmpty)
                SliverFillRemaining(
                  child: Center(child: Text(_error!, textAlign: TextAlign.center)),
                )
              else if (_items.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No activity yet')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _items[index];
                        final user = item['user'] as Map<String, dynamic>? ?? {};
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: LeonBezelCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item['action']}'.replaceAll('_', ' '),
                                        style: LeonTypography.sans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user['username']?.toString() ?? 'Unknown',
                                        style: LeonTypography.mono(
                                          fontSize: 11,
                                          color: LeonColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatWhen('${item['createdAt']}'),
                                  style: LeonTypography.mono(
                                    fontSize: 10,
                                    color: LeonColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _items.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
