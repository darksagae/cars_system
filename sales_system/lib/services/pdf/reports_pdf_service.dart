import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class ReportsPDFService {
  Future<Uint8List> generateAnalyticsReport({
    required Map<String, dynamic> analytics,
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    final base = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();

    final stats = (analytics['stats'] as Map<String, dynamic>?);

    pw.Widget header() => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Business Reports', style: pw.TextStyle(font: bold, fontSize: 18)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _formatDateRange(startDate, endDate),
                    style: pw.TextStyle(font: base, fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  reportType,
                  style: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        );

    pw.Widget summaryCards() {
      if (stats == null) return pw.SizedBox();
      final items = <_SummaryItem>[
        _SummaryItem('Total Revenue', _fmt(stats['totalRevenue']), PdfColors.green600),
        _SummaryItem('Total Invoices', '${stats['totalInvoices']}', PdfColors.blue600),
        _SummaryItem('Total Customers', '${stats['totalCustomers']}', PdfColors.purple600),
        _SummaryItem('Outstanding', _fmt(stats['totalOutstanding']), PdfColors.orange600),
      ];
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Summary', style: pw.TextStyle(font: bold, fontSize: 14)),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (e) => pw.Container(
                    width: 250,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(e.title, style: pw.TextStyle(font: base, fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(e.value,
                            style: pw.TextStyle(font: bold, fontSize: 16, color: e.color)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      );
    }

    pw.Widget section() {
      switch (reportType) {
        case 'Sales Summary':
          final status = (analytics['statusBreakdown'] as Map<String, int>?);
          return _keyValueTable('Invoice Status Breakdown', status);
        case 'Customer Analysis':
          final customers = (analytics['customers'] as List<dynamic>?);
          return _simpleListTable(
            title: 'Top Customers',
            headers: ['Name', 'Email'],
            rows: (customers ?? [])
                .take(10)
                .map((c) => [
                      (c?.name ?? '-').toString(),
                      (c?.email ?? '-').toString(),
                    ])
                .toList(),
          );
        case 'Payment Analysis':
          final pm = (analytics['paymentMethodBreakdown'] as Map<String, int>?);
          return _keyValueTable('Payment Methods', pm);
        case 'Invoice Analysis':
          final invoices = (analytics['recentInvoices'] as List<dynamic>?);
          return _simpleListTable(
            title: 'Recent Invoices',
            headers: ['No.', 'Status', 'Total'],
            rows: (invoices ?? [])
                .take(15)
                .map((i) => [
                      (i.invoiceNumber ?? '').toString(),
                      (i.status ?? '').toString(),
                      _fmt(i.totalAmount ?? 0),
                    ])
                .toList(),
          );
        case 'Tax Analysis':
          final invoices = (analytics['recentInvoices'] as List<dynamic>?);
          final totalTax = (invoices ?? [])
              .fold<double>(0.0, (s, i) => s + ((i.taxAmount ?? 0.0) as double));
          final avg = (invoices?.isNotEmpty ?? false)
              ? totalTax / (invoices!.length)
              : 0.0;
          return _keyValueTable('Tax Summary', {
            'Total Tax': totalTax.toInt(),
            'Average Tax': avg.toInt(),
          });
        default:
          return pw.SizedBox();
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: base, bold: bold),
        header: (ctx) => header(),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(font: base, fontSize: 10, color: PdfColors.grey700)),
        ),
        build: (context) => [
          summaryCards(),
          pw.SizedBox(height: 16),
          section(),
        ],
      ),
    );

    return pdf.save();
  }

  Future<String> saveToFile(Uint8List bytes, {required String fileName}) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  String _formatDateRange(DateTime s, DateTime e) {
    String fmt(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
    return '${fmt(s)}  to  ${fmt(e)}';
  }

  String _two(int v) => v < 10 ? '0$v' : '$v';

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    if (n >= 1000000) return 'UGX ${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return 'UGX ${(n / 1000).toStringAsFixed(1)}K';
    return 'UGX ${n.toStringAsFixed(0)}';
  }

  pw.Widget _keyValueTable(String? title, Map<String, int>? data) {
    if (data == null || data.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title != null) pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        if (title != null) pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1)},
          children: [
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Label', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            ]),
            ...data.entries.map((e) => pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.key)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('${e.value}'))),
                ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _simpleListTable({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            for (int i = 0; i < headers.length; i++) i: const pw.FlexColumnWidth(),
          },
          children: [
            pw.TableRow(
              children: headers
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ))
                  .toList(),
            ),
            ...rows.map((r) => pw.TableRow(
                  children: r
                      .map((c) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(c, overflow: pw.TextOverflow.span, maxLines: 1),
                          ))
                      .toList(),
                )),
          ],
        ),
      ],
    );
  }
}

class _SummaryItem {
  final String title;
  final String value;
  final PdfColor color;
  _SummaryItem(this.title, this.value, this.color);
}


