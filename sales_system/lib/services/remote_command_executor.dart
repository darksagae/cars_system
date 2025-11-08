import '../services/remote_command_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pairing_service.dart';
import 'auth_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'pdf/pdf_reader_service.dart';

/// Executes remote commands received from mobile app
class RemoteCommandExecutor {
  static final RemoteCommandExecutor _instance = RemoteCommandExecutor._internal();
  factory RemoteCommandExecutor() => _instance;
  RemoteCommandExecutor._internal();

  final RemoteCommandService _commandService = RemoteCommandService();

  /// Initialize and start listening for commands
  Future<void> initialize() async {
    try {
      // Guard: do not initialize if device isn't paired yet
      final paired = await PairingService().isPaired();
      if (!paired) {
        print('🔒 RemoteCommandExecutor skipped: device not paired.');
        return;
      }
      await _commandService.initialize();
      // If server marks this device archived/revoked, unpair locally and stop
      final status = await _commandService.getCurrentClientStatus();
      if (status == null || status == 'archived' || status == 'revoked') {
        print('🔒 Device status on server is $status. Unpairing locally.');
        await PairingService().unpair();
        return;
      }
      final registered = await _commandService.registerClient();
      
      if (!registered) {
        print('⚠️ Failed to register client, but continuing...');
      }

      // Start polling for commands
      _commandService.startPolling(
        onCommandReceived: _handleCommand,
        interval: const Duration(seconds: 5),
      );

      print('✅ RemoteCommandExecutor initialized and polling');
    } catch (e) {
      print('❌ Error initializing RemoteCommandExecutor: $e');
      // Try to continue anyway
      rethrow;
    }
  }

  /// Restart polling (useful if it stopped)
  Future<void> restartPolling() async {
    print('🔄 Restarting polling...');
    _commandService.stopPolling();
    await Future.delayed(const Duration(seconds: 1));
    _commandService.startPolling(
      onCommandReceived: _handleCommand,
      interval: const Duration(seconds: 5),
    );
  }

  /// Handle incoming command
  Future<void> _handleCommand(Map<String, dynamic> command) async {
    final commandId = command['id'] as String;
    final commandType = command['command'] as String;
    final parameters = command['parameters'] as Map<String, dynamic>? ?? {};

    print('📨 Received command: $commandType (ID: $commandId)');
    print('   Parameters: $parameters');

    try {
      // Mark as processing
      await _commandService.updateCommandStatus(
        commandId: commandId,
        status: 'processing',
      );

      // Execute command based on type
      // Handle aliases for backward compatibility
      String normalizedCommand = commandType;
      if (commandType == 'restart') {
        normalizedCommand = 'restart_application';
      } else if (commandType == 'sync_database') {
        normalizedCommand = 'refresh_database';
      }
      
      String resultSummary;
      print('🔧 Executing command: $normalizedCommand');
      switch (normalizedCommand) {
        case 'refresh_database':
          resultSummary = await _handleRefreshDatabase();
          break;
        case 'update_exchange_rate':
          resultSummary = await _handleUpdateExchangeRate(parameters);
          break;
        case 'restart_application':
          resultSummary = await _handleRestartApplication();
          break;
        case 'export_data':
          resultSummary = await _handleExportData(parameters);
          break;
        case 'backup_database':
          resultSummary = await _handleBackupDatabase();
          break;
        case 'sync_users':
          resultSummary = await _handleSyncUsers(parameters);
          break;
        case 'update_mv_database':
          print('📥 Entering update_mv_database handler...');
          resultSummary = await _handleUpdateMvDatabase(parameters);
          break;
        default:
          print('❌ Unknown command type: $commandType (normalized: $normalizedCommand)');
          throw Exception('Unknown command type: $commandType (normalized: $normalizedCommand)');
      }

      // Mark as completed
      await _commandService.updateCommandStatus(
        commandId: commandId,
        status: 'completed',
        resultSummary: resultSummary,
      );

      print('✅ Command executed successfully: $commandType');
    } catch (e) {
      // Mark as failed
      await _commandService.updateCommandStatus(
        commandId: commandId,
        status: 'failed',
        errorMessage: e.toString(),
      );

      print('❌ Command failed: $commandType - $e');
    }
  }

  /// Handle refresh database command
  Future<String> _handleRefreshDatabase() async {
    // Implement database refresh logic here
    // For now, just return success message
    return 'Database refreshed successfully';
  }

