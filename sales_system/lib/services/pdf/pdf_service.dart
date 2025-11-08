import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../models/demand_letter.dart';

class PDFService {
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
              return [c?.name ?? 'Unknown', c?.email ?? '—', c?.phone ?? '—', rev];
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
                    pw.Text('People • Product • Growth', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
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
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(inv.customer?.name ?? '—', style: const pw.TextStyle(fontSize: 10))),
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
  // Generate professional invoice PDF matching the exact quotation format
  Future<Uint8List> generateInvoicePDF(Invoice invoice) async {
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
        ),
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Document Title - QUOTATION
                _buildDocumentTitle(invoice, logoImage, logoPdfImage, locationIcon, whatsappIcon, facebookIcon, instagramIcon, xIcon, tiktokIcon, gmailIcon),
                pw.SizedBox(height: 2),
                
                // Customer Information Section
                _buildCustomerInformation(customer),
                pw.SizedBox(height: 2),
                
                // Vehicle Details Section
                _buildVehicleDetails(invoice),
                pw.SizedBox(height: 2),
                
                // First Installment Section
                _buildFirstInstallmentTable(invoice, parsed),
                pw.SizedBox(height: 2),
                
                // Second Installment Section
                _buildSecondInstallmentTable(invoice, parsed),
                pw.SizedBox(height: 2),
                
                // Registration Process Section
                _buildRegistrationProcessSection(invoice, parsed),
                pw.SizedBox(height: 8),
                
