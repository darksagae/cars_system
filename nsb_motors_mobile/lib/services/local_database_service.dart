import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static Database? _database;
  Database? _testDatabase; // For testing purposes

  // Method to set test database
  void setTestDatabase(Database db) {
    _testDatabase = db;
  }

  Future<Database> get database async {
    // Return test database if set
    if (_testDatabase != null) {
      return _testDatabase!;
    }
    
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'nsb_motors_mobile.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_invoices_client_id ON invoices(client_id)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_invoices_status ON invoices(status)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_invoices_date ON invoices(invoice_date)
    ''');
  }

  // Save invoice locally
  Future<int> saveInvoice({
    required String supabaseId,
    required String clientId,
    required String invoiceNumber,
    required String customerName,
    required String customerPhone,
    required double totalAmount,
    required String invoiceDate,
    required String status,
    String? pdfUrl,
    String? localPdfPath,
    String? sentAt,
  }) async {
    final db = await database;
    
    final data = {
      'supabase_id': supabaseId,
      'client_id': clientId,
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_amount': totalAmount,
      'invoice_date': invoiceDate,
      'status': status,
      'pdf_url': pdfUrl,
      'local_pdf_path': localPdfPath,
      'sent_at': sentAt,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Try to update first (if exists)
    final result = await db.update(
      'invoices',
      data,
      where: 'supabase_id = ?',
      whereArgs: [supabaseId],
    );

    // If no rows were updated, insert new record
    if (result == 0) {
      return await db.insert('invoices', data);
    }
    
    return result;
  }

  // Get all invoices for a client
  Future<List<Map<String, dynamic>>> getInvoicesByClientId(String clientId) async {
    final db = await database;
    return await db.query(
      'invoices',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'invoice_date DESC',
    );
  }

  // Get invoice by supabase ID
  Future<Map<String, dynamic>?> getInvoiceBySupabaseId(String supabaseId) async {
    final db = await database;
    final results = await db.query(
      'invoices',
      where: 'supabase_id = ?',
      whereArgs: [supabaseId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Update invoice status
  Future<int> updateInvoiceStatus(String supabaseId, String status) async {
    final db = await database;
    return await db.update(
      'invoices',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'supabase_id = ?',
      whereArgs: [supabaseId],
    );
  }

  // Update local PDF path
  Future<int> updateInvoicePdfPath(String supabaseId, String localPdfPath) async {
    final db = await database;
    return await db.update(
      'invoices',
      {
        'local_pdf_path': localPdfPath,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'supabase_id = ?',
      whereArgs: [supabaseId],
    );
  }

  // Delete invoice
  Future<int> deleteInvoice(String supabaseId) async {
    final db = await database;
    return await db.delete(
      'invoices',
      where: 'supabase_id = ?',
      whereArgs: [supabaseId],
    );
  }

  // Get all invoices
  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final db = await database;
    return await db.query('invoices', orderBy: 'invoice_date DESC');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}