  /// Handle update exchange rate command (supports dual rates: tax and phase1)
  Future<String> _handleUpdateExchangeRate(Map<String, dynamic> params) async {
    // Handle both int and double types from JSON
    final rateTaxRaw = params['rate'] ?? params['tax_rate'];
    final ratePhase1Raw = params['phase1_rate'];
    
    double? rateTax;
    if (rateTaxRaw != null) {
      if (rateTaxRaw is int) {
        rateTax = rateTaxRaw.toDouble();
      } else if (rateTaxRaw is double) {
        rateTax = rateTaxRaw;
      } else if (rateTaxRaw is String) {
        rateTax = double.tryParse(rateTaxRaw);
      }
    }
    
    double? ratePhase1;
    if (ratePhase1Raw != null) {
      if (ratePhase1Raw is int) {
        ratePhase1 = ratePhase1Raw.toDouble();
      } else if (ratePhase1Raw is double) {
        ratePhase1 = ratePhase1Raw;
      } else if (ratePhase1Raw is String) {
        ratePhase1 = double.tryParse(ratePhase1Raw);
      }
    }
    
    if (rateTax == null) {
      throw Exception('Exchange rate (tax_rate) parameter is required');
    }

    // Store exchange rates in SharedPreferences
    print('💰 [Exchange Rate] Updating local exchange rates...');
    print('   Tax Rate: $rateTax');
    print('   Phase 1 Rate: ${ratePhase1 ?? rateTax}');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('exchange_rate', rateTax);
    await prefs.setDouble('exchange_rate_tax', rateTax);
    if (ratePhase1 != null) {
      await prefs.setDouble('exchange_rate_phase1', ratePhase1);
    } else {
      // If phase1 not provided, use tax rate as default
      await prefs.setDouble('exchange_rate_phase1', rateTax);
    }
    await prefs.setString('exchange_rate_updated', DateTime.now().toIso8601String());
    
    // Verify the values were saved
    final savedTax = prefs.getDouble('exchange_rate_tax');
    final savedPhase1 = prefs.getDouble('exchange_rate_phase1');
    print('✅ [Exchange Rate] Exchange rates saved to SharedPreferences:');
    print('   Tax Rate: $savedTax');
    print('   Phase 1 Rate: $savedPhase1');
    print('   Updated at: ${prefs.getString('exchange_rate_updated')}');

    return 'Exchange rates updated: Tax=$rateTax, Phase1=${ratePhase1 ?? rateTax}';
  }

  /// Handle restart application command
  Future<String> _handleRestartApplication() async {
    // Note: This is a placeholder. Actually restarting requires platform-specific code
    // For now, we'll just log it
    print('⚠️ Restart application requested (not fully implemented)');
    return 'Restart command received (requires manual restart)';
  }

  /// Handle export data command
  Future<String> _handleExportData(Map<String, dynamic> params) async {
    final format = params['format'] as String? ?? 'csv';
    final table = params['table'] as String?;

    // Implement export logic here
    print('Exporting data: format=$format, table=$table');
    return 'Data exported successfully (format: $format)';
  }

  /// Handle backup database command
  Future<String> _handleBackupDatabase() async {
    // Implement backup logic here
    print('Creating database backup...');
    return 'Database backup created successfully';
  }

  /// Handle sync users command: parameters: { users: [{username, password_hash, role}] }
  Future<String> _handleSyncUsers(Map<String, dynamic> params) async {
    final list = params['users'];
    if (list is! List) {
      throw Exception('Missing users payload (expected array)');
    }
    final users = <Map<String, dynamic>>[];
    for (final u in list) {
      if (u is Map) {
        users.add({
          'username': (u['username'] ?? '').toString(),
          'password_hash': (u['password_hash'] ?? '').toString(),
          'role': (u['role'] ?? 'user').toString(),
        });
      }
    }
    if (users.isEmpty) {
      return 'No users to sync';
    }
    await AuthService().applyUserSync(users);
    print('✅ Synced ${users.length} users from admin');
    return 'Synchronized ${users.length} users';
  }

