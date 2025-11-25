import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/whatsapp_message_tracking_service.dart';
import '../services/whatsapp_auto_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_liquid_theme.dart';
import '../providers/theme_provider.dart';
import 'dart:async';

class ContactForwardingScreen extends StatefulWidget {
  final VoidCallback? onClose;

  const ContactForwardingScreen({Key? key, this.onClose}) : super(key: key);

  @override
  State<ContactForwardingScreen> createState() => _ContactForwardingScreenState();
}

class _ContactForwardingScreenState extends State<ContactForwardingScreen> {
  final WhatsAppMessageTrackingService _trackingService = WhatsAppMessageTrackingService();
  final WhatsAppAutoService _whatsappService = WhatsAppAutoService();
  
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadContacts();
      }
    });
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contacts = await _trackingService.getForwardedContacts(unacknowledgedOnly: false);
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acknowledgeContact(String contactId) async {
    try {
      await _trackingService.acknowledgeContact(contactId);
      await _loadContacts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contact acknowledged', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startConversation(String contactId, String clientPhone) async {
    try {
      // Mark as conversation started
      await _trackingService.markConversationStarted(contactId);
      await _acknowledgeContact(contactId);
      
      // Open WhatsApp with the contact
      await _whatsappService.sendMessage(
        phoneNumber: clientPhone,
        message: 'Hello! How can I help you today?',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversation started!', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await _loadContacts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting conversation: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Forwarded Contacts',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (widget.onClose != null) {
                  widget.onClose!();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadContacts,
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _contacts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadContacts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) {
                            return _buildContactCard(_contacts[index]);
                          },
                        ),
                      ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.userGroup,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Forwarded Contacts',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When clients reply to your messages,\ncontacts will appear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    final clientPhone = contact['client_phone'] as String? ?? '';
    final clientName = contact['client_name'] as String? ?? 'Unknown';
    final forwardedAt = contact['forwarded_at'] as String?;
    final acknowledged = contact['acknowledged'] as bool? ?? false;
    final conversationStarted = contact['conversation_started'] as bool? ?? false;
    final contactId = contact['id'] as String;

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: GlassLiquidTheme.accentBlue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FontAwesomeIcons.user,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.phone,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            clientPhone,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!acknowledged)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'New',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (forwardedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Forwarded: ${_formatDate(forwardedAt)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (!acknowledged)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acknowledgeContact(contactId),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text('Acknowledge', style: GoogleFonts.poppins(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlassLiquidTheme.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                if (!acknowledged) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: conversationStarted
                        ? null
                        : () => _startConversation(contactId, clientPhone),
                    icon: Icon(
                      conversationStarted ? Icons.check_circle : FontAwesomeIcons.message,
                      size: 18,
                    ),
                    label: Text(
                      conversationStarted ? 'Started' : 'Start Chat',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: conversationStarted
                          ? Colors.green
                          : GlassLiquidTheme.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
}

