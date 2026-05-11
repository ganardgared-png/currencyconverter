import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expenses_plan/data/providers/database_provider.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDB('smart_expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }
  
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }
  
  Future _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        email TEXT UNIQUE,
        profile_picture TEXT,
        password TEXT,
        pin TEXT,
        pattern TEXT,
        use_biometrics INTEGER DEFAULT 0,
        income REAL DEFAULT 0,
        income_type TEXT DEFAULT 'monthly',
        currency TEXT DEFAULT 'TZS',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');
    
    // Payment plans table
    await db.execute('''
      CREATE TABLE payment_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pay_name TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'TZS',
        bill_type TEXT NOT NULL,
        reference_type TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        payer_name TEXT,
        payee_name TEXT,
        payment_method TEXT NOT NULL,
        payer_service TEXT,
        payee_service TEXT,
        fees REAL DEFAULT 0,
        total_amount REAL,
        reminder_enabled INTEGER DEFAULT 1,
        notes TEXT,
        status TEXT DEFAULT 'upcoming',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        expense_date TEXT NOT NULL,
        reminder_enabled INTEGER DEFAULT 1,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Incomes table
    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        income_date TEXT NOT NULL,
        recurring INTEGER DEFAULT 0,
        frequency TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE,
        value TEXT,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // CRDB Bank charges table
    await db.execute('''
      CREATE TABLE crdb_charges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        min_amount INTEGER,
        max_amount INTEGER,
        transfer_to_same_bank INTEGER,
        transfer_to_other_bank INTEGER,
        transfer_to_mobile_service INTEGER,
        payment INTEGER
      )
    ''');
    
    // NMB Bank charges table
    await db.execute('''
      CREATE TABLE nmb_charges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        min_amount INTEGER,
        max_amount INTEGER,
        transfer_to_same_bank INTEGER,
        transfer_to_other_bank INTEGER,
        transfer_to_mobile_service INTEGER,
        payment INTEGER
      )
    ''');
    
    // Azania Bank charges table
    await db.execute('''
      CREATE TABLE azania_charges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        min_amount INTEGER,
        max_amount INTEGER,
        transfer_to_same_bank INTEGER,
        transfer_to_other_bank INTEGER,
        transfer_to_mobile_service INTEGER,
        payment INTEGER
      )
    ''');
    
    // M-Pesa charges table
    await db.execute('''
      CREATE TABLE mpesa_charges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        min_amount INTEGER,
        max_amount INTEGER,
        transfer_to_same_network INTEGER,
        transfer_to_other_network INTEGER,
        transfer_to_bank INTEGER,
        payment INTEGER
      )
    ''');
    
    // Airtel charges table
    await db.execute('''
      CREATE TABLE airtel_charges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        min_amount INTEGER,
        max_amount INTEGER,
        transfer_to_same_network INTEGER,
        transfer_to_other_network INTEGER,
        transfer_to_bank INTEGER,
        payment INTEGER
      )
    ''');
    
    // Halopesa charges table
    await db.execute('''
      CREATE TABLE halopesa_charges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        min_amount INTEGER,
        max_amount INTEGER,
        transfer_to_same_network INTEGER,
        transfer_to_other_network INTEGER,
        transfer_to_bank INTEGER,
        payment INTEGER
      )
    ''');
    
    // Mix charges table
    await db.execute('''
      CREATE TABLE mix_charges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        min_amount INTEGER,
        max_amount INTEGER,
        transfer_to_same_network INTEGER,
        transfer_to_other_network INTEGER,
        transfer_to_bank INTEGER,
        payment INTEGER
      )
    ''');
    
    // Backup settings table
    await db.execute('''
      CREATE TABLE backup_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cloud_type TEXT,
        account_email TEXT,
        backup_frequency TEXT,
        last_backup TEXT,
        auto_backup_enabled INTEGER DEFAULT 0
      )
    ''');
  }
  
  Future<void> initialize() async {
    final db = await database;

    // Insert initial data directly without circular dependency
    await db.insert('settings', {'key': 'app_initialized', 'value': 'true'});

    // Create default user if none exists and store id in SharedPreferences.
    final userCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'));
    final prefs = await SharedPreferences.getInstance();

    if (userCount == 0) {
      final userId = await db.insert('users', {
        'username': 'Default User',
        'email': 'user@example.com',
        'password': 'password123', // In production, this should be hashed
        'income': 0.0,
        'income_type': 'monthly',
        'currency': 'TZS',
        'use_biometrics': 0,
      });
      await prefs.setInt('user_id', userId);
    } else {
      final existingUserId = prefs.getInt('user_id');
      if (existingUserId == null) {
        final firstUser = await db.query('users', limit: 1);
        if (firstUser.isNotEmpty && firstUser.first['id'] != null) {
          await prefs.setInt('user_id', firstUser.first['id'] as int);
        }
      }
    }
  }
  
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}