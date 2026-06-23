import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../services/supabase_service.dart';

class DatabaseManagementScreen extends StatefulWidget {
  const DatabaseManagementScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseManagementScreen> createState() =>
      _DatabaseManagementScreenState();
}

class _DatabaseManagementScreenState extends State<DatabaseManagementScreen> {
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();
  String? _selectedFilePath;

  static const _canvas = Color(0xFFF8FAFC);
  static const _ink = Color(0xFF0F172A);
  static const _secondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _accent = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setDefaultMonth());
  }

  void _setDefaultMonth() {
    if (_monthController.text.isEmpty) {
      const monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      final now = DateTime.now();
      setState(
          () => _monthController.text = '${monthNames[now.month - 1]} ${now.year}');
    }
  }

  @override
  void dispose() {
    _monthController.dispose();
    _fileNameController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Database'),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
        actions: [
          IconButton(
            onPressed: () => context.read<AppProvider>().refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExchangeRateCard(context, appProvider),
                const SizedBox(height: 20),
                _buildUraUploadCard(context, appProvider),
                const SizedBox(height: 28),
                _buildSectionLabel('Recent Updates'),
                const SizedBox(height: 12),
                _buildRecentUpdates(appProvider),
              ],
            ),
          );
        },
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
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildExchangeRateCard(
      BuildContext context, AppProvider appProvider) {
    final currentRate = appProvider.currentExchangeRate;
    final rate = currentRate?['rate'] ?? 3700.0;
    final source = currentRate?['source'] ?? 'Unknown';
    final date = currentRate?['effective_date'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.currency_exchange_rounded,
                      color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exchange Rate',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                    Text('USD to UGX conversion',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: _secondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Rate',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: _secondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text(
                    'UGX ${(rate as num).toStringAsFixed(0)} / USD',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Source: $source  •  Updated: ${_formatDate(date)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: _secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _exchangeRateController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'New Rate (UGX)',
                      hintText: '3700',
                      prefixIcon: const Icon(Icons.edit_rounded, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: appProvider.isLoading
                      ? null
                      : () => _updateExchangeRate(context, appProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUraUploadCard(
      BuildContext context, AppProvider appProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.storage_rounded,
                      color: Color(0xFF059669), size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('URA Database',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                    Text('Upload new MV database files',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: _secondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _monthController,
              decoration: const InputDecoration(
                labelText: 'Database Month',
                hintText: 'October 2025',
                prefixIcon: Icon(Icons.calendar_month_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fileNameController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'PDF File',
                      hintText: 'Select file...',
                      prefixIcon:
                          const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      suffixIcon: _fileNameController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => setState(() {
                                _fileNameController.clear();
                                _selectedFilePath = null;
                              }),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _pickFile(context),
                  icon: const Icon(Icons.folder_open_rounded, size: 17),
                  label: const Text('Browse'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: appProvider.isLoading
                    ? null
                    : () => _uploadDatabaseUpdate(context, appProvider),
                icon: appProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 18),
                label: Text(
                    appProvider.isLoading ? 'Uploading...' : 'Upload Database'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUpdates(AppProvider appProvider) {
    if (appProvider.uraUpdates.isEmpty) {
      return Container(
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.inbox_rounded,
                    size: 26, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 14),
              Text('No updates yet',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _ink)),
              const SizedBox(height: 4),
              Text('Upload a database file to get started',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: _secondary)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < appProvider.uraUpdates.length; i++) ...[
            _buildUpdateRow(appProvider.uraUpdates[i]),
            if (i < appProvider.uraUpdates.length - 1)
              Divider(height: 1, color: _border, indent: 68),
          ],
        ],
      ),
    );
  }

  Widget _buildUpdateRow(Map<String, dynamic> update) {
    final status = update['status'] ?? 'pending';
    final Color accent;
    final Color accentBg;
    final IconData icon;

    switch (status) {
      case 'completed':
        accent = const Color(0xFF059669);
        accentBg = const Color(0xFFECFDF5);
        icon = Icons.check_circle_rounded;
        break;
      case 'processing':
        accent = const Color(0xFFD97706);
        accentBg = const Color(0xFFFFFBEB);
        icon = Icons.hourglass_top_rounded;
        break;
      default:
        accent = _accent;
        accentBg = const Color(0xFFEFF6FF);
        icon = Icons.pending_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update['month'] ?? 'Unknown Month',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink),
                ),
                Text(
                  '${update['file_name'] ?? 'Unknown'}  •  ${update['record_count'] ?? 0} records',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: _secondary),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(update['created_at'] ?? ''),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'Unknown';
    try {
      final dateTime = DateTime.parse(dateStr);
      return '${dateTime.day}/${dateTime.month}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _updateExchangeRate(
      BuildContext context, AppProvider appProvider) async {
    final rateText = _exchangeRateController.text.trim();
    if (rateText.isEmpty) {
      _showError(context, 'Please enter an exchange rate');
      return;
    }
    final rate = double.tryParse(rateText);
    if (rate == null || rate <= 0) {
      _showError(context, 'Please enter a valid exchange rate');
      return;
    }
    final success = await appProvider.updateExchangeRate(rate, 'Mobile App');
    if (success) {
      _exchangeRateController.clear();
      _showSuccess(context, 'Exchange rate updated successfully');
    } else {
      _showError(context, 'Failed to update exchange rate');
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _fileNameController.text = result.files.single.name;
        });
      }
    } catch (e) {
      _showError(context, 'Error picking file: $e');
    }
  }

  Future<void> _uploadDatabaseUpdate(
      BuildContext context, AppProvider appProvider) async {
    final month = _monthController.text.trim();
    final fileName = _fileNameController.text.trim();

    if (month.isEmpty || fileName.isEmpty) {
      _showError(context, 'Please fill in all fields and select a file');
      return;
    }
    if (_selectedFilePath == null) {
      _showError(context, 'Please select a PDF file');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Uploading database file...',
                style: GoogleFonts.plusJakartaSans()),
          ],
        ),
      ),
    );

    try {
      final file = await SupabaseService.uploadDatabaseFile(
          _selectedFilePath!, fileName);
      if (file != null) {
        final success = await appProvider.createUraDatabaseUpdate(
          month: month,
          fileName: fileName,
          recordCount: 0,
          fileUrl: file,
        );

        if (context.mounted) Navigator.pop(context);

        if (success) {
          _setDefaultMonth();
          setState(() {
            _fileNameController.clear();
            _selectedFilePath = null;
          });
          _showSuccess(context, 'Database update uploaded successfully');
        } else {
          _showError(context, 'Failed to create database update');
        }
      } else {
        if (context.mounted) Navigator.pop(context);
        _showError(context, 'Failed to upload file');
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      _showError(context, 'Error: $e');
    }
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }
}
