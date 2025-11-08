import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../services/supabase_service.dart';

class DatabaseManagementScreen extends StatefulWidget {
  const DatabaseManagementScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseManagementScreen> createState() => _DatabaseManagementScreenState();
}

class _DatabaseManagementScreenState extends State<DatabaseManagementScreen> {
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-select current month/year for database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setDefaultMonth();
    });
  }

  void _setDefaultMonth() {
    if (_monthController.text.isEmpty) {
      final now = DateTime.now();
      final monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      setState(() {
        _monthController.text = '${monthNames[now.month - 1]} ${now.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Database Management',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              context.read<AppProvider>().refresh();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExchangeRateSection(context, appProvider),
                const SizedBox(height: 24),
                _buildUraDatabaseSection(context, appProvider),
                const SizedBox(height: 24),
                _buildRecentUpdates(appProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExchangeRateSection(BuildContext context, AppProvider appProvider) {
    final currentRate = appProvider.currentExchangeRate;
    final rate = currentRate?['rate'] ?? 3700.0;
    final source = currentRate?['source'] ?? 'Unknown';
    final date = currentRate?['effective_date'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_exchange, color: Color(0xFFFF9800), size: 28),
              const SizedBox(width: 12),
              Text(
                'Exchange Rate',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Rate',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'UGX ${rate.toStringAsFixed(0)} per USD',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Source: $source • Updated: ${_formatDate(date)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
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
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'New Exchange Rate',
                    hintText: '3700',
                    labelStyle: GoogleFonts.poppins(color: Colors.white70),
                    hintStyle: GoogleFonts.poppins(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF0A0E21),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFFF9800)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: appProvider.isLoading ? null : () => _updateExchangeRate(context, appProvider),
                icon: const Icon(Icons.update, size: 18),
                label: const Text('Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUraDatabaseSection(BuildContext context, AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage, color: Color(0xFF4CAF50), size: 28),
              const SizedBox(width: 12),
              Text(
                'URA Database Updates',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Upload new URA Used MV Database files to update all desktop clients.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              TextField(
                controller: _monthController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Database Month',
                  hintText: 'October 2025',
                  labelStyle: GoogleFonts.poppins(color: Colors.white70),
                  hintStyle: GoogleFonts.poppins(color: Colors.white30),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fileNameController,
                      readOnly: true,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'File Name',
                        hintText: 'Select PDF file...',
                        labelStyle: GoogleFonts.poppins(color: Colors.white70),
                        hintStyle: GoogleFonts.poppins(color: Colors.white30),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _pickFile(context),
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('Browse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: appProvider.isLoading ? null : () => _uploadDatabaseUpdate(context, appProvider),
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Upload Database Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUpdates(AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Updates',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: appProvider.uraUpdates.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.storage_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No database updates yet',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appProvider.uraUpdates.length,
                  itemBuilder: (context, index) {
                    final update = appProvider.uraUpdates[index];
                    return _buildUpdateItem(update);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUpdateItem(Map<String, dynamic> update) {
    final status = update['status'] ?? 'pending';
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'processing':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update['month'] ?? 'Unknown Month',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${update['file_name'] ?? 'Unknown'} • ${update['record_count'] ?? 0} records',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(update['created_at'] ?? ''),
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white54,
            ),
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

  Future<void> _updateExchangeRate(BuildContext context, AppProvider appProvider) async {
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

  String? _selectedFilePath;

  Future<void> _pickFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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

  Future<void> _uploadDatabaseUpdate(BuildContext context, AppProvider appProvider) async {
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

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Uploading database file...',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      print('🚀 Starting database update upload process...');
      print('   Month: $month');
      print('   File: $fileName');
      
      // Upload file to Supabase Storage
      final file = await SupabaseService.uploadDatabaseFile(_selectedFilePath!, fileName);
      
      if (file != null) {
        print('📝 Creating database update record...');
        final success = await appProvider.createUraDatabaseUpdate(
          month: month,
          fileName: fileName,
          recordCount: 0, // Record count will be determined when PDF is processed
          fileUrl: file,
        );

        if (success) {
          print('🎉 Database update upload completed successfully!');
          
          // Reset form
          _monthController.text = ''; // Will be auto-filled in initState
          final now = DateTime.now();
          final monthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
          ];
          _monthController.text = '${monthNames[now.month - 1]} ${now.year}';
          _fileNameController.clear();
          _selectedFilePath = null;
          
          Navigator.pop(context); // Close loading dialog
          _showSuccess(context, 'Database update uploaded successfully');
        } else {
          print('❌ Failed to create database update record');
          Navigator.pop(context); // Close loading dialog
          _showError(context, 'Failed to create database update');
        }
      } else {
        print('❌ File upload returned null URL');
        Navigator.pop(context); // Close loading dialog
        _showError(context, 'Failed to upload file');
      }
    } catch (e) {
      print('❌ Error during upload: $e');
      Navigator.pop(context); // Close loading dialog
      _showError(context, 'Error: $e');
    }
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _monthController.dispose();
    _fileNameController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }
}

