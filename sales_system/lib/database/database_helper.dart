import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'migration_helper.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  static DatabaseHelper get instance => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // Use a more persistent path for Linux
      String path;
      if (Platform.isLinux) {
        // Use home directory for Linux
        final homeDir = Platform.environment['HOME'] ?? '/tmp';
        path = join(homeDir, 'sales_system.db');
      } else {
        path = join(await getDatabasesPath(), 'sales_system.db');
      }
      print('Initializing database at: $path');
      
      final db = await databaseFactory.openDatabase(
      path,
        options: OpenDatabaseOptions(
          version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
        ),
      );
      
      print('Database initialized successfully');
      return db;
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables...');
    
    // Create Customers table
    print('Creating customers table...');
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        address TEXT,
        city TEXT,
        location TEXT,
        company TEXT,
        notes TEXT,
        profileImage TEXT,
        totalSpent REAL DEFAULT 0.0,
        totalInvoices INTEGER DEFAULT 0,
        balance REAL DEFAULT 0.0,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create Vehicles table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stockNo TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        priceUSD REAL NOT NULL,
        priceUGX REAL DEFAULT 0.0,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        chassisNo TEXT,
        engineSize TEXT,
        fuelType TEXT,
        transmission TEXT,
        mileage INTEGER DEFAULT 0,
        color TEXT,
        status TEXT DEFAULT 'inStock',
        isActive INTEGER DEFAULT 1,
        images TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create Invoices table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceNumber TEXT NOT NULL UNIQUE,
        invoiceType TEXT DEFAULT 'carSale',
        customerId INTEGER NOT NULL,
        vehicleId INTEGER,
        invoiceDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        status INTEGER DEFAULT 0,
        
        stockNo TEXT,
        vehicleMake TEXT,
        vehicleModel TEXT,
        vehicleYear INTEGER DEFAULT 0,
        chassisNo TEXT,
        engineSize TEXT,
        fuelType TEXT,
        transmission TEXT,
        color TEXT,
        countryOfOrigin TEXT DEFAULT 'JP',
        
        carPriceUSD REAL DEFAULT 0.0,
        clearanceFeeUSD REAL DEFAULT 0.0,
        exchangeRate REAL DEFAULT 3834.56,
        firstInstallmentUGX REAL DEFAULT 0.0,
        
        taxesURA REAL DEFAULT 0.0,
        numberPlatesFee REAL DEFAULT 714300.0,
        thirdPartyInsurance REAL DEFAULT 0.0,
        agencyFees REAL DEFAULT 0.0,
        secondInstallmentUGX REAL DEFAULT 0.0,
        
        subtotal REAL DEFAULT 0.0,
        taxAmount REAL DEFAULT 0.0,
        discountAmount REAL DEFAULT 0.0,
        totalAmount REAL DEFAULT 0.0,
        paidAmount REAL DEFAULT 0.0,
        balanceAmount REAL DEFAULT 0.0,
        carAmount REAL DEFAULT 0.0,
        downPayment REAL DEFAULT 0.0,
        remainingAmount REAL DEFAULT 0.0,
        notes TEXT,
        terms TEXT,
        images TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');
    print('Invoices table created successfully');

    // Create Invoice Items table
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        productId INTEGER,
        productName TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        taxRate REAL DEFAULT 0.0,
        discount REAL DEFAULT 0.0,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');
    print('Invoice items table created successfully');

    // Create Payments table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        amount REAL NOT NULL,
        method INTEGER NOT NULL,
        status INTEGER DEFAULT 0,
        paymentDate TEXT NOT NULL,
        reference TEXT,
        referenceNumber TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // Create Demand Letters table
    await db.execute('''
      CREATE TABLE demand_letters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        customerId INTEGER NOT NULL,
        letterNumber TEXT NOT NULL UNIQUE,
        issueDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        amount REAL NOT NULL,
        interestRate REAL NOT NULL,
        daysOverdue INTEGER NOT NULL,
        status TEXT NOT NULL,
        subject TEXT NOT NULL,
        content TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Create Payment Reminders table
    await db.execute('''
      CREATE TABLE payment_reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        customer_id INTEGER NOT NULL,
        reminder_number TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        sent_date TEXT,
        subject TEXT NOT NULL,
        message TEXT NOT NULL,
        frequency TEXT NOT NULL,
        days_before_due INTEGER NOT NULL,
        days_after_due INTEGER NOT NULL,
        is_recurring INTEGER DEFAULT 0,
        next_reminder_date TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Create Vehicle Tax Rates table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vehicle_tax_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        modelCode TEXT,
        bodyType TEXT,
        yearFrom INTEGER NOT NULL,
        yearTo INTEGER NOT NULL,
        engineSizeCC INTEGER NOT NULL,
        fuelType TEXT NOT NULL,
        fobValue REAL NOT NULL,
        customsValue REAL NOT NULL,
        importDuty REAL NOT NULL,
        exciseDuty REAL NOT NULL,
        vat REAL NOT NULL,
        infrastructureLevy REAL DEFAULT 0.0,
        environmentalLevy REAL DEFAULT 0.0,
        withholdingTax REAL DEFAULT 0.0,
        registrationFee REAL DEFAULT 0.0,
        totalTaxUGX REAL NOT NULL,
        databaseMonth TEXT NOT NULL,
        importedAt TEXT NOT NULL,
        importedBy TEXT,
        sourceFile TEXT,
        isActive INTEGER DEFAULT 1,
        notes TEXT,
        CHECK(yearFrom <= yearTo),
        CHECK(totalTaxUGX >= 0)
      )
    ''');

    // Create Tax Import History table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tax_import_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fileName TEXT NOT NULL,
        importMonth TEXT NOT NULL,
        importedAt TEXT NOT NULL,
        importedBy TEXT,
        recordsImported INTEGER NOT NULL,
        recordsUpdated INTEGER DEFAULT 0,
        recordsFailed INTEGER DEFAULT 0,
        status TEXT NOT NULL,
        errorLog TEXT,
        notes TEXT,
        CHECK(status IN ('success', 'partial', 'failed'))
      )
    ''');

    // Create URA CIF Database Cache table (for vehicle lookups)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ura_cif_database (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serial_number TEXT,
        hsc_code TEXT,
        country_origin TEXT,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        engine_cc INTEGER,
        description TEXT,
        cif_usd REAL NOT NULL,
        database_month TEXT NOT NULL,
        downloaded_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Create Exchange Rate Cache table
    await db.execute('''
      CREATE TABLE exchange_rate_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rate REAL NOT NULL,
        effective_date TEXT NOT NULL,
        source TEXT,
        downloaded_at TEXT NOT NULL,
        is_current INTEGER DEFAULT 1
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vehicles_make ON vehicles(make)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vehicles_model ON vehicles(model)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_number ON invoices(invoiceNumber)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customerId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoiceId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_invoice ON payments(invoiceId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_demand_letters_invoice ON demand_letters(invoiceId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_demand_letters_customer ON demand_letters(customerId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_demand_letters_status ON demand_letters(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_demand_letters_number ON demand_letters(letterNumber)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_reminders_invoice ON payment_reminders(invoice_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_reminders_customer ON payment_reminders(customer_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_reminders_status ON payment_reminders(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_reminders_type ON payment_reminders(type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_reminders_scheduled ON payment_reminders(scheduled_date)');
    
    // Create indexes for vehicle_tax_rates table
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tax_make_model ON vehicle_tax_rates(make, model)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tax_year_range ON vehicle_tax_rates(yearFrom, yearTo)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tax_engine_size ON vehicle_tax_rates(engineSizeCC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tax_active ON vehicle_tax_rates(isActive)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tax_month ON vehicle_tax_rates(databaseMonth, isActive)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tax_lookup ON vehicle_tax_rates(make, model, yearFrom, yearTo, engineSizeCC, isActive)');
    
    // Create indexes for URA CIF database
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ura_make_model ON ura_cif_database(make, model)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ura_year ON ura_cif_database(year)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ura_engine ON ura_cif_database(engine_cc)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ura_active ON ura_cif_database(is_active)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ura_month ON ura_cif_database(database_month, is_active)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ura_lookup ON ura_cif_database(make, model, year, engine_cc, is_active)');
    
    // Create indexes for exchange rate cache
    await db.execute('CREATE INDEX IF NOT EXISTS idx_exchange_current ON exchange_rate_cache(is_current)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_exchange_date ON exchange_rate_cache(effective_date)');
    
    print('All database tables and indexes created successfully!');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    // Run migrations using MigrationHelper
    await MigrationHelper.runMigrations(db);
    
    if (oldVersion < 2) {
      // Check if tables exist before altering them
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='invoices'");
      if (tables.isNotEmpty) {
        // Add new fields to invoices table
        try {
          await db.execute('ALTER TABLE invoices ADD COLUMN carAmount REAL DEFAULT 0.0');
        } catch (e) {
          print('Column carAmount might already exist: $e');
        }
        try {
          await db.execute('ALTER TABLE invoices ADD COLUMN downPayment REAL DEFAULT 0.0');
        } catch (e) {
          print('Column downPayment might already exist: $e');
        }
        try {
          await db.execute('ALTER TABLE invoices ADD COLUMN remainingAmount REAL DEFAULT 0.0');
        } catch (e) {
          print('Column remainingAmount might already exist: $e');
        }
        try {
          await db.execute('ALTER TABLE invoices ADD COLUMN images TEXT');
        } catch (e) {
          print('Column images might already exist: $e');
        }
      }
      
      // Add profile image field to customers table
      final customersTable = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='customers'");
      if (customersTable.isNotEmpty) {
        try {
          await db.execute('ALTER TABLE customers ADD COLUMN profileImage TEXT');
        } catch (e) {
          print('Column profileImage might already exist: $e');
        }
      }
      
      print('Database upgraded to version 2');
    }
    
    if (oldVersion < 3) {
      // Migrate from products to vehicles
      print('Migrating from products to vehicles...');
      
      // Drop old products table
      await db.execute('DROP TABLE IF EXISTS products');
      
      // Create new vehicles table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vehicles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          stockNo TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          description TEXT,
          priceUSD REAL NOT NULL,
          priceUGX REAL DEFAULT 0.0,
          make TEXT NOT NULL,
          model TEXT NOT NULL,
          year INTEGER NOT NULL,
          chassisNo TEXT,
          engineSize TEXT,
          fuelType TEXT,
          transmission TEXT,
          mileage INTEGER DEFAULT 0,
          color TEXT,
          status TEXT DEFAULT 'inStock',
          isActive INTEGER DEFAULT 1,
          images TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
      
      // Update indexes
      await db.execute('DROP INDEX IF EXISTS idx_products_sku');
      await db.execute('DROP INDEX IF EXISTS idx_products_category');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_vehicles_make ON vehicles(make)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_vehicles_model ON vehicles(model)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status)');
      
      print('Database upgraded to version 3 - Products migrated to Vehicles');
    }
    
    if (oldVersion < 4) {
      // Add tax database tables
      print('Adding tax database tables...');
      
      // Create Vehicle Tax Rates table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vehicle_tax_rates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          make TEXT NOT NULL,
          model TEXT NOT NULL,
          modelCode TEXT,
          bodyType TEXT,
          yearFrom INTEGER NOT NULL,
          yearTo INTEGER NOT NULL,
          engineSizeCC INTEGER NOT NULL,
          fuelType TEXT NOT NULL,
          fobValue REAL NOT NULL,
          customsValue REAL NOT NULL,
          importDuty REAL NOT NULL,
          exciseDuty REAL NOT NULL,
          vat REAL NOT NULL,
          infrastructureLevy REAL DEFAULT 0.0,
          environmentalLevy REAL DEFAULT 0.0,
          withholdingTax REAL DEFAULT 0.0,
          registrationFee REAL DEFAULT 0.0,
          totalTaxUGX REAL NOT NULL,
          databaseMonth TEXT NOT NULL,
          importedAt TEXT NOT NULL,
          importedBy TEXT,
          sourceFile TEXT,
          isActive INTEGER DEFAULT 1,
          notes TEXT,
          CHECK(yearFrom <= yearTo),
          CHECK(totalTaxUGX >= 0)
        )
      ''');
      
      // Create Tax Import History table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tax_import_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fileName TEXT NOT NULL,
          importMonth TEXT NOT NULL,
          importedAt TEXT NOT NULL,
          importedBy TEXT,
          recordsImported INTEGER NOT NULL,
          recordsUpdated INTEGER DEFAULT 0,
          recordsFailed INTEGER DEFAULT 0,
          status TEXT NOT NULL,
          errorLog TEXT,
          notes TEXT,
          CHECK(status IN ('success', 'partial', 'failed'))
        )
      ''');
      
      // Create indexes for vehicle_tax_rates table
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tax_make_model ON vehicle_tax_rates(make, model)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tax_year_range ON vehicle_tax_rates(yearFrom, yearTo)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tax_engine_size ON vehicle_tax_rates(engineSizeCC)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tax_active ON vehicle_tax_rates(isActive)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tax_month ON vehicle_tax_rates(databaseMonth, isActive)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tax_lookup ON vehicle_tax_rates(make, model, yearFrom, yearTo, engineSizeCC, isActive)');
      
      print('Database upgraded to version 4 - Tax database tables added');
    }
    
    if (oldVersion < 5) {
      // Add URA CIF database and exchange rate cache tables
      print('Adding URA CIF database and exchange rate cache tables...');
      
      // Create URA CIF Database Cache table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ura_cif_database (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          hsc_code TEXT,
          country_origin TEXT,
          make TEXT NOT NULL,
          model TEXT NOT NULL,
          year INTEGER NOT NULL,
          engine_cc INTEGER,
          description TEXT,
          cif_usd REAL NOT NULL,
          database_month TEXT NOT NULL,
          downloaded_at TEXT NOT NULL,
          is_active INTEGER DEFAULT 1
        )
      ''');
      
      // Create Exchange Rate Cache table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS exchange_rate_cache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          rate REAL NOT NULL,
          effective_date TEXT NOT NULL,
          source TEXT,
          downloaded_at TEXT NOT NULL,
          is_current INTEGER DEFAULT 1
        )
      ''');
      
      // Create indexes for URA CIF database
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ura_make_model ON ura_cif_database(make, model)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ura_year ON ura_cif_database(year)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ura_engine ON ura_cif_database(engine_cc)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ura_active ON ura_cif_database(is_active)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ura_month ON ura_cif_database(database_month, is_active)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ura_lookup ON ura_cif_database(make, model, year, engine_cc, is_active)');
      
      // Create indexes for exchange rate cache
      await db.execute('CREATE INDEX IF NOT EXISTS idx_exchange_current ON exchange_rate_cache(is_current)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_exchange_date ON exchange_rate_cache(effective_date)');
      
      print('Database upgraded to version 5 - URA database and exchange rate tables added');
    }
    
    if (oldVersion < 6) {
      // Add missing invoice fields: transmission, color, countryOfOrigin
      print('Adding transmission, color, and countryOfOrigin columns to invoices table...');
      
      final invoicesTable = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='invoices'");
      if (invoicesTable.isNotEmpty) {
        try {
          await db.execute('ALTER TABLE invoices ADD COLUMN transmission TEXT');
          print('✅ Added transmission column');
        } catch (e) {
          print('Column transmission might already exist: $e');
        }
        try {
          await db.execute('ALTER TABLE invoices ADD COLUMN color TEXT');
          print('✅ Added color column');
        } catch (e) {
          print('Column color might already exist: $e');
        }
        try {
          await db.execute('ALTER TABLE invoices ADD COLUMN countryOfOrigin TEXT DEFAULT \'JP\'');
          print('✅ Added countryOfOrigin column');
        } catch (e) {
          print('Column countryOfOrigin might already exist: $e');
        }
      }
      
      print('Database upgraded to version 6 - Invoice columns added');
    }
  }

  // Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('payments');
    await db.delete('invoice_items');
    await db.delete('invoices');
    await db.delete('products');
    await db.delete('customers');
  }

  // Force database recreation (for testing)
  Future<void> recreateDatabase() async {
    await close();
    _database = null;
    await database; // This will recreate the database
  }

  // Get database info
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        (SELECT COUNT(*) FROM customers) as customerCount,
        (SELECT COUNT(*) FROM products) as productCount,
        (SELECT COUNT(*) FROM invoices) as invoiceCount,
        (SELECT COUNT(*) FROM payments) as paymentCount
    ''');
    return result.first;
  }

  // Check database schema
  Future<Map<String, List<String>>> getDatabaseSchema() async {
    final db = await database;
    final tables = ['customers', 'products', 'invoices', 'payments'];
    final schema = <String, List<String>>{};
    
    for (final table in tables) {
      try {
        final result = await db.rawQuery('PRAGMA table_info($table)');
        schema[table] = result.map((row) => row['name'] as String).toList();
        print('Table $table columns: ${schema[table]}');
      } catch (e) {
        print('Error getting schema for table $table: $e');
        schema[table] = [];
      }
    }
    
    return schema;
  }
}