                // Combined Bank Information Footer
                _buildBankFooterSection(),
                pw.SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // Save PDF to file
  Future<String> savePDFToFile(Invoice invoice) async {
    final pdfBytes = await generateInvoicePDF(invoice);
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

  // Save demand letter PDF
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
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'demand_${letter.letterNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
              pw.Text(customer.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              if (customer.phone.isNotEmpty) pw.Text('Phone: ${customer.phone}', style: const pw.TextStyle(fontSize: 10)),
              if (customer.email.isNotEmpty) pw.Text('Email: ${customer.email}', style: const pw.TextStyle(fontSize: 10)),
            ]),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Letter No.: ${letter.letterNumber}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Issue Date: ${_formatDate(letter.issueDate)}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Due Date: ${_formatDate(letter.dueDate)}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Invoice: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 10)),
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
                customer?.name ?? 'N/A',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                customer?.phone ?? 'N/A',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                customer?.email ?? 'N/A',
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
                '${invoice.vehicleMake} ${invoice.vehicleModel}',
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
                '${invoice.engineSize.isNotEmpty ? invoice.engineSize : (parsed.engineCc?.toString() ?? '')}cc / ${invoice.fuelType.isNotEmpty ? invoice.fuelType : (parsed.fuelType ?? '')}',
            style: pw.TextStyle(
              fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
              pw.SizedBox(height: 8),
              pw.Text(
                (invoice.vehicleYear != 0 ? invoice.vehicleYear.toString() : (parsed.year?.toString() ?? '')),
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
        _buildSecondInstallmentRow('Taxes Payable to URA', _formatMoneyWithDecimals(invoice.taxesURA != 0.0 ? invoice.taxesURA : (parsed.taxesUra ?? 0.0))),
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
        _buildBankInfoRow('Bank address:', 'EQUITY BANK, CHURCH HOUSE'),
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
          fontSize: 12,
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
          email = trimmedLine.substring(6).trim();
        } else if (trimmedLine.startsWith('Phone:')) {
          phone = trimmedLine.substring(6).trim();
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

  // Parse invoice notes for additional details used as fallbacks
  _ParsedInvoiceNotes _parseInvoiceNotes(String notes) {
    final parsed = _ParsedInvoiceNotes();
    if (notes.isEmpty) return parsed;
    final lines = notes.split('\n').map((e) => e.trim()).toList();

    for (final line in lines) {
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
      } else if (line.startsWith('Customs Value')) {
        parsed.cv = _tryParseMoney(line.split(':').last);
      } else if (line.startsWith('Import Declaration')) {
        parsed.idf = _tryParseMoney(line.split(':').last);
      } else if (line.startsWith('Import Duty')) {
        parsed.importDuty = _tryParseMoney(line.split(':').last);
      } else if (line.startsWith('VAT ')) {
        parsed.vat = _tryParseMoney(line.split(':').last);
      } else if (line.startsWith('Withholding Tax') || line.startsWith('WHT')) {
        parsed.wht = _tryParseMoney(line.split(':').last);
      } else if (line.startsWith('Environmental Levy')) {
        parsed.envLevy = _tryParseMoney(line.split(':').last);
      } else if (line.startsWith('Infrastructure Levy')) {
        parsed.infra = _tryParseMoney(line.split(':').last);
      } else if (line.startsWith('Registration Fee')) {
        parsed.regFee = _tryParseMoney(line.split(':').last);
      } else if (line.startsWith('Stamp Duty')) {
        parsed.stamp = _tryParseMoney(line.split(':').last);
      } else if (line.startsWith('Reg Form')) {
        parsed.regForm = _tryParseMoney(line.split(':').last);
      } else if (line.startsWith('Sheet Used:')) {
        parsed.sheetUsed = line.substring(11).trim();
      } else if (line.startsWith('Vehicle Category:')) {
        parsed.vehicleCategory = line.substring(17).trim();
      }
    }

    if (parsed.secondInstallment == null && parsed.taxesUra != null) {
      // Align with new definition: Registration Process = URA + Plates + Insurance + Agent
      parsed.registrationProcess = (parsed.taxesUra ?? 0) + (parsed.plates ?? 0) + (parsed.insurance ?? 0) + (parsed.agent ?? 0);
      parsed.secondInstallment = parsed.registrationProcess;
    }

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

    if (iconImage == null) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      width: 14,
      height: 14,
      padding: pw.EdgeInsets.all(1),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Image(
        iconImage,
        fit: pw.BoxFit.contain,
      ),
    );
  }

  // Build document title section with company header
  pw.Widget _buildDocumentTitle(Invoice invoice, Uint8List logoImage, pw.ImageProvider? logoPdfImage, pw.ImageProvider? locationIcon, pw.ImageProvider? whatsappIcon, pw.ImageProvider? facebookIcon, pw.ImageProvider? instagramIcon, pw.ImageProvider? xIcon, pw.ImageProvider? tiktokIcon, pw.ImageProvider? gmailIcon) {
    print('Building document title with logo: ${logoImage.length} bytes');
    final colors = _getDynamicColors(invoice);
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(5),
      child: pw.Column(
        children: [
          // Company Header Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Logo Section (Left)
              pw.Container(
                width: 120,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Logo
                    (logoPdfImage != null)
                        ? pw.Container(
                            width: 80,
                            height: 60,
                            child: pw.Image(
                              logoPdfImage,
                              fit: pw.BoxFit.contain,
                            ),
                          )
                        : pw.Container(
                            width: 80,
                            height: 60,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.green600,
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'NSB',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          ),
                    pw.SizedBox(height: 5),
                    // Tagline
                    pw.Text(
                      'People • Product • Growth',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Address Section (Middle) with location icon
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Location icon above address (centered, larger size)
                    if (locationIcon != null)
                      pw.Container(
                        width: 30,
                        height: 30,
                        padding: pw.EdgeInsets.all(2),
                        child: pw.Image(
                          locationIcon,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    pw.SizedBox(height: 3),
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
              
              // Contact Section (Right) with icons
              pw.Container(
                width: 200,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Phone with WhatsApp icon
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        _buildSocialIcon('whatsapp', locationIcon, whatsappIcon, facebookIcon, instagramIcon, xIcon, tiktokIcon, gmailIcon),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          '+256 394 836253 / +256 752 128406',
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    // Email with envelope icon
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        _buildSocialIcon('gmail', locationIcon, whatsappIcon, facebookIcon, instagramIcon, xIcon, tiktokIcon, gmailIcon),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          'nsbbsolutions@gmail.com',
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.black, fontStyle: pw.FontStyle.italic),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    // Social Media Icons
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        _buildSocialIcon('facebook', locationIcon, whatsappIcon, facebookIcon, instagramIcon, xIcon, tiktokIcon, gmailIcon),
                        pw.SizedBox(width: 3),
                        _buildSocialIcon('x', locationIcon, whatsappIcon, facebookIcon, instagramIcon, xIcon, tiktokIcon, gmailIcon),
                        pw.SizedBox(width: 3),
                        _buildSocialIcon('tiktok', locationIcon, whatsappIcon, facebookIcon, instagramIcon, xIcon, tiktokIcon, gmailIcon),
                        pw.SizedBox(width: 3),
                        _buildSocialIcon('instagram', locationIcon, whatsappIcon, facebookIcon, instagramIcon, xIcon, tiktokIcon, gmailIcon),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          'nsb motors ug',
                          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Horizontal Line
          pw.SizedBox(height: 5),
          pw.Container(
            height: 1,
            color: PdfColors.grey400,
          ),
          pw.SizedBox(height: 5),
          
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
        ],
      ),
    );
  }

  // Build customer information section
  pw.Widget _buildCustomerInformation(Customer? customer) {
    // Use table for proper alignment
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(vertical: 2),
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
                  customer?.name ?? 'N/A',
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
                  customer?.phone ?? 'N/A',
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
                  customer?.email ?? 'N/A',
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
      padding: pw.EdgeInsets.symmetric(vertical: 2),
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
      padding: pw.EdgeInsets.symmetric(vertical: 2),
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
          pw.SizedBox(height: 5),
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
      padding: pw.EdgeInsets.symmetric(vertical: 2),
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
          pw.SizedBox(height: 5),
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
                    child: pw.Text('Taxes Payable to URA', style: pw.TextStyle(fontSize: 10)),
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
                    child: pw.Text('Agent Fees', style: pw.TextStyle(fontSize: 10)),
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
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(vertical: 2),
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
          pw.SizedBox(height: 5),
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

  // Build combined bank information footer
  pw.Widget _buildBankFooterSection() {
    print('=== BANK FOOTER SECTION BEING BUILT ==='); // Debug print
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Bank Information
          pw.Text(
            'Bank Information',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
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
            'Bank Address: EQUITY BANK, CHURCH HOUSE',
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
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.center,
            ),
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
