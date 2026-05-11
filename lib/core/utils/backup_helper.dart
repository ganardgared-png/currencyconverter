import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:smart_expenses_plan/data/models/payment_plan_model.dart';
import 'package:smart_expenses_plan/data/models/expense_model.dart';
import 'package:smart_expenses_plan/data/models/user_model.dart';
import 'package:smart_expenses_plan/data/providers/database_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class BackupHelper {
  static final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
  static final _iv = encrypt.IV.fromLength(16);
  
  static Future<Map<String, dynamic>> createBackupData() async {
    final db = await DatabaseProvider.instance.database;
    
    // Get all data
    final users = await db.query('users');
    final payments = await db.query('payment_plans');
    final expenses = await db.query('expenses');
    final settings = await db.query('settings');
    
    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'users': users,
        'payments': payments,
        'expenses': expenses,
        'settings': settings,
      },
    };
  }
  
  static Future<String> saveBackupToFile(Map<String, dynamic> backupData) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final path = '${directory.path}/$fileName';
    
    // Encrypt data
    final encrypted = encryptData(jsonEncode(backupData));
    
    final file = File(path);
    await file.writeAsString(encrypted);
    
    return path;
  }
  
  static Future<Map<String, dynamic>> restoreFromFile(String path) async {
    final file = File(path);
    final encrypted = await file.readAsString();
    
    // Decrypt data
    final decrypted = decryptData(encrypted);
    
    return jsonDecode(decrypted);
  }
  
  static Future<void> restoreToDatabase(Map<String, dynamic> backupData) async {
    final db = await DatabaseProvider.instance.database;
    final data = backupData['data'];
    
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('users');
      await txn.delete('payment_plans');
      await txn.delete('expenses');
      await txn.delete('settings');
      
      // Restore users
      for (var user in data['users']) {
        await txn.insert('users', user);
      }
      
      // Restore payments
      for (var payment in data['payments']) {
        await txn.insert('payment_plans', payment);
      }
      
      // Restore expenses
      for (var expense in data['expenses']) {
        await txn.insert('expenses', expense);
      }
      
      // Restore settings
      for (var setting in data['settings']) {
        await txn.insert('settings', setting);
      }
    });
  }
  
  static String encryptData(String data) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(data, iv: _iv);
    return encrypted.base64;
  }
  
  static String decryptData(String encrypted) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final decrypted = encrypter.decrypt64(encrypted, iv: _iv);
    return decrypted;
  }
  
  static Future<List<String>> getBackupFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    
    return files
        .where((file) => file.path.endsWith('.json'))
        .map((file) => file.path)
        .toList();
  }
  
  static Future<void> deleteBackupFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}