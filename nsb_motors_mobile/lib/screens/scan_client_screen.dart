import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class ScanClientScreen extends StatefulWidget {
  const ScanClientScreen({super.key});

  @override
  State<ScanClientScreen> createState() => _ScanClientScreenState();
}

class _ScanClientScreenState extends State<ScanClientScreen> {
  final _nameController = TextEditingController();
  String? _deviceId;
  String? _token;
  bool _approved = false;
  bool _processing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (_processing) return;
    final codes = cap.barcodes;
    if (codes.isEmpty) return;
    final raw = codes.first.rawValue;
    if (raw == null) return;
    try {
      _processing = true;
      final jsonData = json.decode(raw);
      final deviceId = jsonData['device_id']?.toString();
      final token = jsonData['token']?.toString();
      if (deviceId == null || token == null) throw Exception('Invalid QR');
      setState(() {
        _deviceId = deviceId;
        _token = token;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid QR: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
      );
    } finally {
      _processing = false;
    }
  }

  Future<void> _approve() async {
    final name = _nameController.text.trim();
    if (_deviceId == null) return;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter client name', style: GoogleFonts.poppins()), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _approved = true);
    final ok = await SupabaseService.approveDesktopClient(deviceId: _deviceId!, clientName: name);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _approved = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve client', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Scan Desktop QR',
                style: GoogleFonts.poppins(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: _onDetect,
              controller: MobileScannerController(
                detectionSpeed: DetectionSpeed.noDuplicates,
                facing: CameraFacing.back,
              ),
            ),
          ),
          if (_deviceId != null) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Device: $_deviceId', style: GoogleFonts.poppins(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Client Name (admin sets)',
                      labelStyle: GoogleFonts.poppins(color: Colors.white70),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _approved ? null : _approve,
                      child: _approved ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('Approve'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ],
      ),
    );
  }
}



