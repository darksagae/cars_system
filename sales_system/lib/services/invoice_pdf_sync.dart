import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/invoice.dart';
import 'cloud_api_service.dart';
import 'invoice_service.dart';
import 'pdf/pdf_service.dart';

/// Keeps cloud PDF byte-identical to the machine file in Downloads
/// (NSBmotors_{invoiceNumber}_{timestamp}.pdf).
class InvoicePdfSync {
  InvoicePdfSync._();

  static String downloadsPrefix(String invoiceNumber) =>
      'NSBmotors_${invoiceNumber}_';

  /// Newest matching PDF in Downloads for this invoice number.
  static Future<String?> findLatestInDownloads(String invoiceNumber) async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads == null) return null;
      final dir = Directory(downloads.path);
      if (!await dir.exists()) return null;

      final prefix = downloadsPrefix(invoiceNumber);
      File? newest;
      int newestStamp = -1;

      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (!name.startsWith(prefix) || !name.toLowerCase().endsWith('.pdf')) {
          continue;
        }
        // NSBmotors_INV-xxxx_<epochMs>.pdf — highest stamp wins
        final stampStr = name.substring(prefix.length, name.length - 4);
        final stamp = int.tryParse(stampStr) ?? 0;
        if (stamp > newestStamp) {
          newest = entity;
          newestStamp = stamp;
        }
      }
      return newest?.path;
    } catch (e) {
      print('findLatestInDownloads error: $e');
      return null;
    }
  }

  /// Stored path, else newest Downloads file for this invoice.
  static Future<String?> resolveCanonicalPath(Invoice invoice) async {
    if (invoice.id != null) {
      final stored = await InvoiceService().getLocalPdfPath(invoice.id!);
      if (stored != null && stored.isNotEmpty && await File(stored).exists()) {
        return stored;
      }
    }
    return findLatestInDownloads(invoice.invoiceNumber);
  }

  static Future<String> saveAndRecord(Invoice invoice) async {
    final path = await PDFService().savePDFToFile(invoice);
    if (invoice.id != null) {
      await InvoiceService().setLocalPdfPath(invoice.id!, path);
    }
    return path;
  }

  /// Upload exact bytes from the Downloads/stored PDF file.
  /// Returns null on success, or an error message.
  static Future<String?> uploadForInvoice(Invoice invoice, {String? path}) async {
    final resolved = path ?? await resolveCanonicalPath(invoice);
    if (resolved == null) {
      return 'No PDF file found for ${invoice.invoiceNumber}';
    }
    if (invoice.id != null) {
      await InvoiceService().setLocalPdfPath(invoice.id!, resolved);
    }
    return CloudApiService().syncInvoicePdfToCloud(
      invoiceNumber: invoice.invoiceNumber,
      localPdfPath: resolved,
      invoice: invoice,
    );
  }

  static Future<Uint8List> readCanonicalBytes(Invoice invoice) async {
    final path = await resolveCanonicalPath(invoice);
    if (path != null) {
      return File(path).readAsBytes();
    }
    return PDFService().generateInvoicePDF(invoice);
  }
}
