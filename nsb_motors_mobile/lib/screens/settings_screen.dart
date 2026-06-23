import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import '../services/supabase_service.dart';
import '../providers/app_provider.dart';
import '../services/notification_preferences_service.dart';
import 'whatsapp_server_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationPreferencesService _prefsService =
      NotificationPreferencesService();
  bool _pushNotificationsEnabled = true;
  bool _emailAlertsEnabled = false;
  bool _isLoading = true;

  static const _canvas = Color(0xFFF8FAFC);
  static const _ink = Color(0xFF0F172A);
  static const _secondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _accent = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await _prefsService.initialize();
    setState(() {
      _pushNotificationsEnabled = _prefsService.pushNotificationsEnabled;
      _emailAlertsEnabled = _prefsService.emailAlertsEnabled;
      _isLoading = false;
    });
  }

  Future<void> _onPushNotificationsChanged(bool value) async {
    setState(() => _pushNotificationsEnabled = value);
    await _prefsService.setPushNotificationsEnabled(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Push notifications ${value ? "enabled" : "disabled"}'),
          backgroundColor:
              value ? const Color(0xFF059669) : const Color(0xFF64748B),
        ),
      );
    }
  }

  Future<void> _onEmailAlertsChanged(bool value) async {
    setState(() => _emailAlertsEnabled = value);
    await _prefsService.setEmailAlertsEnabled(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email alerts ${value ? "enabled" : "disabled"}'),
          backgroundColor:
              value ? const Color(0xFF059669) : const Color(0xFF64748B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 28),
                  _sectionLabel('WhatsApp'),
                  const SizedBox(height: 10),
                  _buildGroup([
                    _actionRow(
                      icon: Icons.chat_bubble_rounded,
                      iconColor: const Color(0xFF25D366),
                      iconBg: const Color(0xFFE8FFF2),
                      title: 'Manage WhatsApp Server',
                      subtitle: 'Start/stop server for desktop machines',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WhatsAppServerScreen()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _sectionLabel('Notifications'),
                  const SizedBox(height: 10),
                  _buildGroup([
                    _switchRow(
                      icon: Icons.notifications_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      iconBg: const Color(0xFFF5F3FF),
                      title: 'Push Notifications',
                      subtitle: 'Receive client update notifications',
                      value: _pushNotificationsEnabled,
                      onChanged: _onPushNotificationsChanged,
                      isLast: false,
                    ),
                    _switchRow(
                      icon: Icons.email_rounded,
                      iconColor: const Color(0xFF1D4ED8),
                      iconBg: const Color(0xFFEFF6FF),
                      title: 'Email Alerts',
                      subtitle: 'Get email alerts for system events',
                      value: _emailAlertsEnabled,
                      onChanged: _onEmailAlertsChanged,
                      isLast: true,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _sectionLabel('System'),
                  const SizedBox(height: 10),
                  _buildGroup([
                    _infoRow(
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF64748B),
                      iconBg: const Color(0xFFF1F5F9),
                      title: 'App Version',
                      value: '1.0.0',
                    ),
                    _infoRow(
                      icon: Icons.cloud_done_rounded,
                      iconColor: const Color(0xFF059669),
                      iconBg: const Color(0xFFECFDF5),
                      title: 'Status',
                      value: 'Connected',
                    ),
                    _actionRow(
                      icon: Icons.cleaning_services_rounded,
                      iconColor: const Color(0xFFD97706),
                      iconBg: const Color(0xFFFFFBEB),
                      title: 'Clear Cache',
                      subtitle: 'Clear local cache and refresh data',
                      onTap: () => _clearCache(context),
                    ),
                    _actionRow(
                      icon: Icons.file_download_rounded,
                      iconColor: _accent,
                      iconBg: const Color(0xFFEFF6FF),
                      title: 'Export Data',
                      subtitle: 'Export system data for backup',
                      onTap: () => _exportData(context),
                      isLast: true,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _sectionLabel('Support'),
                  const SizedBox(height: 10),
                  _buildGroup([
                    _actionRow(
                      icon: Icons.support_agent_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      iconBg: const Color(0xFFF5F3FF),
                      title: 'Help & Support',
                      subtitle: 'Contact technical support',
                      onTap: () => _callSupport(context),
                    ),
                    _actionRow(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: _secondary,
                      iconBg: const Color(0xFFF1F5F9),
                      title: 'Privacy Policy',
                      subtitle: 'View privacy policy',
                      onTap: () {},
                    ),
                    _actionRow(
                      icon: Icons.description_outlined,
                      iconColor: _secondary,
                      iconBg: const Color(0xFFF1F5F9),
                      title: 'Terms of Service',
                      subtitle: 'View terms of service',
                      onTap: () {},
                      isLast: true,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSignOutRow(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    final email = SupabaseService.currentUser?.email ?? 'Not signed in';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_rounded,
                color: Color(0xFF1D4ED8), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _secondary,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Active',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF059669)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
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

  Widget _buildGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(children: children),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20))
          : BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _ink)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: _secondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required Future<void> Function(bool) onChanged,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                Text(subtitle,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: _secondary)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
          ),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: _secondary)),
        ],
      ),
    );
  }

  Widget _buildSignOutRow() {
    return InkWell(
      onTap: () async => await SupabaseService.signOut(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sign Out',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626))),
                  Text('Sign out of your account',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: const Color(0xFFEF4444))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFFCA5A5), size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cache?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'This will clear all cached data and refresh from server.',
          style: GoogleFonts.plusJakartaSans(color: _secondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706)),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (context.mounted) {
          context.read<AppProvider>().refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cache cleared successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final appProvider = context.read<AppProvider>();
      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'system_stats': appProvider.systemStats,
        'desktop_clients': appProvider.desktopClients,
        'ura_updates': appProvider.uraUpdates,
        'exchange_rate': appProvider.currentExchangeRate,
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/nsb_motors_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      await Share.shareXFiles([XFile(file.path)],
          text: 'NSB Motors System Data Export',
          subject: 'NSB Motors Data Export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _callSupport(BuildContext context) async {
    const phoneNumber = '0705223777';
    final uri = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone: $phoneNumber')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone: $phoneNumber')),
        );
      }
    }
  }
}
