import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'migration_helper.dart';
import 'package:path/path.dart' as path;

// #region agent log
void _agentDebugLog(String hypothesisId, String message, Map<String, Object?> data) {
  try {
    final payload = jsonEncode({
      'sessionId': '60ef30',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'hypothesisId': hypothesisId,
      'message': message,
      'data': data,
    });
    File('/home/darksagae/Desktop/NSB/.cursor/debug-60ef30.log')
        .writeAsStringSync('$payload\n', mode: FileMode.append);
  } catch (_) {}
}
// #endregion

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

  /// Call before invoice writes when [onOpen] may not have run (e.g. hot reload kept a stale connection).
  Future<void> repairInvoicesIsFinalizedIfNeeded() async {
    // #region agent log
    _agentDebugLog('H2', 'repairInvoicesIsFinalizedIfNeeded_called', {});
    // #endregion
    final db = await database;
    await _ensureInvoicesIsFinalizedColumn(db);
  }

  Future<Database> _initDatabase() async {
    try {
      String dbPath;
      String dbDir;
      
      if (Platform.isLinux) {
        // Use home directory for Linux
        final homeDir = Platform.environment['HOME'] ?? '/tmp';
        dbDir = homeDir;
        dbPath = path.join(homeDir, 'sales_system.db');
      } else if (Platform.isWindows) {
        // Use AppData\Local for Windows (more reliable than getDatabasesPath)
        final appDataDir = Platform.environment['LOCALAPPDATA'] ?? 
                          Platform.environment['APPDATA'] ?? 
                          path.join(Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public', 'AppData', 'Local');
        dbDir = path.join(appDataDir, 'NSB_Motors_Sales_System');
        dbPath = path.join(dbDir, 'sales_system.db');
      } else {
        // For macOS and other platforms, use getDatabasesPath
        dbDir = await getDatabasesPath();
        dbPath = path.join(dbDir, 'sales_system.db');
      }
      
      // CRITICAL: Ensure the directory exists before opening the database
      final dbDirectory = Directory(dbDir);
      if (!await dbDirectory.exists()) {
        print('Creating database directory: $dbDir');
        await dbDirectory.create(recursive: true);
        print('Database directory created successfully');
      }
      
      print('Initializing database at: $dbPath');
      print('Database directory: $dbDir');
      
      // Verify directory exists and is writable
      if (!await dbDirectory.exists()) {
        throw Exception('Failed to create database directory: $dbDir');
      }
      
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 10,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onOpen: _onDatabaseOpen,
        ),
      );
      
      print('Database initialized successfully at: $dbPath');
      return db;
    } catch (e, stackTrace) {
      print('Error initializing database: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Ensures [isFinalized] exists even if [onUpgrade] did not run (e.g. user_version already 10).
  Future<void> _onDatabaseOpen(Database db) async {
    await _ensureInvoicesIsFinalizedColumn(db);
  }

  /// Idempotent: adds [isFinalized] when missing (repairs partial migrations).
  Future<void> _ensureInvoicesIsFinalizedColumn(Database db) async {
    // #region agent log
    _agentDebugLog('H1', 'onOpen_pragma_invoices', {'stage': 'before_check'});
    // #endregion
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='invoices'",
      );
      if (tables.isEmpty) return;

      final cols = await db.rawQuery('PRAGMA table_info(invoices)');
      final has = cols.any((r) => r['name'] == 'isFinalized');
      // #region agent log
      _agentDebugLog('H1', 'onOpen_isFinalized_column', {
        'hasColumn': has,
        'columnCount': cols.length,
      });
      // #endregion
      if (has) return;

      await db.execute(
        'ALTER TABLE invoices ADD COLUMN isFinalized INTEGER DEFAULT 0',
      );
      print('✅ Repaired invoices: added isFinalized (onOpen lazy migration)');
      // #region agent log
      _agentDebugLog('H1', 'onOpen_alter_success', {'repaired': true});
      // #endregion
    } catch (e, st) {
      print('❌ onOpen isFinalized repair failed: $e');
      // #region agent log
      _agentDebugLog('H1', 'onOpen_alter_failed', {
        'error': e.toString(),
        'stack': st.toString().split('\n').take(4).join('|'),
      });
      // #endregion
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
        vehicleModelSuffix TEXT DEFAULT '',
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
        isFinalized INTEGER NOT NULL DEFAULT 0,
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

    if (oldVersion < 7) {
      // Recalculate invoice totals excluding CIF reference items.
      // CIF is used only as an input/reference for URA tax calculations and must NOT be included in invoice totals.
      try {
        await db.execute('''
          UPDATE invoices
          SET
            subtotal = COALESCE((
              SELECT SUM(ii.price * ii.quantity)
              FROM invoice_items ii
              WHERE ii.invoiceId = invoices.id
                AND NOT (
                  LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                  AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                )
            ), 0.0),
            discountAmount = COALESCE((
              SELECT SUM((ii.price * ii.quantity) * (COALESCE(ii.discount, 0.0) / 100.0))
              FROM invoice_items ii
              WHERE ii.invoiceId = invoices.id
                AND NOT (
                  LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                  AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                )
            ), 0.0),
            taxAmount = COALESCE((
              SELECT SUM(
                ((ii.price * ii.quantity) - ((ii.price * ii.quantity) * (COALESCE(ii.discount, 0.0) / 100.0)))
                * (COALESCE(ii.taxRate, 0.0) / 100.0)
              )
              FROM invoice_items ii
              WHERE ii.invoiceId = invoices.id
                AND NOT (
                  LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                  AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                )
            ), 0.0),
            totalAmount = (
              COALESCE((
                SELECT SUM(ii.price * ii.quantity)
                FROM invoice_items ii
                WHERE ii.invoiceId = invoices.id
                  AND NOT (
                    LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                    AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                  )
              ), 0.0)
              - COALESCE((
                SELECT SUM((ii.price * ii.quantity) * (COALESCE(ii.discount, 0.0) / 100.0))
                FROM invoice_items ii
                WHERE ii.invoiceId = invoices.id
                  AND NOT (
                    LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                    AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                  )
              ), 0.0)
              + COALESCE((
                SELECT SUM(
                  ((ii.price * ii.quantity) - ((ii.price * ii.quantity) * (COALESCE(ii.discount, 0.0) / 100.0)))
                  * (COALESCE(ii.taxRate, 0.0) / 100.0)
                )
                FROM invoice_items ii
                WHERE ii.invoiceId = invoices.id
                  AND NOT (
                    LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                    AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                  )
              ), 0.0)
            ),
            balanceAmount = (
              (
                COALESCE((
                  SELECT SUM(ii.price * ii.quantity)
                  FROM invoice_items ii
                  WHERE ii.invoiceId = invoices.id
                    AND NOT (
                      LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                      AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                    )
                ), 0.0)
                - COALESCE((
                  SELECT SUM((ii.price * ii.quantity) * (COALESCE(ii.discount, 0.0) / 100.0))
                  FROM invoice_items ii
                  WHERE ii.invoiceId = invoices.id
                    AND NOT (
                      LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                      AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                    )
                ), 0.0)
                + COALESCE((
                  SELECT SUM(
                    ((ii.price * ii.quantity) - ((ii.price * ii.quantity) * (COALESCE(ii.discount, 0.0) / 100.0)))
                    * (COALESCE(ii.taxRate, 0.0) / 100.0)
                  )
                  FROM invoice_items ii
                  WHERE ii.invoiceId = invoices.id
                    AND NOT (
                      LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                      AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                    )
                ), 0.0)
              )
              - COALESCE(paidAmount, 0.0)
            )
        ''');
        print('✅ Recalculated invoice totals excluding CIF reference items (v7)');
      } catch (e) {
        print('⚠️ Failed to recalculate invoice totals excluding CIF reference items: $e');
      }
    }

    if (oldVersion < 8) {
      // Ensure URA taxes are always included in totals even when Phase 2 extras are not included.
      // - Compute taxesURA for invoices that can be derived from CIF (carPriceUSD) + exchangeRate + vehicleYear + invoiceDate
      // - Ensure a "Taxes payable to URA" line item exists when taxesURA > 0
      // - Recompute totals excluding CIF reference items (but including URA taxes item)
      try {
        // Compute taxesURA where missing (use same base formula as Invoice Details screen).
        await db.execute('''
          UPDATE invoices
          SET taxesURA = (
            -- CV (UGX)
            (carPriceUSD * exchangeRate) * 0.25 -- Import Duty
            + ((carPriceUSD * exchangeRate) + ((carPriceUSD * exchangeRate) * 0.25)) * 0.18 -- VAT
            + (carPriceUSD * exchangeRate) * 0.06 -- WHT
            + (carPriceUSD * exchangeRate) * 0.015 -- Infrastructure Levy
            + (carPriceUSD * exchangeRate) * 0.01 -- IDF
            + CASE
                WHEN vehicleYear > 0
                 AND CAST(SUBSTR(invoiceDate, 1, 4) AS INTEGER) > 0
                 AND vehicleYear <= (CAST(SUBSTR(invoiceDate, 1, 4) AS INTEGER) - 10)
                THEN (carPriceUSD * exchangeRate) * 0.50
                ELSE 0.0
              END
            + 1500000.0 -- Registration Fee
            + 18000.0 -- Stamp Duty
            + 35000.0 -- Reg Form
          )
          WHERE COALESCE(taxesURA, 0.0) = 0.0
            AND COALESCE(carPriceUSD, 0.0) > 0.0
            AND COALESCE(exchangeRate, 0.0) > 0.0
            AND COALESCE(vehicleYear, 0) > 0
        ''');

        // Insert missing URA tax item when taxesURA is present.
        await db.execute('''
          INSERT INTO invoice_items (invoiceId, productId, productName, description, price, quantity, taxRate, discount)
          SELECT
            i.id,
            NULL,
            'Taxes payable to URA',
            'Import Duty, VAT, WHT, Environmental & Infrastructure Levy, IDF, Stamp, Reg Form',
            i.taxesURA,
            1,
            0.0,
            0.0
          FROM invoices i
          WHERE COALESCE(i.taxesURA, 0.0) > 0.0
            AND NOT EXISTS (
              SELECT 1
              FROM invoice_items ii
              WHERE ii.invoiceId = i.id
                AND LOWER(COALESCE(ii.productName, '')) = 'taxes payable to ura'
            )
        ''');

        // Recompute totals excluding CIF reference items.
        await db.execute('''
          UPDATE invoices
          SET
            subtotal = COALESCE((
              SELECT SUM(ii.price * ii.quantity)
              FROM invoice_items ii
              WHERE ii.invoiceId = invoices.id
                AND NOT (
                  LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                  AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                )
            ), 0.0),
            discountAmount = COALESCE((
              SELECT SUM((ii.price * ii.quantity) * (COALESCE(ii.discount, 0.0) / 100.0))
              FROM invoice_items ii
              WHERE ii.invoiceId = invoices.id
                AND NOT (
                  LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                  AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                )
            ), 0.0),
            taxAmount = COALESCE((
              SELECT SUM(
                ((ii.price * ii.quantity) - ((ii.price * ii.quantity) * (COALESCE(ii.discount, 0.0) / 100.0)))
                * (COALESCE(ii.taxRate, 0.0) / 100.0)
              )
              FROM invoice_items ii
              WHERE ii.invoiceId = invoices.id
                AND NOT (
                  LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                  AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                )
            ), 0.0),
            totalAmount = (
              COALESCE((
                SELECT SUM(ii.price * ii.quantity)
                FROM invoice_items ii
                WHERE ii.invoiceId = invoices.id
                  AND NOT (
                    LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                    AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                  )
              ), 0.0)
              - COALESCE((
                SELECT SUM((ii.price * ii.quantity) * (COALESCE(ii.discount, 0.0) / 100.0))
                FROM invoice_items ii
                WHERE ii.invoiceId = invoices.id
                  AND NOT (
                    LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                    AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                  )
              ), 0.0)
              + COALESCE((
                SELECT SUM(
                  ((ii.price * ii.quantity) - ((ii.price * ii.quantity) * (COALESCE(ii.discount, 0.0) / 100.0)))
                  * (COALESCE(ii.taxRate, 0.0) / 100.0)
                )
                FROM invoice_items ii
                WHERE ii.invoiceId = invoices.id
                  AND NOT (
                    LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                    AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                  )
              ), 0.0)
            ),
            balanceAmount = (
              (
                COALESCE((
                  SELECT SUM(ii.price * ii.quantity)
                  FROM invoice_items ii
                  WHERE ii.invoiceId = invoices.id
                    AND NOT (
                      LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                      AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                    )
                ), 0.0)
                - COALESCE((
                  SELECT SUM((ii.price * ii.quantity) * (COALESCE(ii.discount, 0.0) / 100.0))
                  FROM invoice_items ii
                  WHERE ii.invoiceId = invoices.id
                    AND NOT (
                      LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                      AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                    )
                ), 0.0)
                + COALESCE((
                  SELECT SUM(
                    ((ii.price * ii.quantity) - ((ii.price * ii.quantity) * (COALESCE(ii.discount, 0.0) / 100.0)))
                    * (COALESCE(ii.taxRate, 0.0) / 100.0)
                  )
                  FROM invoice_items ii
                  WHERE ii.invoiceId = invoices.id
                    AND NOT (
                      LOWER(COALESCE(ii.productName, '')) LIKE 'cif (%'
                      AND LOWER(COALESCE(ii.description, '')) LIKE '%reference%'
                    )
                ), 0.0)
              )
              - COALESCE(paidAmount, 0.0)
            )
        ''');

        print('✅ Ensured URA taxes included in totals and backfilled missing URA items (v8)');
      } catch (e) {
        print('⚠️ Failed v8 migration to include URA taxes in totals: $e');
      }
    }

    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE invoices ADD COLUMN vehicleModelSuffix TEXT DEFAULT \'\'');
        print('✅ Added vehicleModelSuffix column to invoices (v9)');
      } catch (e) {
        print('Column vehicleModelSuffix might already exist: $e');
      }
    }

    if (oldVersion < 10) {
      try {
        await db.execute(
          'ALTER TABLE invoices ADD COLUMN isFinalized INTEGER DEFAULT 0',
        );
        print('✅ Added isFinalized column to invoices (v10)');
      } catch (e) {
        print('Column isFinalized might already exist: $e');
      }
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
