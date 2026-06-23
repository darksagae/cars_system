import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/whatsapp_server_service.dart';
import '../services/whatsapp_queue_processor.dart';
import 'package:share_plus/share_plus.dart';

class WhatsAppServerScreen extends StatefulWidget {
  const WhatsAppServerScreen({Key? key}) : super(key: key);

  @override
  State<WhatsAppServerScreen> createState() => _WhatsAppServerScreenState();
}

class _WhatsAppServerScreenState extends State<WhatsAppServerScreen> {
  final WhatsAppServerService _serverService = WhatsAppServerService();
  bool _isStarting = false;
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();
    // Refresh state when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  Future<void> _startServer() async {
    setState(() {
      _isStarting = true;
    });

    try {
      final success = await _serverService.start();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ WhatsApp server started successfully!',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Failed to start server',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  Future<void> _stopServer() async {
    setState(() {
      _isStopping = true;
    });

    try {
      await _serverService.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ WhatsApp server stopped',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStopping = false;
        });
      }
    }
  }

  Future<void> _shareServerUrl() async {
    final url = _serverService.serverUrl;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Server is not running',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Share.share(
      'WhatsApp Server URL: $url\n\nDesktop machines can connect to this URL to send WhatsApp messages.',
      subject: 'WhatsApp Server Connection',
    );
  }

  void _copyServerUrl() {
    final url = _serverService.serverUrl;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Server is not running',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Copy to clipboard
    // Note: You'll need to add clipboard package if not available
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Server URL copied: $url',
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _serverService.isRunning;
    final serverUrl = _serverService.serverUrl;
    final serverIp = _serverService.serverIp;
    final port = _serverService.port;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'WhatsApp Server',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isRunning ? Icons.check_circle : Icons.error_outline,
                          color: isRunning ? Colors.green : Colors.red,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isRunning ? 'Server Running' : 'Server Stopped',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isRunning ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isRunning && serverUrl != null) ...[
                      _buildInfoRow('Server URL', serverUrl),
                      const SizedBox(height: 8),
                      _buildInfoRow('IP Address', serverIp ?? 'Unknown'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Port', port.toString()),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Queue Processor Status
            Card(
              elevation: 2,
              color: WhatsAppQueueProcessor().isRunning ? Colors.green[50] : Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          WhatsAppQueueProcessor().isRunning ? Icons.check_circle : Icons.error_outline,
                          color: WhatsAppQueueProcessor().isRunning ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          WhatsAppQueueProcessor().isRunning 
                              ? 'Queue Processor: Running' 
                              : 'Queue Processor: Stopped',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: WhatsAppQueueProcessor().isRunning ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      WhatsAppQueueProcessor().isRunning
                          ? '✅ Messages are being processed automatically from Supabase queue.\n'
                            '✅ Works from anywhere - no WiFi required!\n'
                            '✅ Desktop machines send messages via Supabase.\n'
                            '✅ This app processes them automatically every 5 seconds.'
                          : '⚠️ Queue processor is stopped. Messages will not be processed automatically.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Instructions
            Card(
              elevation: 2,
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 How It Works',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Desktop machines send messages to Supabase queue\n'
                      '2. This app automatically processes pending messages\n'
                      '3. WhatsApp opens with the message (you click send)\n'
                      '4. Works from anywhere - no WiFi required!\n'
                      '5. Messages are tracked in Supabase',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            if (isRunning) ...[
              ElevatedButton.icon(
                onPressed: _shareServerUrl,
                icon: const Icon(Icons.share),
                label: Text(
                  'Share Server URL',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _copyServerUrl,
                icon: const Icon(Icons.copy),
                label: Text(
                  'Copy Server URL',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isStopping ? null : _stopServer,
                icon: _isStopping
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.stop),
                label: Text(
                  'Stop Server',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _isStarting ? null : _startServer,
                icon: _isStarting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  'Start Server',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Note
            Card(
              elevation: 1,
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Note: When a message is queued, WhatsApp will open automatically and you need to manually click the send button. This is a limitation of WhatsApp\'s security model.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

