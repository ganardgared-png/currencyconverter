import 'package:sqflite/sqflite.dart';
import 'package:smart_expenses_plan/services/database_service.dart';

class DatabaseProvider {
  static final DatabaseProvider instance = DatabaseProvider._init();

  DatabaseProvider._init();

  Future<Database> get database async {
    return await DatabaseService.instance.database;
  }

  Future<void> insertInitialData(Database db) async {
    // Minimal default settings for initial run
    await db.insert('settings', {'key': 'app_initialized', 'value': 'true'});
  }
}
