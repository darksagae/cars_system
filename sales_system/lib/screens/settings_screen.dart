import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../database/database_helper.dart';
import '../widgets/glass_container.dart';
import 'email_config_screen.dart';
import 'pdf_management_screen.dart';
import 'data_management_screen.dart';
import 'performance_screen.dart';
import 'performance/performance_metrics_screen.dart';
import 'background/background_settings_screen.dart';
import '../widgets/glass_liquid_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A), // Pure black background
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
        child: Column(
              children: [
                Row(
          children: [
            Icon(
              Icons.settings,
                      size: 32,
                      color: Colors.white,
            ),
                    const SizedBox(width: 12),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSettingsCard(
                          context,
                          'Database Status',
                          'Check database connection and view status',
                          Icons.storage,
                          () async {
                            final dbHelper = DatabaseHelper();
                            try {
                              final db = await dbHelper.database;
                              final result = await db.rawQuery('SELECT COUNT(*) as count FROM ura_cif_database');
                              final count = result.first['count'] as int;
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Database connected! $count vehicles in URA database.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Database error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          context,
                          'Recreate Database',
                          'Force database recreation (for testing)',
                          Icons.refresh,
                          () async {
                            try {
                              final dbHelper = DatabaseHelper();
                              await dbHelper.recreateDatabase();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Database recreated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error recreating database: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          context,
                          'Check Database Schema',
                          'Check database table structure',
                          Icons.table_chart,
                          () async {
                            try {
                              final dbHelper = DatabaseHelper();
                              final schema = await dbHelper.getDatabaseSchema();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Database Schema'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: schema.entries.map((entry) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Table: ${entry.key}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text('Columns: ${entry.value.join(', ')}'),
                                            const SizedBox(height: 8),
                                          ],
                                        );
                                      }).toList(),
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
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error checking schema: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          context,
                          'Email Configuration',
                          'Configure SMTP settings for email functionality',
                          Icons.email,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmailConfigScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          context,
                          'URA PDF Management',
                          'Manage URA database with PDF integration and Magic Lookup',
                          Icons.auto_awesome,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PdfManagementScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          context,
                          'Data Management',
                          'Backup, restore, import, and export data',
                          Icons.storage,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DataManagementScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          context,
                          'Performance Monitor',
                          'Monitor system performance and optimization',
                          Icons.speed,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PerformanceScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          context,
                          'Performance Metrics',
                          'View detailed performance metrics and statistics',
                          Icons.analytics,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PerformanceMetricsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          context,
                          'Background Settings',
                          'Customize app background and appearance',
                          Icons.image,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BackgroundSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          context,
                          'System Information',
                          'View system details and version',
                          Icons.info,
                          () {
                            // Show system info dialog
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GlassContainer(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GlassLiquidTheme.accentBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: GlassLiquidTheme.accentBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(
                      title,
                      style: GoogleFonts.poppins(
                fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white60,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}