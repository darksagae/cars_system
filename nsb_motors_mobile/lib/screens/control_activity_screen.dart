import 'package:flutter/material.dart';
import '../services/cloud_control_service.dart';
import '../theme/leon_theme.dart';
import '../widgets/leon/leon_bezel_card.dart';
import '../widgets/leon/leon_section_header.dart';

class ControlActivityScreen extends StatefulWidget {
  const ControlActivityScreen({super.key});

  @override
  State<ControlActivityScreen> createState() => _ControlActivityScreenState();
}

class _ControlActivityScreenState extends State<ControlActivityScreen> {
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
      setState(() => _loading = false);
    }
  }

  String _formatWhen(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LeonColors.canvas,
      appBar: AppBar(
        title: Text('Activity', style: LeonTypography.heading(fontSize: 18)),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? const ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  if (_error != null)
                    LeonBezelCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: LeonTypography.sans(color: const Color(0xFFDC2626))),
                    ),
                  const LeonSectionHeader('Recent events'),
                  const SizedBox(height: 12),
                  if (_items.isEmpty && !_loading)
                    LeonBezelCard(
                      child: Text('No activity yet', style: LeonTypography.sans(color: LeonColors.secondary)),
                    ),
                  ..._items.map((item) {
                    final user = item['user'] as Map<String, dynamic>?;
                    final action = item['action']?.toString().replaceAll('_', ' ') ?? '';
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
                                    action,
                                    style: LeonTypography.sans(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?['username']?.toString() ?? 'Unknown',
                                    style: LeonTypography.mono(fontSize: 11, color: LeonColors.secondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatWhen(item['createdAt']?.toString()),
                              style: LeonTypography.mono(fontSize: 10, color: LeonColors.muted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