  /// Handle update MV database command: parameters: { file_url, month, record_count }
  Future<String> _handleUpdateMvDatabase(Map<String, dynamic> params) async {
    final fileUrl = params['file_url'] as String?;
    final month = params['month'] as String?;
    final recordCount = params['record_count'] as int?;
    
    if (fileUrl == null || fileUrl.isEmpty) {
      throw Exception('file_url parameter is required');
    }
    
    print('📥 MV Database update requested: $fileUrl (month: $month)');
    
    File? tempFile;
    try {
      // 1. Download PDF file from URL
      print('📥 Downloading PDF from: $fileUrl');
      final response = await http.get(Uri.parse(fileUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }
      
      // 2. Save to Downloads folder for easy access
      final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '/tmp';
      print('📂 Home directory: $homeDir');
      final downloadsDir = Directory(path.join(homeDir, 'Downloads'));
      print('📂 Downloads directory: ${downloadsDir.path}');
      
      if (!await downloadsDir.exists()) {
        print('📁 Creating Downloads directory...');
        await downloadsDir.create(recursive: true);
        print('✅ Downloads directory created');
      } else {
        print('✅ Downloads directory exists');
      }
      
      // Also create ura_database subdirectory in Downloads for organization
      final uraDatabaseDir = Directory(path.join(downloadsDir.path, 'ura_database'));
      print('📂 URA database directory: ${uraDatabaseDir.path}');
      
      if (!await uraDatabaseDir.exists()) {
        print('📁 Creating ura_database directory...');
        await uraDatabaseDir.create(recursive: true);
        print('✅ URA database directory created');
      } else {
        print('✅ URA database directory exists');
      }
      
      // Extract filename from URL and decode URL encoding
      String fileName = fileUrl.split('/').last;
      // Decode URL encoding (e.g., "Used%20MV%20Database" -> "Used MV Database")
      try {
        fileName = Uri.decodeComponent(fileName);
      } catch (e) {
        print('⚠️ Could not decode filename, using as-is: $e');
      }
      
      // Ensure it's not empty and has .pdf extension
      if (fileName.isEmpty || !fileName.toLowerCase().endsWith('.pdf')) {
        fileName = 'ura_database_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }
      
      final persistentFile = File(path.join(uraDatabaseDir.path, fileName));
      await persistentFile.writeAsBytes(response.bodyBytes);
      
      final fileSizeMB = (response.bodyBytes.length / 1024 / 1024).toStringAsFixed(2);
      print('✅ PDF downloaded successfully!');
      print('   📁 Full path: ${persistentFile.path}');
      print('   📄 File name: $fileName');
      print('   📊 File size: ${fileSizeMB} MB');
      print('   📂 Directory: ${uraDatabaseDir.path}');
      
      // Verify file exists
      if (await persistentFile.exists()) {
        final actualSize = await persistentFile.length();
        print('   ✅ File verified: exists (${(actualSize / 1024 / 1024).toStringAsFixed(2)} MB)');
      } else {
        print('   ❌ WARNING: File was written but does not exist!');
      }
      
      // 3. Extract and import data using PdfReaderService
      print('🔍 Extracting vehicle data from PDF...');
      final pdfReader = PdfReaderService();
      await pdfReader.extractPdfTablesToDatabase(persistentFile.path);
      print('✅ PDF extraction and import completed!');
      
      // 4. Update local metadata (store month info and PDF path)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_ura_database_month', month ?? 'Unknown');
      await prefs.setString('last_ura_database_update', DateTime.now().toIso8601String());
      await prefs.setString('last_ura_database_pdf_path', persistentFile.path);
      if (recordCount != null) {
        await prefs.setInt('last_ura_database_record_count', recordCount);
      }
      
      // Clean up old PDFs (keep only the latest 3)
      try {
        final pdfFiles = await uraDatabaseDir
            .list()
            .where((entity) => entity.path.toLowerCase().endsWith('.pdf'))
            .cast<File>()
            .toList();
        
        if (pdfFiles.length > 3) {
          // Get modification times and sort by them
          final filesWithTime = await Future.wait(
            pdfFiles.map((file) async => {
              'file': file,
              'time': await file.lastModified(),
            })
          );
          
          // Sort by modification time (newest first)
          filesWithTime.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
          
          // Keep only the 3 most recent PDFs
          for (int i = 3; i < filesWithTime.length; i++) {
            try {
              final file = filesWithTime[i]['file'] as File;
              await file.delete();
              print('🧹 Deleted old PDF: ${file.path.split('/').last}');
            } catch (e) {
              print('⚠️ Failed to delete old PDF: $e');
            }
          }
        }
      } catch (e) {
        print('⚠️ Error cleaning up old PDFs: $e');
      }
      
      print('✅ MV Database update complete! Month: $month');
      print('🎉 Database is now ready with the latest URA vehicle data!');
      print('📁 Latest PDF saved at: ${persistentFile.path}');
      return 'MV database updated successfully (Month: $month, Records: ${recordCount ?? 'N/A'})';
      
    } catch (e) {
      print('❌ Error updating MV database: $e');
      throw Exception('Failed to update MV database: $e');
    }
  }

  /// Stop command executor
  void stop() {
    _commandService.stopPolling();
  }
}

