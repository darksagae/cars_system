import 'package:flutter_test/flutter_test.dart';
import 'package:nsb_motors_mobile/services/local_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  group('LocalDatabaseService', () {
    late LocalDatabaseService localDb;
    late Database database;

    setUp(() async {
      // Initialize sqflite for testing
      TestWidgetsFlutterBinding.ensureInitialized();
      sqfliteFfiInit();
      
      // Use in-memory database for testing
      database = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            // Create invoices table
            await db.execute('''
              CREATE TABLE invoices (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                supabase_id TEXT UNIQUE,
                client_id TEXT,
                invoice_number TEXT,
                customer_name TEXT,
                customer_phone TEXT,
                total_amount REAL,
                invoice_date TEXT,
                status TEXT,
                pdf_url TEXT,
                local_pdf_path TEXT,
                sent_at TEXT,
                created_at TEXT,
                updated_at TEXT
              )
            ''');
          },
        ),
      );
      
      // Create a new instance of LocalDatabaseService and set the test database
      localDb = LocalDatabaseService();
      localDb.setTestDatabase(database);
    });

    tearDown(() async {
      // Close the database after each test
      await database.close();
    });

    test('saveInvoice and getInvoicesByClientId work correctly', () async {
      // Test data
      const supabaseId = 'test_invoice_1';
      const clientId = 'test_client_1';
      const invoiceNumber = 'INV-001';
      const customerName = 'Test Customer';
      const customerPhone = '256700000000';
      const totalAmount = 100000.0;
      const invoiceDate = '2025-01-15';
      const status = 'sent';
      const pdfUrl = 'https://example.com/invoice.pdf';
      const localPdfPath = '/local/path/invoice.pdf';
      const sentAt = '2025-01-15T10:30:00Z';

      // Save an invoice
      final result = await localDb.saveInvoice(
        supabaseId: supabaseId,
        clientId: clientId,
        invoiceNumber: invoiceNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        totalAmount: totalAmount,
        invoiceDate: invoiceDate,
        status: status,
        pdfUrl: pdfUrl,
        localPdfPath: localPdfPath,
        sentAt: sentAt,
      );

      // Verify the invoice was saved
      expect(result, greaterThan(0));

      // Retrieve invoices for the client
      final invoices = await localDb.getInvoicesByClientId(clientId);

      // Verify we got the invoice back
      expect(invoices, isNotEmpty);
      expect(invoices.length, 1);
      
      final invoice = invoices.first;
      expect(invoice['supabase_id'], supabaseId);
      expect(invoice['client_id'], clientId);
      expect(invoice['invoice_number'], invoiceNumber);
      expect(invoice['customer_name'], customerName);
      expect(invoice['customer_phone'], customerPhone);
      expect(invoice['total_amount'], totalAmount);
      expect(invoice['invoice_date'], invoiceDate);
      expect(invoice['status'], status);
      expect(invoice['pdf_url'], pdfUrl);
      expect(invoice['local_pdf_path'], localPdfPath);
      expect(invoice['sent_at'], sentAt);
    });

    test('getInvoiceBySupabaseId works correctly', () async {
      // Test data
      const supabaseId = 'test_invoice_2';
      const clientId = 'test_client_2';

      // Save an invoice first
      await localDb.saveInvoice(
        supabaseId: supabaseId,
        clientId: clientId,
        invoiceNumber: 'INV-002',
        customerName: 'Test Customer 2',
        customerPhone: '256700000001',
        totalAmount: 200000.0,
        invoiceDate: '2025-01-16',
        status: 'sent',
      );

      // Retrieve the invoice by supabase ID
      final invoice = await localDb.getInvoiceBySupabaseId(supabaseId);

      // Verify we got the correct invoice
      expect(invoice, isNotNull);
      expect(invoice!['supabase_id'], supabaseId);
      expect(invoice['client_id'], clientId);
    });

    test('updateInvoiceStatus works correctly', () async {
      // Test data
      const supabaseId = 'test_invoice_3';
      const clientId = 'test_client_3';

      // Save an invoice first
      await localDb.saveInvoice(
        supabaseId: supabaseId,
        clientId: clientId,
        invoiceNumber: 'INV-003',
        customerName: 'Test Customer 3',
        customerPhone: '256700000002',
        totalAmount: 300000.0,
        invoiceDate: '2025-01-17',
        status: 'sent',
      );

      // Update the invoice status
      const newStatus = 'downloaded';
      final result = await localDb.updateInvoiceStatus(supabaseId, newStatus);

      // Verify the update was successful
      expect(result, 1);

      // Retrieve the invoice to verify the status was updated
      final invoice = await localDb.getInvoiceBySupabaseId(supabaseId);
      expect(invoice, isNotNull);
      expect(invoice!['status'], newStatus);
    });

    test('getAllInvoices works correctly', () async {
      // Save multiple invoices
      await localDb.saveInvoice(
        supabaseId: 'test_invoice_4',
        clientId: 'test_client_4',
        invoiceNumber: 'INV-004',
        customerName: 'Test Customer 4',
        customerPhone: '256700000003',
        totalAmount: 400000.0,
        invoiceDate: '2025-01-18',
        status: 'sent',
      );

      await localDb.saveInvoice(
        supabaseId: 'test_invoice_5',
        clientId: 'test_client_5',
        invoiceNumber: 'INV-005',
        customerName: 'Test Customer 5',
        customerPhone: '256700000004',
        totalAmount: 500000.0,
        invoiceDate: '2025-01-19',
        status: 'sent',
      );

      // Retrieve all invoices
      final allInvoices = await localDb.getAllInvoices();

      // Verify we got at least the invoices we just added
      expect(allInvoices.length, greaterThanOrEqualTo(2));
    });
  });
}