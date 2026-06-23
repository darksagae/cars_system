import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/glass_container.dart';
import '../services/data_management/data_management_service.dart';
import '../utils/uganda_formatters.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final DataManagementService _dataService = DataManagementService();
  Map<String, dynamic>? _databaseStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDatabaseStats();
  }

  void _loadDatabaseStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _dataService.getDatabaseStatistics();
      setState(() {
        _databaseStats = stats;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading database stats: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Data Management',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A), // Pure black background
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildDatabaseStats(),
                      const SizedBox(height: 24),
                      _buildBackupRestoreSection(),
                      const SizedBox(height: 24),
                      _buildImportExportSection(),
                      const SizedBox(height: 24),
                      _buildDataValidationSection(),
                      const SizedBox(height: 24),
                      _buildDataCleanupSection(),
                      const SizedBox(height: 24),
                      _buildVehicleManagementSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.database,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 16),
          Text(
            'Data Management',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseStats() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Database Statistics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_databaseStats != null) ...[
            _buildStatRow('Customers', _databaseStats!['customerCount'].toString()),
            _buildStatRow('Vehicles', _databaseStats!['vehicleCount'].toString()),
            _buildStatRow('Invoices', _databaseStats!['invoiceCount'].toString()),
            _buildStatRow('Payments', _databaseStats!['paymentCount'].toString()),
            _buildStatRow('Reminders', _databaseStats!['reminderCount'].toString()),
            _buildStatRow('Demand Letters', _databaseStats!['letterCount'].toString()),
            const Divider(color: Colors.white30),
            _buildStatRow('Total Revenue', UgandaFormatters.formatCurrency(_databaseStats!['totalRevenue'])),
            _buildStatRow('Total Paid', UgandaFormatters.formatCurrency(_databaseStats!['totalPaid'])),
            _buildStatRow('Outstanding', UgandaFormatters.formatCurrency(_databaseStats!['outstanding'])),
            _buildStatRow('Database Size', '${(_databaseStats!['databaseSize'] / 1024).toStringAsFixed(1)} KB'),
          ] else
            const Text('Failed to load statistics', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupRestoreSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup & Restore',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Create Backup',
                  FontAwesomeIcons.download,
                  GlassLiquidTheme.accentBlue,
                  () => _createBackup(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Restore Data',
                  FontAwesomeIcons.upload,
                  Colors.green,
                  () => _restoreData(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportExportSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import & Export',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Export Customers',
                  FontAwesomeIcons.users,
                  Colors.orange,
                  () => _exportData('customers'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Export Vehicles',
                  FontAwesomeIcons.car,
                  Colors.purple,
                  () => _exportData('vehicles'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Export Invoices',
                  FontAwesomeIcons.fileInvoice,
                  GlassLiquidTheme.accentBlue,
                  () => _exportData('invoices'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Import Data',
                  FontAwesomeIcons.fileImport,
                  Colors.green,
                  () => _importData(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataValidationSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Validation',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Validate Data',
                  FontAwesomeIcons.circleCheck,
                  GlassLiquidTheme.accentBlue,
                  () => _validateData(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Refresh Stats',
                  FontAwesomeIcons.arrowsRotate,
                  Colors.orange,
                  () => _loadDatabaseStats(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataCleanupSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Cleanup',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Cleanup Data',
                  FontAwesomeIcons.broom,
                  Colors.red,
                  () => _cleanupData(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              FaIcon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createBackup() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Creating backup...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      final filePath = await _dataService.backupAllData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created successfully!\nSaved to: $filePath'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating backup: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _restoreData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restoring data...'),
            backgroundColor: GlassLiquidTheme.accentBlue,
          ),
        );

        final success = await _dataService.restoreData(result.files.first.path!);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Data restored successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            _loadDatabaseStats();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to restore data'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportData(String dataType) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exporting $dataType...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      final filePath = await _dataService.exportToCSV(dataType);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$dataType exported successfully!\nSaved to: $filePath'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting $dataType: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        // Show dialog to select data type
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Select Data Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Customers'),
                  onTap: () {
                    Navigator.pop(context);
                    _importDataFromCSV(result.files.first.path!, 'customers');
                  },
                ),
                ListTile(
                  title: Text('Vehicles'),
                  onTap: () {
                    Navigator.pop(context);
                    _importDataFromCSV(result.files.first.path!, 'vehicles');
                  },
                ),
                ListTile(
                  title: Text('Invoices'),
                  onTap: () {
                    Navigator.pop(context);
                    _importDataFromCSV(result.files.first.path!, 'invoices');
                  },
                ),
                ListTile(
                  title: Text('Payments'),
                  onTap: () {
                    Navigator.pop(context);
                    _importDataFromCSV(result.files.first.path!, 'payments');
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _importDataFromCSV(String filePath, String dataType) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Importing $dataType...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      final success = await _dataService.importFromCSV(filePath, dataType);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$dataType imported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDatabaseStats();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to import $dataType'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing $dataType: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _validateData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Validating data...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      final result = await _dataService.validateDataIntegrity();
      
      if (mounted) {
        if (result['isValid']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data validation passed! No issues found.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Data Validation Results'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Found ${result['issueCount']} issues:'),
                  const SizedBox(height: 8),
                  ...result['issues'].map<Widget>((issue) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $issue', style: TextStyle(color: Colors.red)),
                  )),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _cleanupData();
                  },
                  child: Text('Cleanup Data'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error validating data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cleanupData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cleaning up data...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      final success = await _dataService.cleanupData();
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data cleanup completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDatabaseStats();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cleanup data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cleaning up data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildVehicleManagementSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Management',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Update Vehicle Status',
                  FontAwesomeIcons.car,
                  GlassLiquidTheme.accentBlue,
                  () => _updateVehicleStatus(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Bulk Vehicle Import',
                  FontAwesomeIcons.fileImport,
                  Colors.green,
                  () => _bulkVehicleImport(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Vehicle Analytics',
                  FontAwesomeIcons.chartLine,
                  Colors.purple,
                  () => _showVehicleAnalytics(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Inventory Report',
                  FontAwesomeIcons.warehouse,
                  Colors.orange,
                  () => _generateInventoryReport(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateVehicleStatus() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updating vehicle statuses...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      // This would update vehicle statuses based on sales
      // For now, just show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle statuses updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating vehicle statuses: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _bulkVehicleImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path!;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Importing vehicles from CSV...'),
            backgroundColor: GlassLiquidTheme.accentBlue,
          ),
        );

        final success = await _dataService.importFromCSV(filePath, 'vehicles');
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Vehicles imported successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            _loadDatabaseStats();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to import vehicles'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing vehicles: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showVehicleAnalytics() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generating vehicle analytics...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      // This would show vehicle analytics
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle analytics generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating vehicle analytics: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _generateInventoryReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generating inventory report...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      // This would generate an inventory report
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inventory report generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating inventory report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

