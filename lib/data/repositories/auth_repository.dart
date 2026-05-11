import 'package:smart_expenses_plan/data/providers/database_provider.dart';
import 'package:smart_expenses_plan/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final DatabaseProvider _databaseProvider = DatabaseProvider.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId == null) return null;
    
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (maps.isEmpty) return null;
    
    return UserModel.fromMap(maps.first);
  }
  
  Future<int> createUser(UserModel user) async {
    final db = await _databaseProvider.database;
    final id = await db.insert('users', user.toMap());
    
    // Save user ID to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
    
    return id;
  }
  
  Future<UserModel?> loginWithPassword(String email, String password) async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    
    if (maps.isEmpty) return null;
    
    final user = UserModel.fromMap(maps.first);
    
    // Save user ID to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id!);
    
    return user;
  }
  
  Future<UserModel?> loginWithPin(String pin) async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'pin = ?',
      whereArgs: [pin],
    );
    
    if (maps.isEmpty) return null;
    
    final user = UserModel.fromMap(maps.first);
    
    // Save user ID to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id!);
    
    return user;
  }
  
  Future<UserModel?> loginWithPattern(String pattern) async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'pattern = ?',
      whereArgs: [pattern],
    );
    
    if (maps.isEmpty) return null;
    
    final user = UserModel.fromMap(maps.first);
    
    // Save user ID to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id!);
    
    return user;
  }
  
  Future<bool> hasPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_password') ?? false;
  }
  
  Future<void> setHasPassword(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_password', value);
  }
  
  Future<bool> useBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('use_biometrics') ?? false;
  }
  
  Future<void> setUseBiometrics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_biometrics', value);
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('has_password');
    await prefs.remove('use_biometrics');
  }
  
  Future<void> updateUserProfile({required String username, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId == null) throw Exception('No user logged in');
    
    final db = await _databaseProvider.database;
    await db.update(
      'users',
      {
        'username': username,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
  
  Future<void> updateUser(UserModel user) async {
    final db = await _databaseProvider.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
  
  Future<void> saveSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  Future<String?> getSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }
}