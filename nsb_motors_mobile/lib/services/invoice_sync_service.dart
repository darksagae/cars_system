import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'supabase_service.dart';
import 'local_database_service.dart';

/// Invoice Sync Service
/// 
/// Syncs invoices from Supabase client_activities table to local database.
/// Fetches invoices created on client machines and stores them locally.
class InvoiceSyncService {
  static final InvoiceSyncService _instance = InvoiceSyncService._internal();
  factory InvoiceSyncService() => _instance;
  InvoiceSyncService._internal();

  bool _isSyncing = false;

  /// Sync invoices from all clients or a specific client
  Future<int> syncInvoices({
    String? clientId,
    Duration? timeFilter,
    int? limit = 100,
  }) async {
    if (_isSyncing) {
      print('⚠️ Invoice sync already in progress');
      return 0;
    }

    _isSyncing = true;
    int syncedCount = 0;

    try {
      print('🔄 Starting invoice sync...');
      
      // Get all clients if clientId is not specified
      List<String> clientIds = [];
      if (clientId != null) {
        clientIds = [clientId];
      } else {
        // Get all clients from the desktop_clients table
        try {
          final clientsResponse = await SupabaseService.getDesktopClients();
          
          for (var client in clientsResponse) {
            final id = client['client_id']?.toString();
            if (id != null && id.isNotEmpty) {
              clientIds.add(id);
            }
          }
        } catch (e) {
          print('⚠️ Error fetching clients: $e');
          // Continue with empty list - will sync for current client only
        }
      }

      if (clientIds.isEmpty) {
        print('⚠️ No clients found for invoice sync');
        _isSyncing = false;
        return 0;
      }

      print('📊 Syncing invoices for ${clientIds.length} client(s)...');

      // Fetch invoice activities from each client
      for (final cId in clientIds) {
        try {
          final localDb = LocalDatabaseService();
          final activities = await SupabaseService.getClientActivities(
            cId,
            timeFilter: timeFilter,
            limit: limit,
          );

          // Filter for invoice creation activities
          final invoiceActivities = activities.where((activity) {
            final action = activity['action']?.toString() ?? '';
            return action == 'create_invoice';
          }).toList();

          print('📄 Found ${invoiceActivities.length} invoice activities for client $cId');

          // Process each invoice activity
          for (final activity in invoiceActivities) {
            try {
              final metadata = activity['metadata'] as Map<String, dynamic>? ?? {};
              final invoiceNumber = metadata['invoice_number']?.toString();
              
              if (invoiceNumber == null || invoiceNumber.isEmpty) {
                print('⚠️ Skipping activity ${activity['id']}: No invoice number');
                continue;
              }

              // Check if invoice already exists in local database
              final existingInvoice = await localDb.getInvoiceBySupabaseId(activity['id'].toString());
              if (existingInvoice != null) {
                print('⏭️ Invoice $invoiceNumber already synced, skipping');
                continue;
              }

              // Extract invoice data from metadata
              final customerName = metadata['customer_name']?.toString() ?? 'Unknown Customer';
              final amount = (metadata['amount'] as num?)?.toDouble() ?? 0.0;
              final localPdfPath = metadata['local_pdf_path']?.toString();
              final pdfUrl = metadata['pdf_url']?.toString();
              
              // Try to get PDF URL from Supabase Storage
              String? finalPdfUrl = pdfUrl;
              String? downloadedPdfPath;

              // If PDF URL is not in metadata, try to find it in Supabase Storage
              if (finalPdfUrl == null || finalPdfUrl.isEmpty) {
                finalPdfUrl = await _findPdfInStorage(invoiceNumber);
              }

              // Download PDF if URL is available
              if (finalPdfUrl != null && finalPdfUrl.isNotEmpty) {
                downloadedPdfPath = await _downloadAndSavePdf(finalPdfUrl, invoiceNumber);
              }

              // Extract invoice date from activity or use current date
              final invoiceDate = activity['created_at']?.toString() ?? DateTime.now().toIso8601String();

              // Save invoice to local database
              final result = await localDb.saveInvoice(
                supabaseId: activity['id'].toString(),
                clientId: cId,
                invoiceNumber: invoiceNumber,
                customerName: customerName,
                customerPhone: metadata['customer_phone']?.toString() ?? '',
                totalAmount: amount,
                invoiceDate: invoiceDate,
                status: 'created', // Default status for synced invoices
                pdfUrl: finalPdfUrl,
                localPdfPath: downloadedPdfPath,
                sentAt: null, // Not sent yet, just created
              );

              if (result > 0) {
                syncedCount++;
                print('✅ Synced invoice: $invoiceNumber');
              }
            } catch (e) {
              print('❌ Error syncing invoice activity ${activity['id']}: $e');
            }
          }
        } catch (e) {
          print('❌ Error syncing invoices for client $cId: $e');
        }
      }

      print('✅ Invoice sync completed: $syncedCount invoice(s) synced');
      return syncedCount;
    } catch (e) {
      print('❌ Error in invoice sync: $e');
      return syncedCount;
    } finally {
      _isSyncing = false;
    }
  }

  /// Find PDF in Supabase Storage by invoice number
  Future<String?> _findPdfInStorage(String invoiceNumber) async {
    // Supabase storage is deprecated; PDFs are now logged directly as Base64/URLs
    return null;
  }

  /// Download and save PDF permanently to local storage
  Future<String?> _downloadAndSavePdf(String pdfUrl, String invoiceNumber) async {
    try {
      print('📥 Downloading PDF for invoice $invoiceNumber: $pdfUrl');
      
      // Download PDF from URL or decode Base64 data URI
      Uint8List bytes;
      if (pdfUrl.startsWith('data:')) {
        final base64String = pdfUrl.substring(pdfUrl.indexOf(',') + 1);
        bytes = base64.decode(base64String);
      } else {
        final response = await http.get(Uri.parse(pdfUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
        }
        bytes = response.bodyBytes;
      }

      // Save PDF to application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'invoice_${invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File('${appDir.path}/$fileName');
      await pdfFile.writeAsBytes(bytes);
      
      print('✅ PDF permanently saved: ${pdfFile.path}');
      return pdfFile.path;
    } catch (e) {
      print('❌ Error downloading and saving PDF: $e');
      return null;
    }
  }

  /// Sync invoices for a specific client
  Future<int> syncInvoicesForClient(String clientId, {Duration? timeFilter}) async {
    return await syncInvoices(clientId: clientId, timeFilter: timeFilter);
  }

  /// Sync all invoices (last 30 days by default)
  Future<int> syncAllInvoices({Duration timeFilter = const Duration(days: 30)}) async {
    return await syncInvoices(timeFilter: timeFilter);
  }
}

