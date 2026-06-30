import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../models/demand_letter.dart';

class PDFService {
  static bool _isGenerating = false;

  // Helper method to get saved username from SharedPreferences
  Future<String> _getSalesPersonName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_profile_name');
      return username?.isNotEmpty == true ? username! : 'NSB SALES TEAM';
    } catch (e) {
      print('Error getting sales person name: $e');
      return 'NSB SALES TEAM';
    }
  }

  // Generate analytics PDF report from aggregated dashboard data
  Future<Uint8List> generateAnalyticsReport({
    required Map<String, dynamic> analytics,
    required DateTime startDate,
    required DateTime endDate,
    required String reportTitle,
  }) async {
    try {
      final pdf = pw.Document();
      pw.ImageProvider? logoPdfImage;
      try {
        logoPdfImage = await _loadLogoAsPdfImage();
      } catch (e) {
        print('Warning: Could not load logo: $e');
      }

      final stats = (analytics['stats'] as Map<String, dynamic>?);
      final statusBreakdown = Map<String, dynamic>.from((analytics['statusBreakdown'] as Map?) ?? const {});
      final customers = (analytics['customers'] as List<Customer>?) ?? <Customer>[];
      final paymentMethodBreakdown = Map<String, dynamic>.from((analytics['paymentMethodBreakdown'] as Map?) ?? const {});
      final recentInvoices = (analytics['recentInvoices'] as List<Invoice>?) ?? <Invoice>[];
      final topCustomerEntries = (analytics['topCustomers'] as List<dynamic>?) ?? const [];

      // Helper function to format numbers
      String fmtNum(num n) {
        return _fmtNum(n);
      }

      pw.Widget _metric(String label, String value) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 3),
              pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );
      }

    pw.Widget _breakdownTable(String title, Map<String, dynamic> data) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
            columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1)},
            children: [
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Value', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              ]),
              ...data.entries.take(10).map((e) => pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${e.key}', style: const pw.TextStyle(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('${e.value}', style: const pw.TextStyle(fontSize: 10)))),
                  ])),
            ],
          ),
        ],
      );
    }

    pw.Widget _topCustomersByRevenue(List<dynamic> entries, List<Customer> fallback) {
      final rows = entries
          .map((e) {
            try {
              final c = e['customer'] as Customer?;
              final rev = (e['revenue'] as num?) ?? 0;
              return [c?.name ?? 'Unknown', _isPlaceholderOrEmptyEmail(c?.email) ? 'N/A' : (c?.email ?? '—'), c?.phone ?? '—', rev];
            } catch (_) {
              return null;
            }
          })
          .whereType<List<dynamic>>()
          .toList();
      final useFallback = rows.isEmpty;
      final topFallback = fallback.take(5).map((c) => [c.name, c.email, c.phone, 0]).toList();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('Top Customers by Revenue', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(2), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(1.2)},
            children: [
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Name', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Email', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Phone', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Revenue', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              ]),
              ...((useFallback ? topFallback : rows).take(5)).map((r) => pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${r[0]}', style: const pw.TextStyle(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${r[1]}', style: const pw.TextStyle(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${r[2]}', style: const pw.TextStyle(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(useFallback ? '—' : 'UGX ${fmtNum((r[3] as num))}', style: const pw.TextStyle(fontSize: 10)))),
                  ])),
            ],
          ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(children: [
                  if (logoPdfImage != null)
                    pw.Container(width: 48, height: 36, child: pw.Image(logoPdfImage, fit: pw.BoxFit.contain)),
                  pw.SizedBox(width: 10),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('NSB Motors Ug', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ]),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text(reportTitle, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Period: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}', style: const pw.TextStyle(fontSize: 10)),
                ]),
              ],
            ),
            pw.SizedBox(height: 16),

            // Summary metrics grid
            if (stats != null) ...[
              pw.Text('Summary', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _metric('Total Revenue', 'UGX ${fmtNum((stats['totalRevenue'] ?? 0.0) as num)}'),
                      _metric('Total Invoices', '${stats['totalInvoices'] ?? 0}'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _metric('Total Customers', '${stats['totalCustomers'] ?? 0}'),
                      _metric('Outstanding', 'UGX ${fmtNum((stats['totalOutstanding'] ?? 0.0) as num)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // Status breakdown
            if (statusBreakdown.isNotEmpty)
              _breakdownTable('Invoice Status Breakdown', statusBreakdown),
            if (statusBreakdown.isNotEmpty) pw.SizedBox(height: 16),

            // Payment methods
            if (paymentMethodBreakdown.isNotEmpty)
              _breakdownTable('Payment Methods', paymentMethodBreakdown),
            if (paymentMethodBreakdown.isNotEmpty) pw.SizedBox(height: 16),

            // Top customers
            if (customers.isNotEmpty || topCustomerEntries.isNotEmpty) _topCustomersByRevenue(topCustomerEntries, customers),
            if (customers.isNotEmpty || topCustomerEntries.isNotEmpty) pw.SizedBox(height: 16),

            // Recent invoices small table
            if (recentInvoices.isNotEmpty)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('Recent Invoices', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
                    columnWidths: {0: const pw.FlexColumnWidth(1.6), 1: const pw.FlexColumnWidth(2.2), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(1)},
                    children: [
                      pw.TableRow(children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Invoice #', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Customer', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Status', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      ]),
                      ...recentInvoices.take(10).map((inv) => pw.TableRow(children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(inv.invoiceNumber, style: const pw.TextStyle(fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text((inv.customer?.name?.isNotEmpty == true) ? inv.customer!.name : 'N/A', style: const pw.TextStyle(fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('UGX ${fmtNum(inv.totalAmount)}', style: const pw.TextStyle(fontSize: 10)))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(inv.status.name, style: const pw.TextStyle(fontSize: 10))),
                          ])),
                    ],
                  ),
                ],
              ),
        ];
        },
      ),
    );

    return pdf.save();
    } catch (e) {
      print('Error generating analytics PDF: $e');
      rethrow;
    }
  }
  // Generate professional invoice PDF — uses Tax Summary design (Design Lab variant)
  /// Only one invoice PDF generation at a time; concurrent calls throw until the current one completes.
  Future<Uint8List> generateInvoicePDF(Invoice invoice) async {
    if (_isGenerating) {
      throw StateError('A PDF is already being generated. Please wait for it to complete.');
    }
    _isGenerating = true;
    try {
      return await generateInvoiceDesignLabSummary(invoice);
    } finally {
      _isGenerating = false;
    }
  }

  // Legacy: Original full quotation-style PDF (kept for reference, not used in production)
  Future<Uint8List> _generateInvoicePDFLegacy(Invoice invoice) async {
    final pdf = pw.Document();
    
    // Load logo image
    final logoImage = await _loadLogoImage();
    final logoPdfImage = await _loadLogoAsPdfImage();
    
    // Load social media icon images
    final locationIcon = await _loadIconImage('assets/fonts/address.png');
    final whatsappIcon = await _loadIconImage('assets/fonts/whatsapp.png');
    final facebookIcon = await _loadIconImage('assets/fonts/facebook.png');
    final instagramIcon = await _loadIconImage('assets/fonts/insta.png');
    final xIcon = await _loadIconImage('assets/fonts/x.png');
    final tiktokIcon = await _loadIconImage('assets/fonts/tiktok.png');
    // Gmail icon (use location icon as fallback if gmail.png doesn't exist)
    final gmailIcon = await _loadIconImage('assets/fonts/gmail.png') ?? locationIcon;
    final bankWatermarkLogo = await _loadIconImage('assets/logo/logo.png');
    final trebuchetFont = await _loadTrebuchetFont();
    final boldItalicFont = await PdfGoogleFonts.robotoBoldItalic();
    
    // Get customer data - extract from notes if not linked
    Customer? customer = invoice.customer;
    if (customer == null && invoice.notes.isNotEmpty) {
      customer = _extractCustomerFromNotes(invoice.notes);
    }
    // Parse additional info from notes as fallbacks (style preserved)
    final _ParsedInvoiceNotes parsed = _parseInvoiceNotes(invoice.notes);

    // First page with main content
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(8),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.robotoRegular(),
          bold: await PdfGoogleFonts.robotoBold(),
          italic: await PdfGoogleFonts.robotoItalic(),
          boldItalic: await PdfGoogleFonts.robotoBoldItalic(),
        ),
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Document Title - QUOTATION
                _buildDocumentTitle(
                  invoice,
                  logoImage,
                  logoPdfImage,
                  locationIcon,
                  whatsappIcon,
                  facebookIcon,
                  instagramIcon,
                  xIcon,
                  tiktokIcon,
                  gmailIcon,
                ),
                
                // Customer Information Section
                _buildCustomerInformation(customer),
                
                // Vehicle Details Section
                _buildVehicleDetails(invoice),
                
                // First Installment Section
                _buildFirstInstallmentTable(invoice, parsed),
                
                // Second Installment Section
                _isPhaseTwoIncluded(invoice, parsed)
                    ? _buildSecondInstallmentTable(invoice, parsed)
                    : pw.SizedBox.shrink(),
                
                // Registration Process Section
                _buildRegistrationProcessSection(invoice, parsed),
                
                // Combined Bank Information Footer
                _buildBankFooterSection(bankWatermarkLogo, trebuchetFont: trebuchetFont, boldItalicFont: boldItalicFont),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // Design Lab variant:
  // Keep current header/footer and redesign only the middle content section.
  Future<Uint8List> generateInvoiceDesignLabSecond(Invoice invoice) async {
    final pdf = pw.Document();

    final logoImage = await _loadLogoImage();
    final logoPdfImage = await _loadLogoAsPdfImage();
    final locationIcon = await _loadIconImage('assets/fonts/address.png');
    final whatsappIcon = await _loadIconImage('assets/fonts/whatsapp.png');
    final facebookIcon = await _loadIconImage('assets/fonts/facebook.png');
    final instagramIcon = await _loadIconImage('assets/fonts/insta.png');
    final xIcon = await _loadIconImage('assets/fonts/x.png');
    final tiktokIcon = await _loadIconImage('assets/fonts/tiktok.png');
    final gmailIcon = await _loadIconImage('assets/fonts/gmail.png') ?? locationIcon;
    final bankWatermarkLogo = await _loadIconImage('assets/logo/logo.png');
    final trebuchetFont = await _loadTrebuchetFont();
    final boldItalicFont = await PdfGoogleFonts.robotoBoldItalic();

    Customer? customer = invoice.customer;
    if (customer == null && invoice.notes.isNotEmpty) {
      customer = _extractCustomerFromNotes(invoice.notes);
    }
    final _ParsedInvoiceNotes parsed = _parseInvoiceNotes(invoice.notes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(8),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.robotoRegular(),
          bold: await PdfGoogleFonts.robotoBold(),
          italic: await PdfGoogleFonts.robotoItalic(),
          boldItalic: await PdfGoogleFonts.robotoBoldItalic(),
        ),
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Keep original top section unchanged
                _buildDocumentTitle(
                  invoice,
                  logoImage,
                  logoPdfImage,
                  locationIcon,
                  whatsappIcon,
                  facebookIcon,
                  instagramIcon,
                  xIcon,
                  tiktokIcon,
                  gmailIcon,
                  hideDocumentMeta: true,
                ),
                // New middle design section
                _buildDesignLabMiddleSection(invoice, customer, parsed),
                // Keep original footer unchanged
                _buildBankFooterSection(bankWatermarkLogo, trebuchetFont: trebuchetFont, boldItalicFont: boldItalicFont),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // Design Lab third variant:
  // Keep current header/footer, middle follows a classic boxed grid style.
  Future<Uint8List> generateInvoiceDesignLabThird(Invoice invoice) async {
    final pdf = pw.Document();

    final logoImage = await _loadLogoImage();
    final logoPdfImage = await _loadLogoAsPdfImage();
    final locationIcon = await _loadIconImage('assets/fonts/address.png');
    final whatsappIcon = await _loadIconImage('assets/fonts/whatsapp.png');
    final facebookIcon = await _loadIconImage('assets/fonts/facebook.png');
    final instagramIcon = await _loadIconImage('assets/fonts/insta.png');
    final xIcon = await _loadIconImage('assets/fonts/x.png');
    final tiktokIcon = await _loadIconImage('assets/fonts/tiktok.png');
    final gmailIcon = await _loadIconImage('assets/fonts/gmail.png') ?? locationIcon;
    final bankWatermarkLogo = await _loadIconImage('assets/logo/logo.png');
    final trebuchetFont = await _loadTrebuchetFont();
    final boldItalicFont = await PdfGoogleFonts.robotoBoldItalic();

    Customer? customer = invoice.customer;
    if (customer == null && invoice.notes.isNotEmpty) {
      customer = _extractCustomerFromNotes(invoice.notes);
    }
    final _ParsedInvoiceNotes parsed = _parseInvoiceNotes(invoice.notes);
    final salesPersonName = await _getSalesPersonName();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(8),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.robotoRegular(),
          bold: await PdfGoogleFonts.robotoBold(),
          italic: await PdfGoogleFonts.robotoItalic(),
          boldItalic: await PdfGoogleFonts.robotoBoldItalic(),
        ),
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildDocumentTitle(
                  invoice,
                  logoImage,
                  logoPdfImage,
                  locationIcon,
                  whatsappIcon,
                  facebookIcon,
                  instagramIcon,
                  xIcon,
                  tiktokIcon,
                  gmailIcon,
                  hideDocumentMeta: true,
                ),
                _buildDesignLabMiddleSectionClassic(invoice, customer, parsed, salesPersonName),
                _buildBankFooterSection(bankWatermarkLogo, trebuchetFont: trebuchetFont, boldItalicFont: boldItalicFont),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // Design Lab fourth variant:
  // Keep current header/footer and show a concise summary of the full tax breakdown.
  Future<Uint8List> generateInvoiceDesignLabSummary(Invoice invoice) async {
    final pdf = pw.Document();

    final logoImage = await _loadLogoImage();
    final logoPdfImage = await _loadLogoAsPdfImage();
    final locationIcon = await _loadIconImage('assets/fonts/address.png');
    final whatsappIcon = await _loadIconImage('assets/fonts/whatsapp.png');
    final facebookIcon = await _loadIconImage('assets/fonts/facebook.png');
    final instagramIcon = await _loadIconImage('assets/fonts/insta.png');
    final xIcon = await _loadIconImage('assets/fonts/x.png');
    final tiktokIcon = await _loadIconImage('assets/fonts/tiktok.png');
    final gmailIcon = await _loadIconImage('assets/fonts/gmail.png') ?? locationIcon;
    final bankWatermarkLogo = await _loadIconImage('assets/logo/logo.png');
    final trebuchetFont = await _loadTrebuchetFont();
    final boldItalicFont = await PdfGoogleFonts.robotoBoldItalic();

    Customer? customer = invoice.customer;
    if (customer == null && invoice.notes.isNotEmpty) {
      customer = _extractCustomerFromNotes(invoice.notes);
    }
    final _ParsedInvoiceNotes parsed = _parseInvoiceNotes(invoice.notes);
    final salesPersonName = await _getSalesPersonName();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(8),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.robotoRegular(),
          bold: await PdfGoogleFonts.robotoBold(),
          italic: await PdfGoogleFonts.robotoItalic(),
          boldItalic: await PdfGoogleFonts.robotoBoldItalic(),
        ),
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildDocumentTitle(
                  invoice,
                  logoImage,
                  logoPdfImage,
                  locationIcon,
                  whatsappIcon,
                  facebookIcon,
                  instagramIcon,
                  xIcon,
                  tiktokIcon,
                  gmailIcon,
                  hideDocumentMeta: true,
                ),
                _buildDesignLabTaxSummarySection(invoice, customer, parsed, salesPersonName),
                _buildBankFooterSection(bankWatermarkLogo, trebuchetFont: trebuchetFont, boldItalicFont: boldItalicFont),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildDesignLabMiddleSection(
    Invoice invoice,
    Customer? customer,
    _ParsedInvoiceNotes parsed,
  ) {
    final invoiceDate = DateFormat('dd MMM yyyy').format(invoice.invoiceDate);
    final dueDate = DateFormat('dd MMM yyyy').format(invoice.dueDate);
    final includePhase2 = _isPhaseTwoIncluded(invoice, parsed);
    final dutyFree = _isDutyFree(invoice, parsed);
    final phase1 = _calculateFirstInstallmentTotal(parsed, invoice);
    final phase2 = _calculateSecondInstallmentTotal(parsed, invoice);
    final grandTotal = phase1 + phase2;
    final cfMombasa = parsed.cfMombasaUsd ?? 0.0;
    final clearance = parsed.clearanceUsd ?? invoice.clearanceFeeUSD;
    final cfKampala = parsed.cfKampalaUsd ?? 0.0;
    final plates = invoice.numberPlatesFee != 0.0 ? invoice.numberPlatesFee : (parsed.plates ?? 0.0);
    final insurance =
        invoice.thirdPartyInsurance != 0.0 ? invoice.thirdPartyInsurance : (parsed.insurance ?? 0.0);
    final agent = invoice.agencyFees != 0.0 ? invoice.agencyFees : (parsed.agent ?? 0.0);
    final taxesUra = dutyFree
        ? (invoice.taxesURA != 0.0 ? invoice.taxesURA : (parsed.taxesUra ?? 0.0))
        : (invoice.taxesURA == 0.0 ? 0.0 : (invoice.taxesURA != 0.0 ? invoice.taxesURA : (parsed.taxesUra ?? 0.0)));

    pw.Widget boxedValue(String label, String value, {bool emphasize = false}) {
      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 4),
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 7),
        decoration: pw.BoxDecoration(
          color: emphasize ? PdfColors.amber100 : PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: PdfColors.grey400, width: 0.7),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: pw.Text(
                label,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              flex: 5,
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  value,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget sectionCard(String title, List<pw.Widget> children) {
      return pw.Container(
        width: 274,
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                title,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ),
            ...children,
          ],
        ),
      );
    }

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 6, bottom: 8),
      child: pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          sectionCard('Invoice + Customer', [
            boxedValue('Invoice Number', invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : 'N/A'),
            boxedValue('Invoice Date', invoiceDate),
            boxedValue('Due Date', dueDate),
            boxedValue('Customer Name', (customer?.name?.isNotEmpty ?? false) ? customer!.name : 'N/A'),
            boxedValue(
              'Customer Phone',
              (customer?.phone?.isNotEmpty ?? false) ? customer!.phone : 'N/A',
            ),
            boxedValue(
              'Customer Email',
              !_isPlaceholderOrEmptyEmail(customer?.email)
                  ? _sanitizeDisplayEmail(customer!.email)
                  : 'N/A',
            ),
            boxedValue('Address', (customer?.address?.isNotEmpty ?? false) ? customer!.address! : 'N/A'),
          ]),
          sectionCard('Vehicle Details', [
            boxedValue('Vehicle', (invoice.vehicleMake.isNotEmpty || invoice.vehicleModel.isNotEmpty) ? '${invoice.vehicleMake} ${_modelForPdf(invoice)}'.trim() : 'N/A'),
            boxedValue('Year', invoice.vehicleYear != 0 ? invoice.vehicleYear.toString() : 'N/A'),
            boxedValue('Engine Size', invoice.engineSize.isNotEmpty ? invoice.engineSize : 'N/A'),
            boxedValue('Fuel Type', invoice.fuelType.isNotEmpty ? invoice.fuelType : 'N/A'),
            boxedValue('Transmission', invoice.transmission.isNotEmpty ? invoice.transmission : 'N/A'),
            boxedValue('Color', invoice.color.isNotEmpty ? invoice.color : 'N/A'),
            boxedValue('Chassis No', invoice.chassisNo.isNotEmpty ? invoice.chassisNo : 'N/A'),
          ]),
          sectionCard('Phase 1 (Upfront)', [
            boxedValue('C&F Mombasa (USD)', _formatMoneyWithDecimals(cfMombasa)),
            boxedValue('Clearance Msa->Kla (USD)', _formatMoneyWithDecimals(clearance)),
            boxedValue('C&F Kampala (USD)', _formatMoneyWithDecimals(cfKampala)),
            boxedValue('Phase 1 Total (UGX)', _formatMoneyWithDecimals(phase1), emphasize: true),
          ]),
          sectionCard('Phase 2 (Settlement)', [
            if (taxesUra > 0) boxedValue(_taxesPayableLabel(invoice, parsed), _formatMoneyWithDecimals(taxesUra)),
            // Only show Number Plates, Insurance, and Agent Fees when Phase 2 is included
            if (includePhase2) ...[
              boxedValue('Number Plates', _formatMoneyWithDecimals(plates)),
              boxedValue('3rd Party Insurance', _formatMoneyWithDecimals(insurance)),
              boxedValue('Agency Fees', _formatMoneyWithDecimals(agent)),
            ],
            boxedValue('Phase 2 Total (UGX)', _formatMoneyWithDecimals(phase2), emphasize: true),
            boxedValue('Grand Total (UGX)', _formatMoneyWithDecimals(grandTotal), emphasize: true),
          ]),
        ],
      ),
    );
  }

  pw.Widget _buildDesignLabMiddleSectionClassic(
    Invoice invoice,
    Customer? customer,
    _ParsedInvoiceNotes parsed,
    String salesPersonName,
  ) {
    final includePhase2 = _isPhaseTwoIncluded(invoice, parsed);
    final dutyFree = _isDutyFree(invoice, parsed);
    final taxesLabel = _taxesSummaryLabel(invoice, parsed);
    final phase1 = _calculateFirstInstallmentTotal(parsed, invoice);
    final phase2 = _calculateSecondInstallmentTotal(parsed, invoice);
    final grandTotal = phase1 + phase2;
    final dateText = DateFormat('MM/dd/yyyy').format(invoice.invoiceDate);
    final dueText = DateFormat('MM/dd/yyyy').format(invoice.dueDate);

    final phase1Rate = parsed.phase1Rate ?? invoice.exchangeRate;
    final cfMombasaUsd = parsed.cfMombasaUsd ?? 0.0;
    final cfMombasaUgx = cfMombasaUsd * phase1Rate;
    final clearanceUsd = parsed.clearanceUsd ?? invoice.clearanceFeeUSD;
    final clearanceUgx = clearanceUsd * phase1Rate;
    final cfKampalaUsd = parsed.cfKampalaUsd ?? 0.0;
    final cfKampalaUgx = cfKampalaUsd * phase1Rate;
    final ttUsd = parsed.ttUsd ?? 40.0;
    final ttUgx = ttUsd * phase1Rate;
    final phase1TotalUsd =
        (cfMombasaUsd > 0 ? cfMombasaUsd : 0.0) +
        (clearanceUsd > 0 ? clearanceUsd : 0.0) +
        (cfKampalaUsd > 0 ? cfKampalaUsd : 0.0) +
        ttUsd;

    // Get base values from invoice or parsed notes.
    var taxesUra = invoice.taxesURA != 0.0 ? invoice.taxesURA : (parsed.taxesUra ?? 0.0);
    if (!dutyFree && invoice.taxesURA == 0.0) taxesUra = 0.0;
    final plates = invoice.numberPlatesFee != 0.0 ? invoice.numberPlatesFee : (parsed.plates ?? 0.0);
    final insurance = invoice.thirdPartyInsurance != 0.0 ? invoice.thirdPartyInsurance : (parsed.insurance ?? 0.0);
    final agent = invoice.agencyFees != 0.0 ? invoice.agencyFees : (parsed.agent ?? 0.0);

    // Classic Grid must not depend solely on notes parsing; derive robust fallbacks
    // from stored invoice fields when parsed rows are missing or stale zeros.
    final cv = (parsed.cv != null && parsed.cv! > 0)
        ? parsed.cv!
        : ((invoice.carPriceUSD > 0 && invoice.exchangeRate > 0) ? (invoice.carPriceUSD * invoice.exchangeRate) : 0.0);

    // Tax breakdown is COMPLETELY INDEPENDENT from Phase 2
    // Always calculate derived values when CV is available (regardless of includePhase2)
    // These will be used as fallbacks if parsed values are missing or zero
    final derivedImportDuty = cv > 0 ? (cv * 0.25) : 0.0;
    var importDuty = (parsed.importDuty != null && parsed.importDuty! > 0)
        ? parsed.importDuty!
        : derivedImportDuty;

    final derivedVat = cv > 0 ? ((cv + importDuty) * 0.18) : 0.0;
    var vat = (parsed.vat != null && parsed.vat! > 0)
        ? parsed.vat!
        : derivedVat;

    final derivedWht = cv > 0 ? ((cv + importDuty) * 0.06) : 0.0;
    var wht = (parsed.wht != null && parsed.wht! > 0)
        ? parsed.wht!
        : derivedWht;

    final derivedInfra = cv > 0 ? (cv * 0.015) : 0.0;
    var infra = (parsed.infra != null && parsed.infra! > 0)
        ? parsed.infra!
        : derivedInfra;

    final derivedIdf = cv > 0 ? (cv * 0.01) : 0.0;
    var idf = (parsed.idf != null && parsed.idf! > 0)
        ? parsed.idf!
        : derivedIdf;

    // Registration Fee, Stamp Duty, and Reg Form have fixed defaults
    final regFee = (parsed.regFee != null && parsed.regFee! > 0) 
        ? parsed.regFee! 
        : 1500000.0;
    final stamp = (parsed.stamp != null && parsed.stamp! > 0) 
        ? parsed.stamp! 
        : 18000.0;
    final regForm = (parsed.regForm != null && parsed.regForm! > 0) 
        ? parsed.regForm! 
        : 35000.0;
    // Excise duty is typically 0 for most vehicles (cars/trucks), so default to 0
    final excise = 0.0;

    // Calculate environmental levy: try parsed first, then residual from taxesUra, then derived
    double env = 0.0;
    if (!dutyFree) {
      if (parsed.envLevy != null && parsed.envLevy! > 0) {
        env = parsed.envLevy!;
      } else if (taxesUra > 0) {
        final calculatedOtherTaxes = importDuty + vat + wht + infra + idf + excise + regFee + stamp + regForm;
        final envFromResidual = taxesUra - calculatedOtherTaxes;
        if (envFromResidual > 0) {
          env = envFromResidual;
        } else if (cv > 0) {
          env = cv * 0.50;
        }
      } else if (cv > 0) {
        env = cv * 0.50;
      }
    }

    // Taxes to URA / Duty fees: only recalculate from components when invoice did not explicitly exclude.
    if (dutyFree) {
      importDuty = vat = wht = env = infra = idf = 0.0;
      taxesUra = invoice.taxesURA != 0.0
          ? invoice.taxesURA
          : (regFee + stamp + regForm);
    } else if (invoice.taxesURA != 0.0 && taxesUra == 0.0) {
      final calculatedTaxesUra = importDuty + vat + wht + env + infra + idf + excise + regFee + stamp + regForm;
      if (calculatedTaxesUra > 0) {
        taxesUra = calculatedTaxesUra;
      }
    }

    // Registration Process = Taxes to URA + Number Plates + Insurance + Agent Fees
    final registrationProcess = includePhase2 ? (taxesUra + plates + insurance + agent) : 0.0;

    // TAX SHEET: Determine based on environmental levy value
    // If environmental levy > 0, it's "with surcharge", otherwise "without surcharge"
    final taxSheet = env > 0 ? 'with surcharge' : 'without surcharge';
    final taxCategory = parsed.vehicleCategory ?? 'N/A';

    final headerGray = PdfColor.fromInt(0xFFE0E0E0); // Monochrome theme - grey headers (#E0E0E0)
    const borderWidth = 1.0; // uniform thin borders throughout
    pw.Widget headerCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: pw.BoxDecoration(
          color: headerGray,
          border: pw.Border.all(color: PdfColors.white, width: 0),
        ),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
        ),
      );
    }

    pw.Widget bodyCell(String text, {pw.TextAlign align = pw.TextAlign.left, double fontSize = 9, bool showBottomBorder = true}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.white, width: 0),
        ),
        child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontSize: fontSize)),
      );
    }

    pw.Widget summaryRow(String label, String value, {bool bold = false}) {
      return pw.Row(
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6, bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.white, width: 0),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                'PROFORMA INVOICE',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
          // Main enclosure: CUSTOMER INFO through PHASE 2 (thick border all sides)
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: borderWidth),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
          // Row: Customer Info and Invoice Details
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 7,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                      decoration: pw.BoxDecoration(
                        color: headerGray,
                        border: pw.Border.all(color: PdfColors.black, width: borderWidth),
                      ),
                      child: pw.Text(
                        'CUSTOMER INFO:',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('NAME: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              pw.Expanded(
                                child: pw.Text(
                                  (customer?.name?.isNotEmpty == true ? customer!.name : 'N/A').toUpperCase(),
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 3),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('ADDRESS: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                              pw.Expanded(
                                child: pw.Text(
                                  ((customer?.address?.isNotEmpty ?? false) ? customer!.address! : 'N/A').toUpperCase(),
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 3),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('PHONE: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                              pw.Expanded(
                                child: pw.Text(
                                  (customer?.phone?.isNotEmpty == true ? customer!.phone : 'N/A').toUpperCase(),
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 2),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('EMAIL: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                              pw.Expanded(
                                child: pw.Text(
                                  !_isPlaceholderOrEmptyEmail(customer?.email) ? _sanitizeDisplayEmail(customer!.email) : 'N/A',
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                      right: pw.BorderSide.none,
                      top: pw.BorderSide.none,
                      bottom: pw.BorderSide.none,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                        decoration: pw.BoxDecoration(
                          color: headerGray,
                          border: pw.Border.all(color: PdfColors.black, width: borderWidth),
                        ),
                        child: pw.Text(
                          'INVOICE DETAILS:',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'DATE              : ',
                                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(
                                  dateText,
                                  style: const pw.TextStyle(fontSize: 10.5),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 6),
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'DUE DATE         : ',
                                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(
                                  dueText,
                                  style: const pw.TextStyle(fontSize: 10.5),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 6),
                            pw.Row(
                              children: [
                                pw.Text(
                                  'INVOICE NUMBER : ',
                                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                                ),
                                pw.Text(
                                  invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : 'N/A',
                                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 6),
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'SALES PERSON   : ',
                                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(
                                  salesPersonName.toUpperCase(),
                                  style: const pw.TextStyle(fontSize: 10.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Spacing between Invoice Details and Description of Goods (line comes from goods table top border)
          pw.SizedBox(height: 2),
          // Merged box: Description of Goods + Phase 1 Breakdown (flush, zero padding)
          pw.Container(
            padding: const pw.EdgeInsets.all(0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Goods table: header + body rows (5 columns); top border = line above DESCRIPTION OF GOODS
                pw.Table(
                  border: pw.TableBorder(
                    top: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                    left: pw.BorderSide.none,
                    right: pw.BorderSide.none,
                    bottom: pw.BorderSide.none,
                    horizontalInside: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                    verticalInside: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(0.8),
                    1: pw.FlexColumnWidth(1.8),
                    2: pw.FlexColumnWidth(5.2),
                    3: pw.FlexColumnWidth(0.8),
                    4: pw.FlexColumnWidth(2.0),
                  },
                  children: [
                    pw.TableRow(children: [
                      headerCell('SNO', align: pw.TextAlign.center),
                      headerCell('CHASSIS NO', align: pw.TextAlign.center),
                      headerCell('DESCRIPTION OF GOODS', align: pw.TextAlign.center),
                      headerCell('QTY', align: pw.TextAlign.center),
                      headerCell('AMOUNT', align: pw.TextAlign.center),
                    ]),
                    pw.TableRow(children: [
                      bodyCell('1', align: pw.TextAlign.center, showBottomBorder: false),
                      bodyCell(invoice.chassisNo.isNotEmpty ? invoice.chassisNo : 'N/A', align: pw.TextAlign.center, showBottomBorder: false),
                      bodyCell(
                        'MAKE: ${invoice.vehicleMake.isNotEmpty ? invoice.vehicleMake : 'N/A'}\n'
                        'MODEL: ${_modelForPdf(invoice)}\n'
                        'YEAR: ${invoice.vehicleYear != 0 ? invoice.vehicleYear : 'N/A'}\n'
                        'Engine: ${invoice.engineSize.isNotEmpty ? invoice.engineSize : 'N/A'}cc\n'
                        'TRANS: ${invoice.transmission.isNotEmpty ? invoice.transmission : 'N/A'}\n'
                        'FUEL: ${invoice.fuelType.isNotEmpty ? invoice.fuelType : 'N/A'}\n'
                        'COLOR: ${invoice.color.isNotEmpty ? invoice.color : 'N/A'}\n'
                        'ORIGIN: ${invoice.countryOfOrigin.isNotEmpty ? invoice.countryOfOrigin : 'N/A'}\n'
                        '${taxesUra > 0 ? 'TAX SHEET: $taxSheet' : ''}',
                        showBottomBorder: false,
                      ),
                      bodyCell('1', align: pw.TextAlign.center, showBottomBorder: false),
                      bodyCell(_formatMoneyWithDecimals(grandTotal), align: pw.TextAlign.center, showBottomBorder: false),
                    ]),
                  ],
                ),
                // Grand Total row: merged SNO+CHASSIS+DESCRIPTION, QTY, AMOUNT (open/hollow, no top/bottom on merged cell)
                pw.Table(
                  border: pw.TableBorder(
                    top: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                    left: pw.BorderSide.none,
                    right: pw.BorderSide.none,
                    bottom: pw.BorderSide.none,
                    horizontalInside: const pw.BorderSide(width: 0),
                    verticalInside: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(7.8),
                    1: pw.FlexColumnWidth(0.8),
                    2: pw.FlexColumnWidth(2.0),
                  },
                  children: [
                    pw.TableRow(children: [
                      pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                          child: pw.Text(
                            'Grand Total',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: pw.Text(
                          '1',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: pw.Text(
                          _formatMoneyWithDecimals(grandTotal),
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ]),
                  ],
                ),
                // Phase 1/Phase 2 table (top border separates from goods table; single line, no double)
                pw.Table(
                  border: pw.TableBorder(
                    top: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                    left: pw.BorderSide.none,
                    right: pw.BorderSide.none,
                    bottom: pw.BorderSide.none,
                    horizontalInside: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                    verticalInside: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1),
                    1: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        headerCell('PHASE 1 BREAKDOWN', align: pw.TextAlign.center),
                        headerCell(taxesUra > 0 ? 'PHASE 2 / REGISTRATION BREAKDOWN' : 'PHASE 2', align: pw.TextAlign.center),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Table(
                                border: pw.TableBorder(
                                  top: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                  bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                  verticalInside: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                ),
                                columnWidths: const {
                                  0: pw.FlexColumnWidth(2),
                                  1: pw.FlexColumnWidth(1),
                                  2: pw.FlexColumnWidth(1),
                                },
                                children: [
                        pw.TableRow(
                          children: [
                            pw.SizedBox(height: 5),
                            pw.SizedBox(height: 5),
                            pw.SizedBox(height: 5),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.SizedBox(),
                            pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                '(USD)',
                                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                '(UGX)',
                                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        if (cfMombasaUsd > 0)
                          pw.TableRow(
                            children: [
                              pw.Text(
                                'C&F Mombasa',
                                style: pw.TextStyle(fontSize: 8.5),
                              ),
                              pw.Align(
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  _formatMoneyWithDecimals(cfMombasaUsd),
                                  style: pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                              pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  _formatMoneyWithDecimals(cfMombasaUgx),
                                  style: pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                            ],
                          ),
                        if (clearanceUsd > 0)
                          pw.TableRow(
                            children: [
                              pw.Text(
                                'Clearance',
                                style: pw.TextStyle(fontSize: 8.5),
                              ),
                              pw.Align(
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  _formatMoneyWithDecimals(clearanceUsd),
                                  style: pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                              pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  _formatMoneyWithDecimals(clearanceUgx),
                                  style: pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                            ],
                          ),
                        if (cfKampalaUsd > 0)
                          pw.TableRow(
                            children: [
                              pw.Text(
                                'C&F Kampala',
                                style: pw.TextStyle(fontSize: 8.5),
                              ),
                              pw.Align(
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  _formatMoneyWithDecimals(cfKampalaUsd),
                                  style: pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                              pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  _formatMoneyWithDecimals(cfKampalaUgx),
                                  style: pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                            ],
                          ),
                        pw.TableRow(
                          children: [
                            pw.Text(
                              'TT',
                              style: pw.TextStyle(fontSize: 8.5),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                _formatMoneyWithDecimals(ttUsd),
                                style: pw.TextStyle(fontSize: 8.5),
                              ),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                _formatMoneyWithDecimals(ttUgx),
                                style: pw.TextStyle(fontSize: 8.5),
                              ),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Text(
                              'Rate',
                              style: pw.TextStyle(fontSize: 8.5),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                _formatMoneyWithDecimals(phase1Rate),
                                style: pw.TextStyle(fontSize: 8.5),
                              ),
                            ),
                            pw.SizedBox(),
                            pw.SizedBox(),
                          ],
                        ),
                        // Bold horizontal line above Phase 1 Total (top of equal-sign effect)
                        pw.TableRow(
                          children: [
                            pw.Container(
                              width: double.infinity,
                              height: 4,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                ),
                              ),
                            ),
                            pw.Container(
                              width: double.infinity,
                              height: 4,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                ),
                              ),
                            ),
                            pw.Container(
                              width: double.infinity,
                              height: 4,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Text(
                              'Phase 1 Total',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                _formatMoneyWithDecimals(phase1TotalUsd),
                                style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                _formatMoneyWithDecimals(phase1),
                                style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Bold horizontal line below Phase 1 Total (bottom of equal-sign effect)
                        pw.TableRow(
                          children: [
                            pw.Container(
                              width: double.infinity,
                              height: 2,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                ),
                              ),
                            ),
                            pw.Container(
                              width: double.infinity,
                              height: 2,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                ),
                              ),
                            ),
                            pw.Container(
                              width: double.infinity,
                              height: 2,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                ),
                              ),
                            ),
                          ],
                        ),
                                ],
                              ),
                            pw.SizedBox(height: 42),
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            if (taxesUra > 0) ...[
                              if (!dutyFree) ...[
                              summaryRow('CV', _formatMoneyWithDecimals(cv)),
                              summaryRow('Import Duty', _formatMoneyWithDecimals(importDuty)),
                              summaryRow('VAT', _formatMoneyWithDecimals(vat)),
                              summaryRow('WHT', _formatMoneyWithDecimals(wht)),
                              summaryRow('Environmental Levy', _formatMoneyWithDecimals(env)),
                              summaryRow('Infrastructure Levy', _formatMoneyWithDecimals(infra)),
                              summaryRow('IDF', _formatMoneyWithDecimals(idf)),
                              ],
                              summaryRow('Registration Fee', _formatMoneyWithDecimals(regFee)),
                              summaryRow('Stamp Duty', _formatMoneyWithDecimals(stamp)),
                              summaryRow('Reg Form', _formatMoneyWithDecimals(regForm)),
                              summaryRow(taxesLabel, _formatMoneyWithDecimals(taxesUra)),
                            ],
                            // Only show Number Plates, Insurance, and Agent Fees when Phase 2 is included
                            if (includePhase2) ...[
                              summaryRow('Number Plates', _formatMoneyWithDecimals(plates)),
                              summaryRow('3rd Party Insurance', _formatMoneyWithDecimals(insurance)),
                              summaryRow('Agency Fees', _formatMoneyWithDecimals(agent)),
                            ],
                            if (taxesUra > 0 || includePhase2) pw.Divider(color: PdfColors.grey500),
                            summaryRow('Registration Process', _formatMoneyWithDecimals(registrationProcess), bold: true),
                            summaryRow('Phase 1 Total', _formatMoneyWithDecimals(phase1), bold: true),
                            summaryRow('Tax Category', taxCategory),
                            summaryRow('Grand Total (UGX)', _formatMoneyWithDecimals(grandTotal), bold: true),
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 6),
                              child: pw.Text(
                                _amountInWordsUgx(grandTotal),
                                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                                maxLines: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        ],
      ),
      ),
    ],
  ),
    );
  }

  pw.Widget _buildDesignLabTaxSummarySection(
    Invoice invoice,
    Customer? customer,
    _ParsedInvoiceNotes parsed,
    String salesPersonName,
  ) {
    final includePhase2 = _isPhaseTwoIncluded(invoice, parsed);
    final dutyFree = _isDutyFree(invoice, parsed);
    final taxesLabel = _taxesSummaryLabel(invoice, parsed);
    
    // Calculate Phase 1 breakdown values (EXACT same as Classic Grid)
    final phase1Rate = parsed.phase1Rate ?? invoice.exchangeRate;
    final cfMombasaUsd = parsed.cfMombasaUsd ?? 0.0;
    final cfMombasaUgx = cfMombasaUsd * phase1Rate;
    final clearanceUsd = parsed.clearanceUsd ?? invoice.clearanceFeeUSD;
    final clearanceUgx = clearanceUsd * phase1Rate;
    final cfKampalaUsd = parsed.cfKampalaUsd ?? 0.0;
    final cfKampalaUgx = cfKampalaUsd * phase1Rate;
    final ttUsd = parsed.ttUsd ?? 40.0;
    final ttUgx = ttUsd * phase1Rate;
    final phase1TotalUsd =
        (cfMombasaUsd > 0 ? cfMombasaUsd : 0.0) +
        (clearanceUsd > 0 ? clearanceUsd : 0.0) +
        (cfKampalaUsd > 0 ? cfKampalaUsd : 0.0) +
        ttUsd;
    
    // Use stored values from invoice instead of recalculating
    final phase1 = invoice.firstInstallmentUGX > 0 
        ? invoice.firstInstallmentUGX 
        : _calculateFirstInstallmentTotal(parsed, invoice);
    final dateText = DateFormat('MM/dd/yyyy').format(invoice.invoiceDate);
    final dueText = DateFormat('MM/dd/yyyy').format(invoice.dueDate);

    // Prefer stored/parsed values, but older invoices may not have URA values saved when Phase 2 was excluded.
    // In that case, derive a consistent fallback from CIF (carPriceUSD), exchangeRate, vehicleYear, and invoiceDate
    // (same formula used in Invoice Details screen).
    double cv = (parsed.cv != null && parsed.cv! > 0)
        ? parsed.cv!
        : ((invoice.carPriceUSD > 0 && invoice.exchangeRate > 0) ? (invoice.carPriceUSD * invoice.exchangeRate) : 0.0);

    double importDuty = parsed.importDuty ?? 0.0;
    double vat = parsed.vat ?? 0.0;
    double wht = parsed.wht ?? 0.0;
    double infra = parsed.infra ?? 0.0;
    double idf = parsed.idf ?? 0.0;
    double regFee = parsed.regFee ?? 0.0;
    double stamp = parsed.stamp ?? 0.0;
    double regForm = parsed.regForm ?? 0.0;
    double envLevy = parsed.envLevy ?? 0.0;

    // Derive component fallbacks when missing/zero (tax breakdown is independent of Phase 2).
    if (cv > 0) {
      if (importDuty <= 0) importDuty = cv * 0.25;
      if (vat <= 0) vat = (cv + importDuty) * 0.18;
      if (wht <= 0) wht = cv * 0.06;
      if (infra <= 0) infra = cv * 0.015;
      if (idf <= 0) idf = cv * 0.01;
      if (regFee <= 0) regFee = 1500000.0;
      if (stamp <= 0) stamp = 18000.0;
      if (regForm <= 0) regForm = 35000.0;
      if (envLevy <= 0) {
        // Environmental levy applies when vehicle is 10+ years older than invoice year (same logic as Invoice Details).
        final cutoffYear = invoice.invoiceDate.year - 10;
        final applicable = invoice.vehicleYear > 0 && invoice.vehicleYear <= cutoffYear;
        envLevy = applicable ? (cv * 0.50) : 0.0;
      }
    }

    // When invoice.taxesURA == 0 the user chose "Include tax to URA" = false; duty-free still has fees.
    double taxesUra = invoice.taxesURA != 0.0 ? invoice.taxesURA : (parsed.taxesUra ?? 0.0);
    if (dutyFree) {
      if (taxesUra <= 0) taxesUra = regFee + stamp + regForm;
      importDuty = vat = wht = envLevy = infra = idf = 0.0;
    } else if (invoice.taxesURA == 0.0) {
      taxesUra = 0.0;
    } else if (taxesUra <= 0 && cv > 0) {
      taxesUra = importDuty + vat + wht + envLevy + infra + idf + regFee + stamp + regForm;
    }
    
    // TAX SHEET: Determine based on environmental levy value
    // If environmental levy > 0, it's "with surcharge", otherwise "without surcharge"
    final taxSheet = envLevy > 0 ? 'with surcharge' : 'without surcharge';
    final numberPlates = invoice.numberPlatesFee != 0.0 ? invoice.numberPlatesFee : (parsed.plates ?? 0.0);
    final insurance =
        invoice.thirdPartyInsurance != 0.0 ? invoice.thirdPartyInsurance : (parsed.insurance ?? 0.0);
    final agentFees = invoice.agencyFees != 0.0 ? invoice.agencyFees : (parsed.agent ?? 0.0);
    // Registration Process = Taxes to URA (independent) + Phase 2 extras (plates, insurance, agent fees)
    // Even when Phase 2 is NOT included, Taxes to URA must still be counted uniquely.
    // So:
    // - If Phase 2 = No  → registrationProcess = taxesUra
    // - If Phase 2 = Yes → registrationProcess = taxesUra + plates + insurance + agentFees
    final registrationProcess = includePhase2
        ? (parsed.registrationProcess ?? (taxesUra + numberPlates + insurance + agentFees))
        : taxesUra;

    // For display consistency in the summary block:
    // - Phase 2 Total should show ONLY the extras when Phase 2 = Yes
    // - When Phase 2 = No, Phase 2 Total should be 0 (no extras), but Taxes to URA is still shown separately
    final phase2Extras = includePhase2 ? (numberPlates + insurance + agentFees) : 0.0;

    // Grand Total is ALWAYS:
    //   Phase 1 Total + Taxes to URA + Phase 2 extras (if included)
    final phase2 = taxesUra + phase2Extras;
    final grandTotal = phase1 + taxesUra + phase2Extras;

    final headerGray = PdfColor.fromInt(0xFFE0E0E0); // Monochrome theme - grey headers (#E0E0E0)
    const borderWidth = 1.0; // uniform thin borders throughout
    pw.Widget headerCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: pw.BoxDecoration(
          color: headerGray,
          border: pw.Border.all(color: PdfColors.white, width: 0),
        ),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
        ),
      );
    }

    pw.Widget bodyCell(String text, {pw.TextAlign align = pw.TextAlign.left, double fontSize = 9, bool showBottomBorder = true}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.white, width: 0),
        ),
        child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontSize: fontSize)),
      );
    }

    pw.Widget summaryLine(String label, String value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget summaryRow(String label, String value, {bool bold = false}) {
      return pw.Row(
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 6, bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.white, width: 0),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                'PROFORMA INVOICE',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
          // Main enclosure: CUSTOMER INFO through PHASE 2 (thick border all sides)
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: borderWidth),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 7,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                      decoration: pw.BoxDecoration(
                        color: headerGray,
                        border: pw.Border.all(color: PdfColors.black, width: borderWidth),
                      ),
                      child: pw.Text(
                        'CUSTOMER INFO:',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('NAME: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              pw.Expanded(
                                child: pw.Text(
                                  (customer?.name?.isNotEmpty == true ? customer!.name : 'N/A').toUpperCase(),
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 3),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('ADDRESS: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                              pw.Expanded(
                                child: pw.Text(
                                  ((customer?.address?.isNotEmpty ?? false) ? customer!.address! : 'N/A').toUpperCase(),
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 3),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('PHONE: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                              pw.Expanded(
                                child: pw.Text(
                                  (customer?.phone?.isNotEmpty == true ? customer!.phone : 'N/A').toUpperCase(),
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 2),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('EMAIL: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                              pw.Expanded(
                                child: pw.Text(
                                  !_isPlaceholderOrEmptyEmail(customer?.email) ? _sanitizeDisplayEmail(customer!.email) : 'N/A',
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                      right: pw.BorderSide.none,
                      top: pw.BorderSide.none,
                      bottom: pw.BorderSide.none,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                        decoration: pw.BoxDecoration(
                          color: headerGray,
                          border: pw.Border.all(color: PdfColors.black, width: borderWidth),
                        ),
                        child: pw.Text(
                          'INVOICE DETAILS:',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'DATE              : ',
                                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(
                                  dateText,
                                  style: const pw.TextStyle(fontSize: 10.5),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 6),
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'DUE DATE         : ',
                                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(
                                  dueText,
                                  style: const pw.TextStyle(fontSize: 10.5),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 6),
                            pw.Row(
                              children: [
                                pw.Text(
                                  'INVOICE NUMBER : ',
                                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                                ),
                                pw.Text(
                                  invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : 'N/A',
                                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 6),
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'SALES PERSON   : ',
                                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(
                                  salesPersonName.toUpperCase(),
                                  style: const pw.TextStyle(fontSize: 10.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Spacing between Invoice Details and Description of Goods (line comes from goods table top border)
          pw.SizedBox(height: 2),
          // Merged box: Description of Goods + Phase 1 Breakdown (flush, zero padding)
          pw.Container(
            padding: const pw.EdgeInsets.all(0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Goods table: header + body rows (5 columns); top border = line above DESCRIPTION OF GOODS
                pw.Table(
                  border: pw.TableBorder(
                    top: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                    left: pw.BorderSide.none,
                    right: pw.BorderSide.none,
                    bottom: pw.BorderSide.none,
                    horizontalInside: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                    verticalInside: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(0.8),
                    1: pw.FlexColumnWidth(1.8),
                    2: pw.FlexColumnWidth(5.2),
                    3: pw.FlexColumnWidth(0.8),
                    4: pw.FlexColumnWidth(2.0),
                  },
                  children: [
                    pw.TableRow(children: [
                      headerCell('SNO', align: pw.TextAlign.center),
                      headerCell('CHASSIS NO', align: pw.TextAlign.center),
                      headerCell('DESCRIPTION OF GOODS', align: pw.TextAlign.center),
                      headerCell('QTY', align: pw.TextAlign.center),
                      headerCell('AMOUNT', align: pw.TextAlign.center),
                    ]),
                    pw.TableRow(children: [
                      bodyCell('1', align: pw.TextAlign.center, showBottomBorder: false),
                      bodyCell(invoice.chassisNo.isNotEmpty ? invoice.chassisNo : 'N/A', align: pw.TextAlign.center, showBottomBorder: false),
                      bodyCell(
                        'MAKE: ${invoice.vehicleMake.isNotEmpty ? invoice.vehicleMake : 'N/A'}\n'
                        'MODEL: ${_modelForPdf(invoice)}\n'
                        'YEAR: ${invoice.vehicleYear != 0 ? invoice.vehicleYear : 'N/A'}\n'
                        'Engine: ${invoice.engineSize.isNotEmpty ? invoice.engineSize : 'N/A'}cc\n'
                        'TRANS: ${invoice.transmission.isNotEmpty ? invoice.transmission : 'N/A'}\n'
                        'FUEL: ${invoice.fuelType.isNotEmpty ? invoice.fuelType : 'N/A'}\n'
                        'COLOR: ${invoice.color.isNotEmpty ? invoice.color : 'N/A'}\n'
                        'ORIGIN: ${invoice.countryOfOrigin.isNotEmpty ? invoice.countryOfOrigin : 'N/A'}\n'
                        '${taxesUra > 0 ? 'TAX SHEET: $taxSheet' : ''}',
                        showBottomBorder: false,
                      ),
                      bodyCell('1', align: pw.TextAlign.center, showBottomBorder: false),
                      bodyCell(_formatMoneyWithDecimals(grandTotal), align: pw.TextAlign.center, showBottomBorder: false),
                    ]),
                  ],
                ),
                // Grand Total row: merged SNO+CHASSIS+DESCRIPTION, QTY, AMOUNT (open/hollow, no top/bottom on merged cell)
                pw.Table(
                  border: pw.TableBorder(
                    top: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                    left: pw.BorderSide.none,
                    right: pw.BorderSide.none,
                    bottom: pw.BorderSide.none,
                    horizontalInside: const pw.BorderSide(width: 0),
                    verticalInside: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(7.8),
                    1: pw.FlexColumnWidth(0.8),
                    2: pw.FlexColumnWidth(2.0),
                  },
                  children: [
                    pw.TableRow(children: [
                      pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                          child: pw.Text(
                            'Grand Total',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: pw.Text(
                          '1',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: pw.Text(
                          _formatMoneyWithDecimals(grandTotal),
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ]),
                  ],
                ),
                // Phase 1/Phase 2 table (top border separates from goods table; single line, no double)
                pw.Table(
                  border: pw.TableBorder(
                    top: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                    left: pw.BorderSide.none,
                    right: pw.BorderSide.none,
                    bottom: pw.BorderSide.none,
                    horizontalInside: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                    verticalInside: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1),
                    1: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        headerCell('PHASE 1 BREAKDOWN', align: pw.TextAlign.center),
                        headerCell(taxesUra > 0 ? 'PHASE 2 / REGISTRATION BREAKDOWN' : 'PHASE 2', align: pw.TextAlign.center),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Table(
                      border: pw.TableBorder(
                        top: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                        bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                        verticalInside: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                      ),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2),
                        1: pw.FlexColumnWidth(1),
                        2: pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.SizedBox(height: 5),
                            pw.SizedBox(height: 5),
                            pw.SizedBox(height: 5),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.SizedBox(),
                            pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                '(USD)',
                                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                '(UGX)',
                                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        if (cfMombasaUsd > 0)
                          pw.TableRow(
                            children: [
                              pw.Text(
                                'C&F Mombasa',
                                style: pw.TextStyle(fontSize: 8.5),
                              ),
                              pw.Align(
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  _formatMoneyWithDecimals(cfMombasaUsd),
                                  style: pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                              pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  _formatMoneyWithDecimals(cfMombasaUgx),
                                  style: pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                            ],
                          ),
                        if (clearanceUsd > 0)
                          pw.TableRow(
                            children: [
                              pw.Text(
                                'Clearance',
                                style: pw.TextStyle(fontSize: 8.5),
                              ),
                              pw.Align(
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  _formatMoneyWithDecimals(clearanceUsd),
                                  style: pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                              pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  _formatMoneyWithDecimals(clearanceUgx),
                                  style: pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                            ],
                          ),
                        if (cfKampalaUsd > 0)
                          pw.TableRow(
                            children: [
                              pw.Text(
                                'C&F Kampala',
                                style: pw.TextStyle(fontSize: 8.5),
                              ),
                              pw.Align(
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  _formatMoneyWithDecimals(cfKampalaUsd),
                                  style: pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                              pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  _formatMoneyWithDecimals(cfKampalaUgx),
                                  style: pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                            ],
                          ),
                        pw.TableRow(
                          children: [
                            pw.Text(
                              'TT',
                              style: pw.TextStyle(fontSize: 8.5),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                _formatMoneyWithDecimals(ttUsd),
                                style: pw.TextStyle(fontSize: 8.5),
                              ),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                _formatMoneyWithDecimals(ttUgx),
                                style: pw.TextStyle(fontSize: 8.5),
                              ),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 2),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Dollar Rate (${_formatMoneyWithDecimals(phase1Rate)})',
                                    style: pw.TextStyle(fontSize: 8.5),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(),
                            pw.SizedBox(),
                          ],
                        ),
                        // Bold horizontal line above Phase 1 Total (top of equal-sign effect)
                        pw.TableRow(
                          children: [
                            pw.Container(
                              width: double.infinity,
                              height: 4,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                ),
                              ),
                            ),
                            pw.Container(
                              width: double.infinity,
                              height: 4,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                ),
                              ),
                            ),
                            pw.Container(
                              width: double.infinity,
                              height: 4,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Text(
                              'Phase 1 Total',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                _formatMoneyWithDecimals(phase1TotalUsd),
                                style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                _formatMoneyWithDecimals(phase1),
                                style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Bold horizontal line below Phase 1 Total (bottom of equal-sign effect)
                        pw.TableRow(
                          children: [
                            pw.Container(
                              width: double.infinity,
                              height: 2,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                ),
                              ),
                            ),
                            pw.Container(
                              width: double.infinity,
                              height: 2,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                ),
                              ),
                            ),
                            pw.Container(
                              width: double.infinity,
                              height: 2,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 42),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        if (taxesUra > 0) summaryRow(taxesLabel, _formatMoneyWithDecimals(taxesUra)),
                        // Only show Number Plates, Insurance, and Agent Fees when Phase 2 is included
                        if (includePhase2) ...[
                          summaryRow('Number Plates', _formatMoneyWithDecimals(numberPlates)),
                          summaryRow('3rd Party Insurance', _formatMoneyWithDecimals(insurance)),
                          summaryRow('Agency Fees', _formatMoneyWithDecimals(agentFees)),
                        ],
                        if (taxesUra > 0 || includePhase2) pw.Divider(color: PdfColors.grey500),
                        // Registration Process = Taxes to URA + Phase 2 extras (if any)
                        summaryRow('Registration Process', _formatMoneyWithDecimals(registrationProcess), bold: true),
                        // Phase 2 Total shows ONLY the extras (plates, insurance, agent fees) when Phase 2 is Yes
                        summaryRow('Phase 1 Total', _formatMoneyWithDecimals(phase1), bold: true),
                        pw.Divider(color: PdfColors.grey500),
                        // Grand Total = Phase 1 Total + Taxes to URA + Phase 2 extras (if any)
                        summaryRow('Grand Total (UGX)', _formatMoneyWithDecimals(grandTotal), bold: true),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 6),
                          child: pw.Text(
                            _amountInWordsUgx(grandTotal),
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
        ),
        ],
      ),
      ),
    ],
  ),
    );
  }

  // Save PDF to file (Downloads when available; filename: NSBmotors INV_<number>)
  Future<String> savePDFToFile(Invoice invoice) async {
    final pdfBytes = await generateInvoicePDF(invoice);
    Directory directory;
    try {
      final downloads = await getDownloadsDirectory();
      directory = downloads ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      directory = await getApplicationDocumentsDirectory();
    }
    final fileName = 'NSBmotors_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  // Print PDF
  Future<void> printPDF(Invoice invoice) async {
    final pdfBytes = await generateInvoicePDF(invoice);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${invoice.invoiceNumber}',
      format: PdfPageFormat.a4,
      dynamicLayout: false,
    );
  }

  // Generate demand letter PDF
  Future<Uint8List> generateDemandLetterPDF({
    required Invoice invoice,
    required Customer customer,
    required DemandLetter letter,
  }) async {
    final pdf = pw.Document();

    final logoImage = await _loadLogoImage();
    final logoPdfImage = await _loadLogoAsPdfImage();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.robotoRegular(),
          bold: await PdfGoogleFonts.robotoBold(),
          italic: await PdfGoogleFonts.robotoItalic(),
          boldItalic: await PdfGoogleFonts.robotoBoldItalic(),
        ),
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildDemandLetterHeader(logoImage, logoPdfImage, letter),
                pw.SizedBox(height: 12),
                _buildDemandLetterMeta(invoice, customer, letter),
                pw.SizedBox(height: 18),
                _buildDemandLetterBody(letter),
                pw.Spacer(),
                _buildDemandLetterFooter(),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // Save demand letter PDF (Downloads when available)
  Future<String> saveDemandLetterPDFToFile({
    required Invoice invoice,
    required Customer customer,
    required DemandLetter letter,
  }) async {
    final pdfBytes = await generateDemandLetterPDF(
      invoice: invoice,
      customer: customer,
      letter: letter,
    );
    Directory directory;
    try {
      final downloads = await getDownloadsDirectory();
      directory = downloads ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      directory = await getApplicationDocumentsDirectory();
    }
    final fileName = 'NSBmotors Demand_${letter.letterNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  // Print demand letter PDF
  Future<void> printDemandLetterPDF({
    required Invoice invoice,
    required Customer customer,
    required DemandLetter letter,
  }) async {
    final pdfBytes = await generateDemandLetterPDF(
      invoice: invoice,
      customer: customer,
      letter: letter,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Demand_${letter.letterNumber}',
      format: PdfPageFormat.a4,
      dynamicLayout: false,
    );
  }

  // ===== Demand letter widgets =====
  pw.Widget _buildDemandLetterHeader(Uint8List logoImage, pw.ImageProvider? logoPdfImage, DemandLetter letter) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(children: [
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            child: logoImage.isNotEmpty
                ? pw.Image(pw.MemoryImage(logoImage), fit: pw.BoxFit.contain)
                : pw.Center(
                    child: pw.Text(
                      'LOGO',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue600,
                      ),
                    ),
                  ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('ENICK SALES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.Text('Demand Letter', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
          ]),
        ]),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.red50,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.red300, width: 1),
          ),
          child: pw.Text(
            letter.statusText,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDemandLetterMeta(Invoice invoice, Customer customer, DemandLetter letter) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey50,
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('To:', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text(customer.name.isNotEmpty ? customer.name : 'N/A', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Phone: ${customer.phone.isNotEmpty ? customer.phone : 'N/A'}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Email: ${!_isPlaceholderOrEmptyEmail(customer.email) ? _sanitizeDisplayEmail(customer.email) : 'N/A'}', style: const pw.TextStyle(fontSize: 10)),
            ]),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Letter No.: ${letter.letterNumber}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Issue Date: ${_formatDate(letter.issueDate)}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Due Date: ${_formatDate(letter.dueDate)}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Invoice: ${invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : 'N/A'}', style: const pw.TextStyle(fontSize: 10)),
            ]),
          ),
        ]),
        pw.SizedBox(height: 10),
        pw.Container(height: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Row(children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Amount Due', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text('UGX ${_formatMoney(invoice.balanceAmount)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ]),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Days Overdue', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text('${letter.daysOverdue}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  pw.Widget _buildDemandLetterBody(DemandLetter letter) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(letter.subject, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 12),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
        ),
        child: pw.Text(
          letter.content,
          style: const pw.TextStyle(fontSize: 11, height: 1.4),
        ),
      ),
      if (letter.notes.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.Text('Notes', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.Text(letter.notes, style: const pw.TextStyle(fontSize: 10)),
      ],
    ]);
  }

  pw.Widget _buildDemandLetterFooter() {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.SizedBox(height: 16),
      pw.Container(height: 1, color: PdfColors.grey300),
      pw.SizedBox(height: 8),
      pw.Text(
        'Please treat this matter with urgency. If you have already made the payment, kindly disregard this notice.',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        'Enick Sales • Kampala, Uganda • +256 704 440 740',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
    ]);
  }

  // Build header with logo and company info
  pw.Widget _buildHeader(Invoice invoice, Uint8List logoImage) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo section
        pw.Container(
          width: 80,
          height: 80,
      decoration: pw.BoxDecoration(
            color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
          ),
          child: logoImage.isNotEmpty 
            ? pw.Image(
                pw.MemoryImage(logoImage),
                fit: pw.BoxFit.contain,
              )
            : pw.Center(
                child: pw.Text(
                  'NSB\nLOGO',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
        ),
        pw.SizedBox(width: 20),
        // Company details
        pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
                'NSB BUSINESS SOLUTIONS (U) LTD',
            style: pw.TextStyle(
                  fontSize: 18,
              fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.Text(
                'People. Product. Growth.',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'P.O. Box 119831, Kampala, Uganda',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.black,
                ),
              ),
              pw.Text(
                'Kama Kama Plaza, Suite No. 3F-11',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.black,
                ),
              ),
              pw.Text(
                '+256 784 836253 / +256 752 13404',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.black,
                ),
              ),
          pw.Text(
                'nsbsolutions@gmail.com',
            style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.black,
            ),
          ),
          pw.Text(
                'nsb motors ug',
            style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.black,
            ),
          ),
        ],
      ),
        ),
        // Quotation badge
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: pw.BoxDecoration(
            color: PdfColors.blue600,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
                'QUOTATION',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
                'DATE: ${_formatDate(invoice.invoiceDate)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build customer and vehicle details in two columns
  pw.Widget _buildCustomerVehicleDetails(Customer? customer, Invoice invoice, _ParsedInvoiceNotes parsed) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
        // Left column - Labels
        pw.Container(
          width: 200,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Customer Name:',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Customer Contacts:',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Customer Email:',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Stock No.:',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Make:',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Chassis No.:',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Color:',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Engine Size / Fuel type:',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Year:',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
        ),
        // Right column - Values from actual invoice data
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                (customer?.name?.isNotEmpty == true) ? customer!.name : 'N/A',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                (customer?.phone?.isNotEmpty == true) ? customer!.phone : 'N/A',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                !_isPlaceholderOrEmptyEmail(customer?.email) ? _sanitizeDisplayEmail(customer!.email) : 'N/A',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.stockNo.isNotEmpty ? invoice.stockNo : 'N/A',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                (invoice.vehicleMake.isNotEmpty || invoice.vehicleModel.isNotEmpty) ? '${invoice.vehicleMake} ${_modelForPdf(invoice)}'.trim() : 'N/A',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.chassisNo.isNotEmpty ? invoice.chassisNo : 'N/A',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.color.isNotEmpty ? invoice.color.toUpperCase() : 'N/A',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${invoice.engineSize.isNotEmpty ? invoice.engineSize : (parsed.engineCc != null ? parsed.engineCc.toString() : 'N/A')}cc / ${invoice.fuelType.isNotEmpty ? invoice.fuelType : (parsed.fuelType?.isNotEmpty == true ? parsed.fuelType! : 'N/A')}',
            style: pw.TextStyle(
              fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
              pw.SizedBox(height: 8),
              pw.Text(
                (invoice.vehicleYear != 0 ? invoice.vehicleYear.toString() : (parsed.year != null ? parsed.year.toString() : 'N/A')),
            style: pw.TextStyle(
              fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
              if ((parsed.serialNumber ?? '').isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'S/N: ${parsed.serialNumber}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
              if (parsed.tonnage != null) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Tonnage: ${parsed.tonnage}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
        ],
      ),
        ),
      ],
    );
  }

  // Build first installment section with actual invoice data
  pw.Widget _buildFirstInstallment(Invoice invoice, [_ParsedInvoiceNotes? parsedOpt]) {
    final parsed = parsedOpt ?? _ParsedInvoiceNotes();
    // Use persisted firstInstallmentUGX as source of truth; fallback to parsed Phase 1 total
    final firstInstallmentUgx = invoice.firstInstallmentUGX != 0.0
        ? invoice.firstInstallmentUGX
        : (parsed.phase1TotalUgx ?? 0.0);
    // TT info (optional)
    final ttUsd = parsed.ttUsd ?? 40.0;
    final rate = parsed.phase1Rate ?? invoice.exchangeRate;
    final ttUgx = ttUsd * rate;
    
    // Determine which options are selected based on parsed values
    final hasCfMombasa = parsed.cfMombasaUsd != null && parsed.cfMombasaUsd! > 0;
    final hasClearance = parsed.clearanceUsd != null && parsed.clearanceUsd! > 0;
    final hasCfKampala = parsed.cfKampalaUsd != null && parsed.cfKampalaUsd! > 0;
    
    // Legacy support: check phase1Mode if individual values not available
    final phase1Mode = parsed.phase1Mode ?? '';
    final hasCfMombasaLegacy = !hasCfMombasa && phase1Mode.contains('C&F Mombasa');
    final hasClearanceLegacy = !hasClearance && phase1Mode.contains('Clearance');
    final hasCfKampalaLegacy = !hasCfKampala && phase1Mode.contains('C&F Kampala');
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'FIRST INSTALLMENT',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 10),
          // Table header
          pw.Container(
          padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            border: pw.Border.all(color: PdfColors.grey400, width: 1),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                flex: 2,
                  child: pw.Text(
                  '',
                    style: pw.TextStyle(
                    fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'COST IN USD',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                  'USD RATE',
                    style: pw.TextStyle(
                    fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                  ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                  'COST IN UGX',
                    style: pw.TextStyle(
                    fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // C&F Mombasa row (show only if selected)
        if (hasCfMombasa || hasCfMombasaLegacy)
          _buildTableRow(
            'C&F Mombasa',
            hasCfMombasa ? _formatMoney(parsed.cfMombasaUsd!) : '',
            _formatMoneyWithDecimals(rate),
            hasCfMombasa ? 'Ush ${_formatMoney(parsed.cfMombasaUsd! * rate)}' : '-',
          ),
        // Clearance Mombasa-Kampala row (show only if selected)
        if (hasClearance || hasClearanceLegacy)
          _buildTableRow(
            'Clearance Mombasa-Kampala',
            hasClearance ? _formatMoney(parsed.clearanceUsd!) : '',
            _formatMoneyWithDecimals(rate),
            hasClearance ? 'Ush ${_formatMoney(parsed.clearanceUsd! * rate)}' : '-',
          ),
        // C&F Kampala row (show only if selected)
        if (hasCfKampala || hasCfKampalaLegacy)
          _buildTableRow(
            'C&F Kampala',
            hasCfKampala ? _formatMoney(parsed.cfKampalaUsd!) : (hasCfKampalaLegacy ? _formatMoney(invoice.carPriceUSD) : ''),
            _formatMoneyWithDecimals(rate),
            hasCfKampala ? 'Ush ${_formatMoney(parsed.cfKampalaUsd! * rate)}' : (hasCfKampalaLegacy && firstInstallmentUgx > 0 ? 'Ush ${_formatMoney(firstInstallmentUgx)}' : '-'),
          ),
        // TT Charges row (always shown)
        _buildTableRow(
          'TT Charges',
          _formatMoney(ttUsd),
          _formatMoneyWithDecimals(rate),
          'Ush ${_formatMoney(ttUgx)}',
        ),
        // Total row - show the persisted/fallback first installment total
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 1),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'First Installment Total',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text('', style: pw.TextStyle(fontSize: 11)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text('', style: pw.TextStyle(fontSize: 11)),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                  'Ush ${_formatMoney(firstInstallmentUgx)}',
                    style: pw.TextStyle(
                    fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build second installment section with actual invoice data
  pw.Widget _buildSecondInstallment(Invoice invoice, _ParsedInvoiceNotes parsed) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SECOND INSTALLMENT',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 10),
        if (invoice.taxesURA > 0)
          _buildSecondInstallmentRow(_taxesPayableLabel(invoice, parsed), _formatMoneyWithDecimals(invoice.taxesURA != 0.0 ? invoice.taxesURA : (parsed.taxesUra ?? 0.0))),
        _buildSecondInstallmentRow('Number plates', _formatMoney(invoice.numberPlatesFee != 0.0 ? invoice.numberPlatesFee : (parsed.plates ?? 0.0))),
        _buildSecondInstallmentRow('3rd Party Insurance', ((invoice.thirdPartyInsurance != 0.0 ? invoice.thirdPartyInsurance : (parsed.insurance ?? 0.0)) > 0) ? _formatMoney(invoice.thirdPartyInsurance != 0.0 ? invoice.thirdPartyInsurance : (parsed.insurance ?? 0.0)) : ''),
        _buildSecondInstallmentRow('Agent fees', _formatMoney(invoice.agencyFees != 0.0 ? invoice.agencyFees : (parsed.agent ?? 0.0))),
      ],
    );
  }

  // Build registration process section with actual invoice data
  pw.Widget _buildRegistrationProcess(Invoice invoice, _ParsedInvoiceNotes parsed) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Text(
              'REGISTRATION PROCESS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.Spacer(),
            pw.Text(
              _formatMoneyWithDecimals(parsed.registrationProcess ?? 2667300.0),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.yellow100,
            border: pw.Border.all(color: PdfColors.grey400, width: 1),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                'GRAND TOTAL (UGX)',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.Spacer(),
              pw.Text(
              _formatMoneyWithDecimals(invoice.totalAmount != 0.0 ? invoice.totalAmount : ((invoice.firstInstallmentUGX != 0.0 ? invoice.firstInstallmentUGX : (parsed.phase1TotalUgx ?? 0.0)) + (invoice.secondInstallmentUGX != 0.0 ? invoice.secondInstallmentUGX : (parsed.secondInstallment ?? 0.0)))),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build bank information section
  pw.Widget _buildBankInformation() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Bank information',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 10),
        _buildBankInfoRow('Payee:', 'NSB BUSINESS SOLUTIONS (U) LTD'),
        _buildBankInfoRow('Bank Name:', 'EQUITY BANK.'),
        _buildBankInfoRow('Bank address:', 'EQUITY BANK, CHURCH HOUSE, GF, KAMPALA RD'),
        _buildBankInfoRow('Bank Code:', '30'),
        _buildBankInfoRow('Branch Code:', '1001'),
        _buildBankInfoRow('SWIFT CODE:', 'EQBLUGKA'),
        _buildBankInfoRow('Account No:', ''),
        pw.SizedBox(height: 5),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Ugx: 1001202951908',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'USD: 1001203004471',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build footer
  pw.Widget _buildFooter() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.black,
      ),
      child: pw.Text(
        '.... Business & Logistics Partner',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          fontStyle: pw.FontStyle.italic,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Helper methods
  pw.Widget _buildTableRow(String label, String costUsd, String usdRate, String costUgx) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                costUsd,
                style: pw.TextStyle(fontSize: 11),
              ),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                usdRate,
                style: pw.TextStyle(fontSize: 11),
              ),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                costUgx,
                style: pw.TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSecondInstallmentRow(String label, String value) {
    return pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.black,
            ),
          ),
        pw.Spacer(),
          pw.Container(
            width: 140,
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildBankInfoRow(String label, String value) {
    return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.black,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.black,
              ),
            ),
          ),
        ],
    );
  }

  // Load company logo image from assets
  Future<Uint8List> _loadLogoImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/logo/logo.png');
      final imageData = data.buffer.asUint8List();
      
      // Decode the PNG image to ensure it's valid
      final decodedImage = img.decodePng(imageData);
      if (decodedImage != null) {
        print('Logo loaded and decoded successfully: ${imageData.length} bytes');
        return imageData;
      } else {
        print('Failed to decode PNG image');
        return Uint8List(0);
      }
    } catch (e) {
      print('Error loading logo from assets: $e');
      return Uint8List(0);
    }
  }

  // Load logo as PDF image
  Future<pw.ImageProvider?> _loadLogoAsPdfImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/logo/logo.png');
      final imageData = data.buffer.asUint8List();
      
      // Decode the PNG image to ensure it's valid
      final decodedImage = img.decodePng(imageData);
      if (decodedImage != null) {
        print('Logo loaded as PDF image successfully: ${imageData.length} bytes');
        return pw.MemoryImage(imageData);
      } else {
        print('Failed to decode PNG image for PDF');
        return null;
      }
    } catch (e) {
      print('Error loading logo as PDF image: $e');
      return null;
    }
  }

  // Extract customer information from notes field
  Customer? _extractCustomerFromNotes(String notes) {
    try {
      final lines = notes.split('\n');
      String? name, email, phone, address;
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.startsWith('Name:')) {
          name = trimmedLine.substring(5).trim();
        } else if (trimmedLine.startsWith('Email:')) {
          String value = trimmedLine.substring(6).trim();
          // Avoid including " Phone: +number" or similar if same line
          final phonePart = value.toLowerCase().indexOf(' phone:');
          if (phonePart > 0) value = value.substring(0, phonePart).trim();
          // Strip trailing phone number (e.g. +1771497302956) if concatenated to email
          final trailingPhone = RegExp(r'\+?\d{10,}$').firstMatch(value);
          if (trailingPhone != null && value.contains('@')) {
            value = value.substring(0, trailingPhone.start).trim();
          }
          // Strip "+digits" before @ (e.g. nsbbsolutions+1771497030716@gmail.com -> nsbbsolutions@gmail.com)
          if (value.contains('@')) {
            value = value.replaceAll(RegExp(r'\+\d{10,}(?=@)'), '');
          }
          email = value;
        } else if (trimmedLine.startsWith('Phone:')) {
          String value = trimmedLine.substring(6).trim();
          // Avoid including " Email: ..." if same line
          final emailPart = value.toLowerCase().indexOf(' email:');
          if (emailPart > 0) value = value.substring(0, emailPart).trim();
          phone = value;
        } else if (trimmedLine.startsWith('Address:')) {
          address = trimmedLine.substring(8).trim();
        }
      }
      
      if (name != null && name.isNotEmpty) {
        return Customer(
          id: 0, // Temporary ID
          name: name,
          email: email ?? '',
          phone: phone ?? '',
          address: address ?? '',
          company: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error extracting customer from notes: $e');
    }
    return null;
  }

  /// True if email is null, empty, or a known placeholder (e.g. noemail@customer.local).
  bool _isPlaceholderOrEmptyEmail(String? email) {
    if (email == null || email.trim().isEmpty) return true;
    final lower = email.trim().toLowerCase();
    return lower == 'noemail@customer.local' ||
        lower.contains('noemail@') ||
        (lower.contains('noemail') && lower.contains('customer.local'));
  }

  /// Model string for PDF: base model + suffix with a space only (no slash).
  String _modelForPdf(Invoice invoice) {
    if (invoice.vehicleModel.trim().isEmpty) return 'N/A';
    final suffix = invoice.vehicleModelSuffix.trim();
    return suffix.isEmpty ? invoice.vehicleModel : '${invoice.vehicleModel} $suffix'.trim();
  }

  /// Removes "+digits" before @ (e.g. nsbbsolutions+1771497030716@gmail.com -> nsbbsolutions@gmail.com).
  String _sanitizeDisplayEmail(String? email) {
    if (email == null || email.isEmpty) return email ?? '';
    if (!email.contains('@')) return email;
    return email.replaceAll(RegExp(r'\+\d{10,}(?=@)'), '');
  }

  // Load Trebuchet MS (prefer italic) for Business & Logistics Partner (distinctive 'g' and '&')
  Future<pw.Font?> _loadTrebuchetFont() async {
    try {
      // Prefer explicit italic face if available (more visible right slant)
      final data = await rootBundle.load('assets/fonts/trebucit.ttf');
      return pw.Font.ttf(data);
    } catch (_) {
      try {
        // Fallback to regular Trebuchet if italic asset is missing
        final data = await rootBundle.load('assets/fonts/trebuc.ttf');
        return pw.Font.ttf(data);
      } catch (_) {
        // Final fallback: use a Google italic font so the line still slants
        return PdfGoogleFonts.cabinItalic();
      }
    }
  }

  // Parse invoice notes for additional details used as fallbacks
  bool _isDutyFree(Invoice invoice, _ParsedInvoiceNotes parsed) {
    if (invoice.dutyFree) return true;
    if (parsed.dutyFree == true) return true;
    return invoice.notes.toLowerCase().contains('duty free: yes');
  }

  String _taxesSummaryLabel(Invoice invoice, _ParsedInvoiceNotes parsed) {
    return _isDutyFree(invoice, parsed) ? 'Duty fees' : 'Taxes to URA';
  }

  String _taxesPayableLabel(Invoice invoice, _ParsedInvoiceNotes parsed) {
    return _isDutyFree(invoice, parsed) ? 'Duty fees' : 'Taxes Payable to URA';
  }

  _ParsedInvoiceNotes _parseInvoiceNotes(String notes) {
    final parsed = _ParsedInvoiceNotes();
    if (notes.isEmpty) return parsed;
    final lines = notes.split('\n').map((e) => e.trim()).toList();

    for (final line in lines) {
      final normalizedLine = line.toLowerCase();
      if (line.startsWith('Description:')) {
        final sn = RegExp(r'S/N:\s*([^\]]+)').firstMatch(line)?.group(1);
        if (sn != null) parsed.serialNumber = sn.trim();
      } else if (line.startsWith('Make:')) {
        parsed.make = line.substring(5).trim();
      } else if (line.startsWith('Model:')) {
        parsed.model = line.substring(6).trim();
      } else if (line.startsWith('Year:')) {
        parsed.year = int.tryParse(line.substring(5).trim());
      } else if (line.startsWith('Engine:')) {
        final cc = RegExp(r'(\d+)').firstMatch(line)?.group(1);
        parsed.engineCc = int.tryParse(cc ?? '');
      } else if (line.startsWith('Tonnage:')) {
        parsed.tonnage = double.tryParse(line.substring(8).trim());
      } else if (line.startsWith('TT Charges:')) {
        parsed.ttUsd = double.tryParse(line.substring(11).trim());
      } else if (line.startsWith('Phase 1 Total:')) {
        parsed.phase1TotalUgx = _tryParseMoney(line.substring(14));
      } else if (line.startsWith('C&F Mombasa:')) {
        if (!line.contains('Not selected')) {
          parsed.cfMombasaUsd = _tryParseMoney(line.substring(13));
          parsed.phase1Mode = 'C&F Mombasa'; // Legacy support
        }
      } else if (line.startsWith('C&F Kampala:')) {
        if (!line.contains('Not selected')) {
          parsed.cfKampalaUsd = _tryParseMoney(line.substring(13));
          parsed.phase1Mode = 'C&F Kampala'; // Legacy support
        }
      } else if (line.startsWith('Clearance Msa→Kla:')) {
        if (!line.contains('Not selected')) {
          parsed.clearanceUsd = _tryParseMoney(line.substring(19));
          parsed.phase1Mode = 'Clearance'; // Legacy support
        }
      } else if (line.startsWith('Phase 1 Selected Options:')) {
        // Parse the selected options string (e.g., "C&F Mombasa, Clearance")
        final optionsStr = line.substring(26).trim();
        if (optionsStr.isNotEmpty && optionsStr != 'None') {
          // The individual values are already parsed from the individual lines above
          // This is just for reference
          parsed.phase1Mode = optionsStr; // Store all options
        }
      } else if (line.startsWith('Phase 1 Mode:')) {
        parsed.phase1Mode = line.substring(14).trim();
      } else if (line.startsWith('Phase 1 Rate:')) {
        parsed.phase1Rate = _tryParseMoney(line.substring(13));
      } else if (line.startsWith('Phase 2 Included:')) {
        parsed.includePhase2 = line.substring(17).trim().toLowerCase() == 'yes';
      } else if (line.startsWith('Duty Free:')) {
        parsed.dutyFree = line.substring(10).trim().toLowerCase() == 'yes';
      } else if (line.startsWith('URA Taxes:')) {
        parsed.taxesUra = _tryParseMoney(line.substring(10));
      } else if (line.startsWith('Number Plates:')) {
        parsed.plates = _tryParseMoney(line.substring(14));
      } else if (line.startsWith('3rd Party Insurance:')) {
        parsed.insurance = _tryParseMoney(line.substring(20));
      } else if (line.startsWith('Agency Fees:')) {
        parsed.agent = _tryParseMoney(line.substring(12));
      } else if (line.startsWith('Registration Process:')) {
        parsed.registrationProcess = _tryParseMoney(line.substring(21));
      } else if (normalizedLine.startsWith('customs value')) {
        parsed.cv = _tryParseMoney(line.split(':').last);
      } else if (normalizedLine.startsWith('import declaration')) {
        parsed.idf = _tryParseMoney(line.split(':').last);
      } else if (normalizedLine.startsWith('import duty')) {
        parsed.importDuty = _tryParseMoney(line.split(':').last);
      } else if (normalizedLine.startsWith('vat')) {
        parsed.vat = _tryParseMoney(line.split(':').last);
      } else if (normalizedLine.startsWith('withholding tax') || normalizedLine.startsWith('wht')) {
        parsed.wht = _tryParseMoney(line.split(':').last);
      } else if (normalizedLine.startsWith('environmental levy')) {
        parsed.envLevy = _tryParseMoney(line.split(':').last);
      } else if (normalizedLine.startsWith('infrastructure levy')) {
        parsed.infra = _tryParseMoney(line.split(':').last);
      } else if (normalizedLine.startsWith('registration fee')) {
        parsed.regFee = _tryParseMoney(line.split(':').last);
      } else if (normalizedLine.startsWith('stamp duty')) {
        parsed.stamp = _tryParseMoney(line.split(':').last);
      } else if (normalizedLine.startsWith('reg form')) {
        parsed.regForm = _tryParseMoney(line.split(':').last);
      } else if (normalizedLine.startsWith('sheet used:')) {
        parsed.sheetUsed = line.substring(11).trim();
      } else if (normalizedLine.startsWith('vehicle category:')) {
        parsed.vehicleCategory = line.substring(17).trim();
      }
    }

    if (parsed.secondInstallment == null && parsed.taxesUra != null) {
      // Align with new definition: Registration Process = URA + Plates + Insurance + Agent
      parsed.registrationProcess = (parsed.taxesUra ?? 0) + (parsed.plates ?? 0) + (parsed.insurance ?? 0) + (parsed.agent ?? 0);
      parsed.secondInstallment = parsed.registrationProcess;
    }

    // Override sheetUsed based on actual environmental levy: if > 0, "with surcharge", else "without surcharge"
    if (parsed.envLevy != null && parsed.envLevy! > 0) {
      parsed.sheetUsed = 'with surcharge';
    } else if (parsed.envLevy != null && parsed.envLevy! == 0) {
      parsed.sheetUsed = 'without surcharge';
    }
    // If envLevy is null, keep the parsed sheetUsed value as-is

    return parsed;
  }

  double? _tryParseMoney(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9\.-]'), '');
    return double.tryParse(cleaned);
  }

  // Format date helper
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day}th -${months[date.month - 1]}, ${date.year}';
  }

  // Shared number short formatter for PDF values (e.g., K, M)
  String _fmtNum(num n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
  
  // Format money with commas (no decimals)
  String _formatMoney(num amount) {
    return NumberFormat('#,##0').format(amount);
  }
  
  // Format money with commas and 2 decimals
  String _formatMoneyWithDecimals(num amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  /// Converts a number to words for display (e.g. "One million five hundred thousand").
  /// [amount] is rounded to integer for the words; decimals can be appended separately.
  String _numberToWords(num amount) {
    const ones = [
      '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
      'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen',
      'seventeen', 'eighteen', 'nineteen',
    ];
    const tens = [
      '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety',
    ];
    int n = amount.round().abs();
    if (n == 0) return 'zero';
    String word(int v) {
      if (v == 0) return '';
      if (v < 20) return ones[v];
      if (v < 100) return '${tens[v ~/ 10]}${v % 10 != 0 ? ' ${ones[v % 10]}' : ''}';
      if (v < 1000) {
        final h = v ~/ 100;
        final r = v % 100;
        return '${ones[h]} hundred${r != 0 ? ' ${word(r)}' : ''}';
      }
      if (v < 1000000) {
        final th = v ~/ 1000;
        final r = v % 1000;
        return '${word(th)} thousand${r != 0 ? ' ${word(r)}' : ''}';
      }
      if (v < 1000000000) {
        final m = v ~/ 1000000;
        final r = v % 1000000;
        return '${word(m)} million${r != 0 ? ' ${word(r)}' : ''}';
      }
      final b = v ~/ 1000000000;
      final r = v % 1000000000;
      return '${word(b)} billion${r != 0 ? ' ${word(r)}' : ''}';
    }
    final s = word(n);
    return s.isEmpty ? 'zero' : '${s[0].toUpperCase()}${s.substring(1)}';
  }

  String _amountInWordsUgx(num amount) {
    final whole = amount.round();
    final words = _numberToWords(whole);
    return '$words only';
  }

  String _amountInWordsUsd(num amount) {
    final whole = amount.floor();
    final cents = (amount * 100).round() % 100;
    final words = _numberToWords(whole);
    if (cents == 0) {
      return '$words US dollars only';
    }
    return '$words US dollars and $cents/100';
  }

  // Load icon image as PDF image
  Future<pw.ImageProvider?> _loadIconImage(String path) async {
    try {
      final imageData = await rootBundle.load(path);
      final decodedImage = img.decodePng(imageData.buffer.asUint8List());
      if (decodedImage != null) {
        return pw.MemoryImage(imageData.buffer.asUint8List());
      }
      return null;
    } catch (e) {
      print('Error loading icon $path: $e');
      return null;
    }
  }

  // Get dynamic colors based on invoice data
  Map<String, PdfColor> _getDynamicColors(Invoice invoice) {
    // Use invoice number or other data to generate consistent colors
    final hash = invoice.invoiceNumber.hashCode;
    final colors = [
      PdfColors.blue,
      PdfColors.green,
      PdfColors.orange,
      PdfColors.purple,
      PdfColors.red,
      PdfColors.teal,
    ];
    
    return {
      'primary': colors[hash.abs() % colors.length],
      'secondary': colors[(hash + 1).abs() % colors.length],
      'accent': colors[(hash + 2).abs() % colors.length],
    };
  }

  // Build social media icon using PNG images
  pw.Widget _buildSocialIcon(String platform, pw.ImageProvider? locationIcon, pw.ImageProvider? whatsappIcon, pw.ImageProvider? facebookIcon, pw.ImageProvider? instagramIcon, pw.ImageProvider? xIcon, pw.ImageProvider? tiktokIcon, pw.ImageProvider? gmailIcon) {
    pw.ImageProvider? iconImage;
    
    switch (platform.toLowerCase()) {
      case 'location':
        iconImage = locationIcon;
        break;
      case 'whatsapp':
        iconImage = whatsappIcon;
        break;
      case 'instagram':
        iconImage = instagramIcon;
        break;
      case 'x':
      case 'twitter':
        iconImage = xIcon;
        break;
      case 'facebook':
        iconImage = facebookIcon;
        break;
      case 'tiktok':
        iconImage = tiktokIcon;
        break;
      case 'gmail':
      case 'email':
        iconImage = gmailIcon;
        break;
      default:
        iconImage = null;
    }

    // Always return a consistent-sized container for proper alignment
    return pw.Container(
      width: 14,
      height: 14,
      padding: pw.EdgeInsets.all(1),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: iconImage != null
          ? pw.Image(
              iconImage,
              fit: pw.BoxFit.contain,
            )
          : pw.SizedBox.shrink(),
    );
  }

  // Build document title section with company header
  pw.Widget _buildDocumentTitle(
    Invoice invoice,
    Uint8List logoImage,
    pw.ImageProvider? logoPdfImage,
    pw.ImageProvider? locationIcon,
    pw.ImageProvider? whatsappIcon,
    pw.ImageProvider? facebookIcon,
    pw.ImageProvider? instagramIcon,
    pw.ImageProvider? xIcon,
    pw.ImageProvider? tiktokIcon,
    pw.ImageProvider? gmailIcon, {
    bool hideDocumentMeta = false,
  }) {
    print('Building document title with logo: ${logoImage.length} bytes');
    final colors = _getDynamicColors(invoice);
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: pw.Column(
        children: [
          // Company Header Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo Section (Left) - expanded to fill available space
              pw.Container(
                width: 160,
                child: (logoPdfImage != null)
                    ? pw.Container(
                        width: 140,
                        height: 70,
                        alignment: pw.Alignment.topLeft,
                        child: pw.Image(
                          logoPdfImage,
                          fit: pw.BoxFit.contain,
                        ),
                      )
                    : pw.Container(
                        width: 140,
                        height: 70,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green600,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'NSB',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ),
              ),
              
              // First Golden Line Separator
              pw.Container(
                width: 2,
                height: 70,
                color: PdfColor.fromInt(0xFFD4AF37), // Golden color
              ),
              
              // Address Section (Middle) with location icon
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Location icon above address (centered, larger size)
                    if (locationIcon != null)
                      pw.Container(
                        width: 24,
                        height: 24,
                        padding: pw.EdgeInsets.all(1),
                        child: pw.Image(
                          locationIcon,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    pw.SizedBox(height: 1),
                    // Address text (centered)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'P.O. Box 110833, Kampala - Uganda',
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'Kamu Kamu Plaza, Suite No. SF-31',
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Second Golden Line Separator
              pw.Container(
                width: 2,
                height: 70,
                color: PdfColor.fromInt(0xFFD4AF37), // Golden color
              ),
              
              // Contact Section (Right) - each method on its own line
              pw.Container(
                width: 200,
                padding: const pw.EdgeInsets.symmetric(horizontal: 20.0),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    // Phone row
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.SizedBox(
                          width: 14,
                          height: 14,
                          child: pw.Center(
                            child: _buildSocialIcon('whatsapp', locationIcon, whatsappIcon, facebookIcon, instagramIcon, xIcon, tiktokIcon, gmailIcon),
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Flexible(
                          child: pw.Text(
                            '+256 394 836253 / +256 752 128406',
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.black),
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8.0),
                    // Email row
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.SizedBox(
                          width: 14,
                          height: 14,
                          child: pw.Center(
                            child: _buildSocialIcon('gmail', locationIcon, whatsappIcon, facebookIcon, instagramIcon, xIcon, tiktokIcon, gmailIcon),
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Flexible(
                          child: pw.Text(
                            'nsbbsolutions@gmail.com',
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.black, fontStyle: pw.FontStyle.italic),
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8.0),
                    // Social Media row
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.SizedBox(
                          width: 14,
                          height: 14,
                          child: pw.Center(
                            child: _buildSocialIcon('facebook', locationIcon, whatsappIcon, facebookIcon, instagramIcon, xIcon, tiktokIcon, gmailIcon),
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.SizedBox(
                          width: 14,
                          height: 14,
                          child: pw.Center(
                            child: _buildSocialIcon('x', locationIcon, whatsappIcon, facebookIcon, instagramIcon, xIcon, tiktokIcon, gmailIcon),
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.SizedBox(
                          width: 14,
                          height: 14,
                          child: pw.Center(
                            child: _buildSocialIcon('tiktok', locationIcon, whatsappIcon, facebookIcon, instagramIcon, xIcon, tiktokIcon, gmailIcon),
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.SizedBox(
                          width: 14,
                          height: 14,
                          child: pw.Center(
                            child: _buildSocialIcon('instagram', locationIcon, whatsappIcon, facebookIcon, instagramIcon, xIcon, tiktokIcon, gmailIcon),
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text(
                          'nsb motors ug',
                          style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                          textAlign: pw.TextAlign.left,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Horizontal Line
          pw.SizedBox(height: 2),
          pw.Container(
            height: 1,
            color: PdfColors.grey400,
          ),
          pw.SizedBox(height: 2),
          
          if (!hideDocumentMeta) ...[
            // Document Title Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'QUOTATION',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.Text(
                  'DATE : ${_formatDate(invoice.invoiceDate)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
            // Invoice Number (Centered)
            pw.SizedBox(height: 1),
            pw.Center(
              child: pw.Text(
                'Invoice No: ${invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : 'N/A'}',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build customer information section
  pw.Widget _buildCustomerInformation(Customer? customer) {
    // Use table for proper alignment
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Table(
        columnWidths: {
          0: pw.FlexColumnWidth(1.5), // Label column
          1: pw.FlexColumnWidth(3.5), // Value column
        },
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  'Customer Name',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  (customer?.name?.isNotEmpty == true) ? customer!.name : 'N/A',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  'Customer Contacts',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  (customer?.phone?.isNotEmpty == true) ? customer!.phone : 'N/A',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  'Customer Email',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  !_isPlaceholderOrEmptyEmail(customer?.email) ? _sanitizeDisplayEmail(customer!.email) : 'N/A',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.blue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build vehicle details section
  pw.Widget _buildVehicleDetails(Invoice invoice) {
    // Use table for proper alignment
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Table(
        columnWidths: {
          0: pw.FlexColumnWidth(1.5), // Label column
          1: pw.FlexColumnWidth(3.5), // Value column
        },
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  'Stock No.',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  invoice.stockNo.isNotEmpty ? invoice.stockNo : 'N/A',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  'Make',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  invoice.vehicleMake.isNotEmpty ? invoice.vehicleMake : 'N/A',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  'Chassis No.',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  invoice.chassisNo.isNotEmpty ? invoice.chassisNo : 'N/A',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  'Color',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  invoice.color.isNotEmpty ? invoice.color.toUpperCase() : 'N/A',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  'Engine Size / Fuel type',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  '${invoice.engineSize.isNotEmpty ? invoice.engineSize : 'N/A'}cc / ${invoice.fuelType.isNotEmpty ? invoice.fuelType : 'N/A'}',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  'Year',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  invoice.vehicleYear != 0 ? invoice.vehicleYear.toString() : 'N/A',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build first installment table
  pw.Widget _buildFirstInstallmentTable(Invoice invoice, _ParsedInvoiceNotes parsed) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'FIRST INSTALLMENT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black),
            columnWidths: {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(3),
            },
            children: [
              // Header row
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('DESCRIPTION', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('COST IN USD', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('USD RATE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('COST IN UGX', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              // Show separate rows for each selected option (can be 1 or 2)
              ..._buildFirstInstallmentOptionRows(parsed, invoice),
              // TT Charges row (use parsed value or default to 40)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('TT Charges', style: pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text(_formatMoney(parsed.ttUsd ?? 40.0), style: pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text(_formatMoneyWithDecimals(parsed.phase1Rate ?? invoice.exchangeRate), style: pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text(_formatMoney((parsed.ttUsd ?? 40.0) * (parsed.phase1Rate ?? invoice.exchangeRate)), style: pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              // Total row
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text(
                      _formatMoney(_calculateFirstInstallmentTotal(parsed, invoice)),
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper: Build rows for all selected Phase 1 options (can be 1 or 2)
  List<pw.TableRow> _buildFirstInstallmentOptionRows(_ParsedInvoiceNotes parsed, Invoice invoice) {
    final List<pw.TableRow> rows = [];
    final double rate = parsed.phase1Rate ?? invoice.exchangeRate;
    
    // Determine which options are selected based on parsed values
    final hasCfMombasa = parsed.cfMombasaUsd != null && parsed.cfMombasaUsd! > 0;
    final hasClearance = parsed.clearanceUsd != null && parsed.clearanceUsd! > 0;
    final hasCfKampala = parsed.cfKampalaUsd != null && parsed.cfKampalaUsd! > 0;
    
    // Legacy support: check phase1Mode if individual values not available
    final phase1Mode = parsed.phase1Mode ?? '';
    final hasCfMombasaLegacy = !hasCfMombasa && phase1Mode.contains('C&F Mombasa');
    final hasClearanceLegacy = !hasClearance && phase1Mode.contains('Clearance');
    final hasCfKampalaLegacy = !hasCfKampala && phase1Mode.contains('C&F Kampala');
    
    // C&F Mombasa row
    if (hasCfMombasa || hasCfMombasaLegacy) {
      final cfMombasaUsd = hasCfMombasa ? parsed.cfMombasaUsd! : 0.0;
      final cfMombasaUgx = cfMombasaUsd * rate;
      rows.add(_buildOptionRow('C&F Mombasa', cfMombasaUsd, rate, cfMombasaUgx));
    }
    
    // Clearance row
    if (hasClearance || hasClearanceLegacy) {
      final clearanceUsd = hasClearance ? parsed.clearanceUsd! : 0.0;
      final clearanceUgx = clearanceUsd * rate;
      rows.add(_buildOptionRow('Clearance Mombasa-Kampala', clearanceUsd, rate, clearanceUgx));
    }
    
    // C&F Kampala row
    if (hasCfKampala || hasCfKampalaLegacy) {
      final cfKampalaUsd = hasCfKampala ? parsed.cfKampalaUsd! : (hasCfKampalaLegacy ? invoice.carPriceUSD : 0.0);
      final cfKampalaUgx = cfKampalaUsd * rate;
      rows.add(_buildOptionRow('C&F Kampala', cfKampalaUsd, rate, cfKampalaUgx));
    }
    
    // If no rows were added (legacy case), add a fallback row
    if (rows.isEmpty) {
      final String mode = (parsed.phase1Mode ?? '').trim();
      final String description =
          mode == 'C&F Mombasa' ? 'C&F Mombasa'
        : mode == 'Clearance'   ? 'Clearance Mombasa-Kampala'
                                : 'C&F Kampala';
      final double ttUgx = 40.0 * rate;
      final double totalPhase1Ugx = invoice.firstInstallmentUGX != 0.0
          ? invoice.firstInstallmentUGX
          : (parsed.phase1TotalUgx ?? ttUgx);
      final double pathUgx = (totalPhase1Ugx - ttUgx).clamp(0, double.infinity);
      final double pathUsd = rate == 0 ? 0 : pathUgx / rate;
      rows.add(_buildOptionRow(description, pathUsd, rate, pathUgx));
    }
    
    return rows;
  }
  
  // Helper: Build a single option row
  pw.TableRow _buildOptionRow(String description, double usdAmount, double rate, double ugxAmount) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(4),
          child: pw.Text(description, style: pw.TextStyle(fontSize: 10)),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(4),
          child: pw.Text(_formatMoney(usdAmount), style: pw.TextStyle(fontSize: 10)),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(4),
          child: pw.Text(_formatMoneyWithDecimals(rate), style: pw.TextStyle(fontSize: 10)),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(4),
          child: pw.Text(_formatMoney(ugxAmount), style: pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  // Calculate first installment total = Selected path UGX + TT UGX (matches invoice)
  double _calculateFirstInstallmentTotal(_ParsedInvoiceNotes parsed, Invoice invoice) {
    final rate = parsed.phase1Rate ?? invoice.exchangeRate;
    const ttUsd = 40.0;
    final ttUgx = ttUsd * rate;
    if (invoice.firstInstallmentUGX != 0.0) return invoice.firstInstallmentUGX;
  if (parsed.phase1TotalUgx != null && parsed.phase1TotalUgx! > 0) {
    // Treat Phase 1 Total from notes as the full first installment total (no extra TT addition)
    return parsed.phase1TotalUgx!;
  }
  // Fallback: only TT known
  return ttUgx;
  }

  // Build second installment table
  pw.Widget _buildSecondInstallmentTable(Invoice invoice, _ParsedInvoiceNotes parsed) {
    if (!_isPhaseTwoIncluded(invoice, parsed)) {
      return pw.SizedBox.shrink();
    }

    // Resolve dynamic amounts (prefer explicit invoice fields, fallback to parsed notes, else 0)
    final double uraTaxes = (invoice.taxesURA != 0.0)
        ? invoice.taxesURA
        : (parsed.taxesUra ?? 0.0);
    final double numberPlates = (invoice.numberPlatesFee != 0.0)
        ? invoice.numberPlatesFee
        : (parsed.plates ?? 0.0);
    final double insurance = (invoice.thirdPartyInsurance != 0.0)
        ? invoice.thirdPartyInsurance
        : (parsed.insurance ?? 0.0);
    final double agentFees = (invoice.agencyFees != 0.0)
        ? invoice.agencyFees
        : (parsed.agent ?? 0.0);
    // Registration Process is defined as: URA Taxes + Number Plates + Insurance + Agent Fees
    final double registrationProcess = uraTaxes + numberPlates + insurance + agentFees;

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SECOND INSTALLMENT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black),
            columnWidths: {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              // Header row
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('DESCRIPTION', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('AMOUNT (UGX)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              // Data rows
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text(_taxesPayableLabel(invoice, parsed), style: pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text(_formatMoney(uraTaxes), style: pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              // Intentionally omit a mid-section Registration Process row to avoid duplication;
              // only show the bold Registration Process total at the bottom of this section.
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('Number Plates', style: pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text(_formatMoney(numberPlates), style: pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('3rd Party Insurance', style: pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text(_formatMoney(insurance), style: pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('Agency Fees', style: pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text(_formatMoney(agentFees), style: pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              // Omit Registration Process total here to avoid repeating totals; shown in Grand Total Summary
            ],
          ),
        ],
      ),
    );
  }


  // Calculate second installment total (now defined as Registration Process)
  double _calculateSecondInstallmentTotal(_ParsedInvoiceNotes parsed, Invoice invoice) {
    if (!_isPhaseTwoIncluded(invoice, parsed)) {
      return 0.0;
    }

    // Dynamic totals: prefer invoice fields, fallback to parsed notes, else 0
    final double uraTaxes = (invoice.taxesURA != 0.0)
        ? invoice.taxesURA
        : (parsed.taxesUra ?? 0.0);
    final double numberPlates = (invoice.numberPlatesFee != 0.0)
        ? invoice.numberPlatesFee
        : (parsed.plates ?? 0.0);
    final double insurance = (invoice.thirdPartyInsurance != 0.0)
        ? invoice.thirdPartyInsurance
        : (parsed.insurance ?? 0.0);
    final double agentFees = (invoice.agencyFees != 0.0)
        ? invoice.agencyFees
        : (parsed.agent ?? 0.0);
    // Registration Process = URA + Plates + Insurance + Agent Fees
    final double registrationProcess = uraTaxes + numberPlates + insurance + agentFees;

    return registrationProcess;
  }


  // Build registration process section
  pw.Widget _buildRegistrationProcessSection(Invoice invoice, _ParsedInvoiceNotes parsed) {
    print('=== REGISTRATION PROCESS SECTION BEING BUILT ==='); // Debug print
    final includePhase2 = _isPhaseTwoIncluded(invoice, parsed);
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GRAND TOTAL SUMMARY',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black),
            columnWidths: {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              // Header row
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('COMPONENT', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('AMOUNT (UGX)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              // Data rows
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('First Installment', style: pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text(_formatMoney(_calculateFirstInstallmentTotal(parsed, invoice)), style: pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              if (includePhase2)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(4),
                      child: pw.Text('Registration Process', style: pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(4),
                      child: pw.Text(_formatMoney(_calculateSecondInstallmentTotal(parsed, invoice)), style: pw.TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
              // Grand Total row
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text('GRAND TOTAL (UGX)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text(
                      _formatMoney(_calculateGrandTotal(parsed, invoice)),
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


  // Calculate grand total
  double _calculateGrandTotal(_ParsedInvoiceNotes parsed, Invoice invoice) {
    final firstInstallment = _calculateFirstInstallmentTotal(parsed, invoice);
    final secondInstallment = _calculateSecondInstallmentTotal(parsed, invoice);
    return firstInstallment + secondInstallment;
  }

  bool _isPhaseTwoIncluded(Invoice invoice, _ParsedInvoiceNotes parsed) {
    if (parsed.includePhase2 != null) {
      return parsed.includePhase2!;
    }

    return invoice.secondInstallmentUGX > 0 ||
        invoice.taxesURA > 0 ||
        invoice.numberPlatesFee > 0 ||
        invoice.thirdPartyInsurance > 0 ||
        invoice.agencyFees > 0 ||
        (parsed.secondInstallment ?? 0) > 0 ||
        (parsed.taxesUra ?? 0) > 0 ||
        (parsed.plates ?? 0) > 0 ||
        (parsed.insurance ?? 0) > 0 ||
        (parsed.agent ?? 0) > 0;
  }

  // Build combined bank information footer
  pw.Widget _buildBankFooterSection(pw.ImageProvider? bankWatermarkLogo, {pw.Font? trebuchetFont, pw.Font? boldItalicFont}) {
    print('=== BANK FOOTER SECTION BEING BUILT ==='); // Debug print
    final lightGray = PdfColor.fromInt(0xFFF5F5F5); // light gray for bank section (#F5F5F5)
    const borderWidth = 1.0; // matches invoice main enclosure
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightGray,
        border: pw.Border.all(color: PdfColors.black, width: borderWidth),
      ),
      child: pw.Stack(
        children: [
          if (bankWatermarkLogo != null)
            pw.Positioned.fill(
              child: pw.Center(
                child: pw.Opacity(
                  opacity: 0.12,
                  child: pw.SizedBox(
                    width: 300,
                    height: 150,
                    child: pw.Image(bankWatermarkLogo, fit: pw.BoxFit.contain),
                  ),
                ),
              ),
            ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left-corner notice badge (black background, white text; no extra border)
              pw.Container(
                width: 110,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.white, width: 0),
                ),
                child: pw.Column(
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: pw.EdgeInsets.symmetric(vertical: 2),
                      color: PdfColors.black,
                      child: pw.Text(
                        'IMPORTANT',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      width: double.infinity,
                      padding: pw.EdgeInsets.symmetric(vertical: 2),
                      color: PdfColors.black,
                      child: pw.Text(
                        'NOTICE',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              // Bank Information section title (consistent border with other headers)
              pw.Container(
                padding: pw.EdgeInsets.only(bottom: 4),
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: borderWidth)),
                ),
                child: pw.Text(
                  'Bank Information',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Payee: NSB BUSINESS SOLUTIONS (U) LTD',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Bank Name: EQUITY BANK',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Bank Address: EQUITY BANK, CHURCH HOUSE, GF, KAMPALA RD',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Bank Code: 30',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Branch Code: 1001',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'SWIFT CODE: EQBLUGKA',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Account No:',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 3),
              pw.Padding(
                padding: pw.EdgeInsets.only(left: 15),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'UGX: 1001202951908',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red700,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'USD: 1001203004471',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),
              // Business Footer
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.black,
                ),
                child: pw.Text(
                  '.... Business & Logistics Partner',
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.white,
                    font: trebuchetFont,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

// Internal container for parsed values used as fallbacks in PDF rendering
class _ParsedInvoiceNotes {
  String? make;
  String? model;
  int? year;
  int? engineCc;
  String? fuelType;
  String? color;
  String? serialNumber;
  double? tonnage;

  // Phase 1
  String? phase1Mode; // Legacy - kept for backward compatibility
  double? cfMombasaUsd;
  double? clearanceUsd;
  double? cfKampalaUsd;
  double? ttUsd;
  double? phase1Rate;
  double? phase1TotalUgx;

  // Phase 2
  bool? includePhase2;
  bool? dutyFree;
  double? taxesUra;
  double? plates;
  double? insurance;
  double? agent;
  double? registrationProcess;
  double? secondInstallment;

  // Tax breakdown
  double? cv;
  double? idf;
  double? importDuty;
  double? vat;
  double? wht;
  double? envLevy;
  double? infra;
  double? regFee;
  double? stamp;
  double? regForm;
  String? sheetUsed;
  String? vehicleCategory;
}
