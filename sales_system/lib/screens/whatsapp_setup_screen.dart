import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/whatsapp_auto_service.dart';
import '../widgets/glass_liquid_theme.dart';
import '../widgets/glass_container.dart';
import 'dart:async';

class WhatsAppSetupScreen extends StatefulWidget {
  const WhatsAppSetupScreen({Key? key}) : super(key: key);

  @override
  State<WhatsAppSetupScreen> createState() => _WhatsAppSetupScreenState();
}

class _WhatsAppSetupScreenState extends State<WhatsAppSetupScreen> {
  final WhatsAppAutoService _whatsappService = WhatsAppAutoService();
  
  String? _qrCodeData;
  String _status = 'checking';
  bool _isServiceRunning = false;
  bool _isReady = false;
  String _statusMessage = 'Checking service status...';
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkServiceStatus() async {
    try {
      // Check if service is running
      final isRunning = await _whatsappService.isServiceRunning();
      
      if (!isRunning) {
        setState(() {
          _isServiceRunning = false;
          _status = 'service_not_running';
          _statusMessage = 'WhatsApp service is not running. Please start it first.';
        });
        return;
      }

      setState(() {
        _isServiceRunning = true;
      });

      // Get status
      final statusData = await _whatsappService.getStatus();
      final status = statusData['status'] as String?;
      final ready = statusData['ready'] as bool? ?? false;
      final hasQR = statusData['hasQR'] as bool? ?? false;

      setState(() {
        _status = status ?? 'unknown';
        _isReady = ready;
      });

      // If QR code is available, get it
      if (hasQR && status == 'qr_ready') {
        await _loadQRCode();
      } else if (ready) {
        setState(() {
          _statusMessage = 'WhatsApp is connected and ready!';
        });
      } else {
        setState(() {
          _statusMessage = 'Status: $status';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'error';
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _loadQRCode() async {
    try {
      final qrData = await _whatsappService.getQRCode();
      if (qrData['success'] == true && qrData['qr'] != null) {
        setState(() {
          _qrCodeData = qrData['qr'] as String;
          _statusMessage = 'Scan the QR code with WhatsApp on your phone';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading QR code: $e';
      });
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _checkServiceStatus();
        
        // If ready, stop polling
        if (_isReady) {
          timer.cancel();
        }
      }
    });
  }

  Future<void> _restartService() async {
    try {
      setState(() {
        _statusMessage = 'Restarting service...';
      });
      
      await _whatsappService.restartService();
      
      // Wait a bit then refresh
      await Future.delayed(const Duration(seconds: 2));
      await _checkServiceStatus();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error restarting: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          'WhatsApp Setup',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: GlassLiquidTheme.accentBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            if (!_isServiceRunning) _buildServiceNotRunningCard(),
            if (_isServiceRunning && _status == 'qr_ready') _buildQRCodeCard(),
            if (_isServiceRunning && _isReady) _buildReadyCard(),
            if (_isServiceRunning && _status != 'qr_ready' && !_isReady)
              _buildStatusMessageCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!_isServiceRunning) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusText = 'Service Not Running';
    } else if (_isReady) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Connected & Ready';
    } else if (_status == 'qr_ready') {
      statusColor = Colors.orange;
      statusIcon = Icons.qr_code;
      statusText = 'Scan QR Code';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.sync;
      statusText = 'Connecting...';
    }

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _checkServiceStatus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceNotRunningCard() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start WhatsApp Service',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To enable automatic WhatsApp sending, start the Node.js service:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                'cd whatsapp_service\nnpm install\nnpm start',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _checkServiceStatus,
              icon: const Icon(Icons.refresh),
              label: Text('Check Again', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassLiquidTheme.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Scan QR Code with WhatsApp',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Open WhatsApp on your phone\n'
              '2. Go to Settings → Linked Devices\n'
              '3. Tap "Link a Device"\n'
              '4. Scan this QR code',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            if (_qrCodeData != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _qrCodeData!,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              )
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _restartService,
              icon: const Icon(Icons.refresh),
              label: Text('Refresh QR Code', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassLiquidTheme.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyCard() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'WhatsApp is Connected!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can now send messages automatically.\nNo QR code scanning needed!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: Text('Done', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessageCard() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Status: $_status',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _restartService,
              icon: const Icon(Icons.refresh),
              label: Text('Retry', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassLiquidTheme.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

