import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/cloud_control_service.dart';
import '../theme/leon_theme.dart';
import '../utils/pdf_viewer_support.dart';
import '../widgets/leon/leon_bezel_card.dart';
import '../widgets/leon/leon_section_header.dart';

class AccountInvoiceDetailScreen extends StatefulWidget {
  final int userId;
  final String invoiceNumber;

  const AccountInvoiceDetailScreen({
    super.key,
    required this.userId,
    required this.invoiceNumber,
  });

  @override
  State<AccountInvoiceDetailScreen> createState() => _AccountInvoiceDetailScreenState();
}

class _AccountInvoiceDetailScreenState extends State<AccountInvoiceDetailScreen> {
  final _cloud = CloudControlService();
  Map<String, dynamic>? _invoice;
  bool _loading = true;
  String? _error;
  bool _pdfLoading = false;
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _cloud.fetchUserInvoiceDetail(widget.userId, widget.invoiceNumber);
      setState(() {
        _invoice = Map<String, dynamic>.from(data['invoice'] as Map);
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _viewPdf() async {
    if (_pdfPath != null) {
      await viewLocalPdf(context, title: widget.invoiceNumber, filePath: _pdfPath!);
      return;
    }
    if (_invoice?['machinePdfReady'] != true && _invoice?['pdfReady'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PDF not on cloud yet. It will generate automatically when the sales machine is online.',
            ),
          ),
        );
      }
      return;
    }
    setState(() => _pdfLoading = true);
    try {
      final bytes = await _cloud.fetchUserInvoicePdfBytes(widget.userId, widget.invoiceNumber);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/admin_${widget.invoiceNumber.replaceAll('/', '_')}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      _pdfPath = file.path;
      if (mounted) {
        await viewLocalPdf(context, title: widget.invoiceNumber, filePath: file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  String _str(dynamic v) {
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  String _money(dynamic v, {String suffix = ''}) {
    if (v == null) return '—';
    final n = num.tryParse(v.toString());
    if (n == null) return '—';
    final formatted = n.toStringAsFixed(n is int || n == n.roundToDouble() ? 0 : 2);
    return '$formatted$suffix';
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: LeonTypography.sans(fontSize: 12, color: LeonColors.muted)),
          ),
          Expanded(
            child: Text(value, style: LeonTypography.mono(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = _invoice;
    final customer = inv?['customer'] is Map
        ? Map<String, dynamic>.from(inv!['customer'] as Map)
        : <String, dynamic>{};

    return Scaffold(
      backgroundColor: LeonColors.canvas,
      appBar: AppBar(
        backgroundColor: LeonColors.surface,
        foregroundColor: LeonColors.ink,
        title: Text(widget.invoiceNumber, style: LeonTypography.mono(fontSize: 14)),
        actions: [
          if (inv != null)
            TextButton.icon(
              onPressed: _pdfLoading ? null : _viewPdf,
              icon: _pdfLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('PDF'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : inv == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      children: [
                        LeonBezelCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const LeonSectionHeader('Customer', color: LeonColors.secondary),
                              const SizedBox(height: 8),
                              _field('Name', _str(customer['name'] ?? inv['consigneeName'])),
                              _field('Phone', _str(customer['phone'] ?? inv['consigneePhone'])),
                              _field('Email', _str(customer['email'] ?? inv['consigneeEmail'])),
                              _field('Address', _str(customer['address'] ?? inv['consigneeAddress'])),
                              _field('City', _str(customer['city'] ?? inv['consigneeCity'])),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        LeonBezelCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const LeonSectionHeader('Vehicle', color: LeonColors.secondary),
                              const SizedBox(height: 8),
                              _field('Make', _str(inv['vehicleMake'])),
                              _field('Model', _str(inv['vehicleModel'])),
                              _field('Year', _str(inv['vehicleYear'])),
                              _field('Chassis', _str(inv['chassisNo'])),
                              _field('Stock / Ref', _str(inv['stockNo'] ?? inv['refNo'])),
                              _field('Color', _str(inv['color'])),
                              _field('Engine CC', _str(inv['vehicleEngineCC'])),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        LeonBezelCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const LeonSectionHeader('Amounts', color: LeonColors.secondary),
                              const SizedBox(height: 8),
                              _field('Status', _str(inv['status'])),
                              _field('C&F USD', _money(inv['carPriceUSD'] ?? inv['cfMombasaUsd'], suffix: ' USD')),
                              _field('Exchange rate', _money(inv['exchangeRate'])),
                              _field('1st installment', _money(inv['firstInstallmentUGX'], suffix: ' UGX')),
                              _field('Taxes URA', _money(inv['taxesURA'], suffix: ' UGX')),
                              _field('2nd installment', _money(inv['secondInstallmentUGX'], suffix: ' UGX')),
                              _field('Grand total', _money(inv['totalAmount'] ?? inv['grandTotalUgx'], suffix: ' UGX')),
                              _field('Due date', _str(inv['dueDate'])),
                            ],
                          ),
                        ),
                        if (inv['notes'] != null && inv['notes'].toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          LeonBezelCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const LeonSectionHeader('Notes', color: LeonColors.secondary),
                                const SizedBox(height: 8),
                                Text(_str(inv['notes']), style: LeonTypography.sans(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
    );
  }
}
