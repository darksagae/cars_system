import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'pdf/pdf_reader_service.dart';

/// Downloads and imports the URA MV database PDF on this machine.
class MvDatabaseSyncService {
  MvDatabaseSyncService._();
  static final MvDatabaseSyncService instance = MvDatabaseSyncService._();

  Future<String> syncFromUrl({
    required String fileUrl,
    required String month,
    int? recordCount,
  }) async {
    if (fileUrl.isEmpty) {
      throw Exception('PDF URL is required');
    }

    final response = await http.get(Uri.parse(fileUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
    }

    final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '/tmp';
    final downloadsDir = Directory(path.join(homeDir, 'Downloads'));
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final uraDatabaseDir = Directory(path.join(downloadsDir.path, 'ura_database'));
    if (!await uraDatabaseDir.exists()) {
      await uraDatabaseDir.create(recursive: true);
    }

    String fileName = Uri.parse(fileUrl.split('?').first).pathSegments.last;
    try {
      fileName = Uri.decodeComponent(fileName);
    } catch (_) {}
    if (fileName.isEmpty || !fileName.toLowerCase().endsWith('.pdf')) {
      fileName = 'ura_database_${DateTime.now().millisecondsSinceEpoch}.pdf';
    }

    final persistentFile = File(path.join(uraDatabaseDir.path, fileName));
    await persistentFile.writeAsBytes(response.bodyBytes);

    final pdfReader = PdfReaderService();
    await pdfReader.extractPdfTablesToDatabase(persistentFile.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_ura_database_month', month);
    await prefs.setString('last_ura_database_update', DateTime.now().toIso8601String());
    await prefs.setString('last_ura_database_pdf_path', persistentFile.path);
    await prefs.setBool('mv_database_locked', true);
    if (recordCount != null) {
      await prefs.setInt('last_ura_database_record_count', recordCount);
    }

    return 'MV database synced ($month, ${recordCount ?? 'N/A'} records)';
  }
}
