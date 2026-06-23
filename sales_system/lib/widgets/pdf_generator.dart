import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';
import '../models/invoice.dart';
import '../services/pdf/pdf_service.dart';
import 'glass_container.dart';
import 'glass_liquid_theme.dart';

class PDFGenerator extends StatefulWidget {
  final Invoice invoice;

  const PDFGenerator({super.key, required this.invoice});

  @override
  State<PDFGenerator> createState() => _PDFGeneratorState();
}

class _PDFGeneratorState extends State<PDFGenerator> {
  final PDFService _pdfService = PDFService();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildPreviewSection(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const FaIcon(
            FontAwesomeIcons.filePdf,
            color: Colors.red,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate PDF',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Create a professional PDF invoice',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice Preview',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildPreviewInfo('Invoice Number', widget.invoice.invoiceNumber),
          _buildPreviewInfo('Customer ID', widget.invoice.customerId.toString()),
          _buildPreviewInfo('Total Amount', '\$${widget.invoice.totalAmount.toStringAsFixed(2)}'),
          _buildPreviewInfo('Status', widget.invoice.statusText),
          _buildPreviewInfo('Due Date', _formatDate(widget.invoice.dueDate)),
        ],
      ),
    );
  }

  Widget _buildPreviewInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Preview PDF',
                FontAwesomeIcons.eye,
                GlassLiquidTheme.accentBlue,
                _previewPDF,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Print PDF',
                FontAwesomeIcons.print,
                Colors.green,
                _printPDF,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Save PDF',
                FontAwesomeIcons.download,
                Colors.orange,
                _savePDF,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Share PDF',
                FontAwesomeIcons.share,
                Colors.purple,
                _sharePDF,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isGenerating ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              if (_isGenerating)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: color,
                    strokeWidth: 2,
                  ),
                )
              else
                FaIcon(
                  icon,
                  color: color,
                  size: 20,
                ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _previewPDF() async {
    if (_isGenerating) return;
    _isGenerating = true;
    setState(() {});

    try {
      final pdfBytes = await _pdfService.generateInvoicePDF(widget.invoice);
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: '${widget.invoice.invoiceNumber}.pdf',
        format: PdfPageFormat.a4,
        dynamicLayout: false,
      );
    } catch (e) {
      _showError('Error previewing PDF: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _printPDF() async {
    if (_isGenerating) return;
    _isGenerating = true;
    setState(() {});

    try {
      await _pdfService.printPDF(widget.invoice);
      _showSuccess('PDF sent to printer successfully!');
    } catch (e) {
      _showError('Error printing PDF: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _savePDF() async {
    if (_isGenerating) return;
    _isGenerating = true;
    setState(() {});

    try {
      final filePath = await _pdfService.savePDFToFile(widget.invoice);
      if (!mounted) return;
      _showSuccessWithOpen('PDF saved to Downloads.', filePath);
    } catch (e) {
      _showError('Error saving PDF: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showSuccessWithOpen(String message, String filePath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green.withOpacity(0.8),
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () async {
            final result = await OpenFilex.open(filePath);
            if (result.type != ResultType.done && mounted) {
              _showError(result.message);
            }
          },
        ),
      ),
    );
  }

  Future<void> _sharePDF() async {
    if (_isGenerating) return;
    _isGenerating = true;
    setState(() {});

    try {
      await _pdfService.sharePDF(widget.invoice);
      _showSuccess('PDF shared successfully!');
    } catch (e) {
      _showError('Error sharing PDF: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green.withOpacity(0.8),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red.withOpacity(0.8),
      ),
    );
  }
}

