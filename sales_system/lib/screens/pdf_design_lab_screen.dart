import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import '../services/pdf/pdf_service.dart';

enum _DesignVariant {
  current,
  minimal,
  compact,
  classicGrid,
  taxSummary,
}

class PdfDesignLabScreen extends StatefulWidget {
  const PdfDesignLabScreen({super.key});

  @override
  State<PdfDesignLabScreen> createState() => _PdfDesignLabScreenState();
}

class _PdfDesignLabScreenState extends State<PdfDesignLabScreen> {
  int? _selectedInvoiceId;
  _DesignVariant _selectedVariant = _DesignVariant.current;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InvoiceProvider>();
      if (provider.invoices.isEmpty) {
        provider.loadInvoices();
      }
    });
  }

  Invoice? _findSelectedInvoice(List<Invoice> invoices) {
    if (_selectedInvoiceId == null) return null;
    for (final invoice in invoices) {
      if (invoice.id == _selectedInvoiceId) return invoice;
    }
    return null;
  }

  Future<Uint8List> _generatePdf(Invoice invoice) async {
    switch (_selectedVariant) {
      case _DesignVariant.current:
        return PDFService().generateInvoicePDF(invoice);
      case _DesignVariant.minimal:
        return PDFService().generateInvoiceDesignLabSecond(invoice);
      case _DesignVariant.compact:
        return _generateCompactPdf(invoice);
      case _DesignVariant.classicGrid:
        return PDFService().generateInvoiceDesignLabThird(invoice);
      case _DesignVariant.taxSummary:
        return PDFService().generateInvoiceDesignLabSummary(invoice);
    }
  }

  Future<void> _previewPdf(Invoice invoice) async {
    setState(() => _isGenerating = true);
    try {
      final bytes = await _generatePdf(invoice);
      if (!mounted) return;
      await Printing.layoutPdf(
        name: 'DesignLab_${_selectedVariant.name}_${invoice.invoiceNumber}',
        onLayout: (format) async => bytes,
        format: PdfPageFormat.a4,
        dynamicLayout: false,
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _savePdfSample(Invoice invoice) async {
    setState(() => _isGenerating = true);
    try {
      final bytes = await _generatePdf(invoice);
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'design_lab_${_selectedVariant.name}_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved sample PDF: ${file.path}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  String _money(num value) => NumberFormat('#,##0.00').format(value);

  Future<Uint8List> _generateMinimalPdf(Invoice invoice) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Invoice No: ${invoice.invoiceNumber}'),
              pw.Text('Invoice Date: ${dateFmt.format(invoice.invoiceDate)}'),
              pw.Text('Due Date: ${dateFmt.format(invoice.dueDate)}'),
              pw.SizedBox(height: 16),
              pw.Text('Customer', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(invoice.customer?.name ?? 'Unknown'),
              pw.Text(invoice.customer?.phone ?? ''),
              pw.SizedBox(height: 16),
              pw.Text('Vehicle', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('${invoice.vehicleMake} ${invoice.vehicleModel} (${invoice.vehicleYear})'),
              pw.Text('Color: ${invoice.color}'),
              pw.SizedBox(height: 16),
              pw.Text('Amounts', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Phase 1: UGX ${_money(invoice.firstInstallmentUGX)}'),
              pw.Text('Phase 2: UGX ${_money(invoice.secondInstallmentUGX)}'),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Grand Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    'UGX ${_money(invoice.totalAmount)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Text(
                'Design Lab Template: MINIMAL',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _generateCompactPdf(Invoice invoice) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            children: [
              pw.Container(
                color: PdfColors.grey900,
                padding: const pw.EdgeInsets.all(12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'NSB Motors Ug',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      invoice.invoiceNumber,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date: ${dateFmt.format(invoice.invoiceDate)}'),
                    pw.Text('Due: ${dateFmt.format(invoice.dueDate)}'),
                    pw.SizedBox(height: 6),
                    pw.Text('Customer: ${invoice.customer?.name ?? 'Unknown'}'),
                    pw.Text('Vehicle: ${invoice.vehicleMake} ${invoice.vehicleModel} (${invoice.vehicleYear})'),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey700),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                },
                children: [
                  _row('Phase 1 (UGX)', _money(invoice.firstInstallmentUGX), header: true),
                  _row('Phase 2 (UGX)', _money(invoice.secondInstallmentUGX)),
                  _row('Taxes URA (UGX)', _money(invoice.taxesURA)),
                  _row('TOTAL (UGX)', _money(invoice.totalAmount), bold: true),
                ],
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Design Lab Template: COMPACT',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.TableRow _row(String label, String value, {bool header = false, bool bold = false}) {
    final textStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: (bold || header) ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.TableRow(
      decoration: header ? const pw.BoxDecoration(color: PdfColors.grey300) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(label, style: textStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(value, style: textStyle),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = context.watch<InvoiceProvider>();
    final invoices = invoiceProvider.invoices;
    final selectedInvoice = _findSelectedInvoice(invoices);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Design Lab'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test multiple invoice PDF designs using the same invoice data.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedInvoiceId,
                    decoration: const InputDecoration(labelText: 'Select Invoice'),
                    items: invoices
                        .map(
                          (invoice) => DropdownMenuItem<int>(
                            value: invoice.id,
                            child: Text(
                              '${invoice.invoiceNumber} - ${invoice.customer?.name ?? 'Unknown'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isGenerating
                        ? null
                        : (value) {
                            setState(() => _selectedInvoiceId = value);
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<_DesignVariant>(
                    value: _selectedVariant,
                    decoration: const InputDecoration(labelText: 'Design Variant'),
                    items: const [
                      DropdownMenuItem(
                        value: _DesignVariant.current,
                        child: Text('Current (Production)'),
                      ),
                      DropdownMenuItem(
                        value: _DesignVariant.minimal,
                        child: Text('Middle Redesign (Header/Footer Fixed)'),
                      ),
                      DropdownMenuItem(
                        value: _DesignVariant.compact,
                        child: Text('Compact'),
                      ),
                      DropdownMenuItem(
                        value: _DesignVariant.classicGrid,
                        child: Text('Classic Grid (Header/Footer Fixed)'),
                      ),
                      DropdownMenuItem(
                        value: _DesignVariant.taxSummary,
                        child: Text('Tax Summary (Header/Footer Fixed)'),
                      ),
                    ],
                    onChanged: _isGenerating
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _selectedVariant = value);
                            }
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: (_isGenerating || selectedInvoice == null)
                      ? null
                      : () => _previewPdf(selectedInvoice),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.preview),
                  label: Text(_isGenerating ? 'Generating...' : 'Preview PDF'),
                ),
                ElevatedButton.icon(
                  onPressed: (_isGenerating || selectedInvoice == null)
                      ? null
                      : () => _savePdfSample(selectedInvoice),
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save Sample'),
                ),
                OutlinedButton.icon(
                  onPressed: _isGenerating
                      ? null
                      : () => context.read<InvoiceProvider>().loadInvoices(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload Invoices'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (invoiceProvider.isLoading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Invoices loaded: ${invoices.length}',
              style: const TextStyle(color: Colors.white70),
            ),
            if (selectedInvoice != null) ...[
              const SizedBox(height: 8),
              Text(
                'Selected: ${selectedInvoice.invoiceNumber} | Total UGX ${_money(selectedInvoice.totalAmount)}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


