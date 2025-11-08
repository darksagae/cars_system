import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/pairing_service.dart';
import '../services/remote_command_service.dart';
import '../widgets/glass_liquid_theme.dart';
import '../services/remote_command_executor.dart';

class PairingLockScreen extends StatefulWidget {
  const PairingLockScreen({super.key});

  @override
  State<PairingLockScreen> createState() => _PairingLockScreenState();
}

class _PairingLockScreenState extends State<PairingLockScreen> {
  final PairingService _pairingService = PairingService();
  final RemoteCommandService _remoteService = RemoteCommandService();
  Map<String, dynamic>? _payload;
  bool _isLoading = true;
  Timer? _pollTimer;

  String? _status;
  String? _assignedClientName;

  @override
  void initState() {
    super.initState();
    _loadPayload();
  }

  Future<void> _loadPayload() async {
    final data = await _pairingService.buildPairingPayload();
    await _remoteService.initialize();
    setState(() {
      _payload = data;
      _isLoading = false;
    });
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_payload == null) return;
      final res = await _remoteService.pollPairingApproval(deviceId: _payload!['device_id']);
      if (!mounted || res == null) return;
      final status = res['status'] as String?;
      final clientName = res['client_name'] as String?;
      setState(() {
        _status = status;
        _assignedClientName = clientName;
      });
      if (status == 'approved' && clientName != null && clientName.isNotEmpty) {
        _pollTimer?.cancel();
        // Immediately register this desktop with the approved name
        try {
          await _remoteService.registerClient(
            overrideClientName: clientName,
            overrideClientId: _payload!['device_id'],
          );
          // Force one immediate last_seen update so mobile shows live status
          await _remoteService.updateLastSeen();
          // Start background heartbeat (updates last_seen every few seconds)
          await RemoteCommandExecutor().initialize();
        } catch (_) {}
        await _pairingService.markPaired(clientName: clientName);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/');
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Admin Pairing Required',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This desktop is locked until an admin approves it.\nScan the QR with the mobile admin app to pair.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: GlassLiquidTheme.glassPrimary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: GlassLiquidTheme.glassBorder),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: QrImageView(
                          data: jsonEncode(_payload),
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Device ID: ${_payload!['device_id']}',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(height: 12),
                      Text(
                        _status == 'approved'
                            ? 'Approved by admin. Assigning client: ${_assignedClientName ?? ''}'
                            : 'Waiting for admin approval…',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 18,
                        width: 18,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            await _pairingService.rotatePairingToken();
                            await _loadPayload();
                            setState(() => _isLoading = false);
                          },
                          child: const Text('Regenerate QR'),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}


