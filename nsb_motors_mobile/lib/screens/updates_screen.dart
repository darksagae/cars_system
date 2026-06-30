import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/cloud_control_service.dart';
import '../theme/leon_theme.dart';
import '../widgets/leon/leon_bezel_card.dart';
import '../widgets/leon/leon_section_header.dart';
import '../widgets/leon/leon_brand_header.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final _cloud = CloudControlService();

  Map<String, dynamic>? _mv;
  Map<String, dynamic>? _rates;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _progress;

  final _taxCtrl = TextEditingController();
  final _cnfCtrl = TextEditingController();
  String _selectedMonth = _defaultMonth();

  static String _defaultMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _taxCtrl.dispose();
    _cnfCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _cloud.fetchUpdates();
      final mv = data['mvDatabase'] as Map<String, dynamic>?;
      final rates = data['exchangeRates'] as Map<String, dynamic>?;
      setState(() {
        _mv = mv;
        _rates = rates;
        if (rates != null) {
          _taxCtrl.text = '${rates['taxRate'] ?? ''}';
          _cnfCtrl.text = '${rates['cnfRate'] ?? ''}';
        }
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadMv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read PDF file')),
        );
      }
      return;
    }

    setState(() {
      _busy = true;
      _progress = 'Starting…';
    });
    try {
      final importResult = await _cloud.uploadMvDatabase(
        pdfBytes: bytes,
        filename: file.name,
        month: _selectedMonth,
        onProgress: (msg) {
          if (mounted) setState(() => _progress = msg);
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${importResult['imported'] ?? 0} rows for $_selectedMonth. '
              'Database locked and pushed to machines.',
            ),
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
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _unlockMv() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlock MV database?'),
        content: const Text('Allows uploading a new monthly URA MV database PDF.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unlock')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await _cloud.unlockMvDatabase();
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

  Future<void> _saveRates() async {
    final tax = double.tryParse(_taxCtrl.text.trim());
    final cnf = double.tryParse(_cnfCtrl.text.trim());
    if (tax == null || tax <= 0 || cnf == null || cnf <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid exchange rates')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await _cloud.updateExchangeRates(taxRate: tax, cnfRate: cnf);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rates updated. Tax rate locked on all machines. '
              'C&F rate is a default — users can still change it locally.',
            ),
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
    final locked = _mv?['locked'] == true;

    return Scaffold(
      backgroundColor: LeonColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: const LeonBrandHeader(
                  title: 'Updates',
                  subtitle: 'Monthly MV database and exchange rates for all sales machines',
                ),
              ),
              if (_loading && _mv == null)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_error != null && _mv == null)
                SliverFillRemaining(
                  child: Center(child: Text(_error!, textAlign: TextAlign.center)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_error!, style: LeonTypography.sans(color: Colors.red, fontSize: 12)),
                        ),
                      _mvSection(locked),
                      const SizedBox(height: 16),
                      _ratesSection(),
                      if (_busy && _progress != null) ...[
                        const SizedBox(height: 16),
                        Text(_progress!, style: LeonTypography.mono(fontSize: 11, color: LeonColors.secondary)),
                      ],
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mvSection(bool locked) {
    return LeonBezelCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('URA MV Database', style: LeonTypography.sans(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (locked ? LeonColors.success : LeonColors.warning).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  locked ? 'LOCKED' : 'OPEN',
                  style: LeonTypography.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: locked ? LeonColors.success : LeonColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Month: ${_mv?['month'] ?? '—'} · ${_mv?['rowCount'] ?? 0} rates · Imported ${_formatWhen(_mv?['importedAt'])}',
            style: LeonTypography.sans(fontSize: 12, color: LeonColors.secondary),
          ),
          const SizedBox(height: 14),
          if (locked) ...[
            Text(
              'Database is locked after import. Unlock only when a new monthly PDF is ready.',
              style: LeonTypography.sans(fontSize: 12, color: LeonColors.secondary),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _busy ? null : _unlockMv,
              child: const Text('Unlock to replace'),
            ),
          ] else ...[
            const LeonSectionHeader('Database month (YYYY-MM)', color: LeonColors.secondary),
            const SizedBox(height: 6),
            InkWell(
              onTap: _busy
                  ? null
                  : () async {
                      final parts = _selectedMonth.split('-');
                      final initial = DateTime(
                        int.tryParse(parts.first) ?? DateTime.now().year,
                        int.tryParse(parts.length > 1 ? parts[1] : '1') ?? DateTime.now().month,
                      );
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedMonth =
                              '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
                        });
                      }
                    },
              child: InputDecorator(
                decoration: const InputDecoration(
                  isDense: true,
                  suffixIcon: Icon(Icons.calendar_month_outlined, size: 18),
                ),
                child: Text(_selectedMonth, style: LeonTypography.mono(fontSize: 14)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _pickAndUploadMv,
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: const Text('Upload monthly MV PDF'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uploads to cloud, imports tax rates, locks the database, and pushes to all sales machines.',
              style: LeonTypography.sans(fontSize: 11, color: LeonColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ratesSection() {
    final taxLocked = _rates?['taxRateLocked'] == true;

    return LeonBezelCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exchange rates', style: LeonTypography.sans(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Updated ${_formatWhen(_rates?['updatedAt'])}',
            style: LeonTypography.sans(fontSize: 12, color: LeonColors.secondary),
          ),
          const SizedBox(height: 14),
          const LeonSectionHeader('Tax calculation rate (UGX/USD) — locked on machines', color: LeonColors.secondary),
          const SizedBox(height: 6),
          TextField(
            controller: _taxCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              isDense: true,
              suffixIcon: Icon(
                taxLocked ? Icons.lock_outline : Icons.lock_open_outlined,
                size: 18,
                color: taxLocked ? LeonColors.warning : LeonColors.success,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const LeonSectionHeader('C&F rate (UGX/USD) — default, users can change', color: LeonColors.secondary),
          const SizedBox(height: 6),
          TextField(
            controller: _cnfCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: const InputDecoration(isDense: true),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _saveRates,
              child: const Text('Update rates on web & machines'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tax rate is locked on sales desktops after update. C&F rate syncs as a default but stays editable per invoice.',
            style: LeonTypography.sans(fontSize: 11, color: LeonColors.muted),
          ),
        ],
      ),
    );
  }
}
