import 'package:smart_expenses_plan/data/providers/database_provider.dart';
import 'package:smart_expenses_plan/data/models/backup_model.dart';

class BackupRepository {
  final DatabaseProvider _databaseProvider = DatabaseProvider.instance;
  
  Future<bool> saveBackupSettings(BackupModel backup) async {
    try {
      final db = await _databaseProvider.database;
      
      // Check if settings exist
      final List<Map<String, dynamic>> existing = await db.query(
        'backup_settings',
        limit: 1,
      );
      
      if (existing.isEmpty) {
        final result = await db.insert('backup_settings', backup.toMap());
        print('BackupRepository: Backup settings inserted with id: $result');
        return result > 0;
      } else {
        final result = await db.update(
          'backup_settings',
          backup.toMap(),
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
        print('BackupRepository: Backup settings updated, rows affected: $result');
        return result > 0;
      }
    } catch (e) {
      print('BackupRepository: Error saving backup settings: $e');
      rethrow;
    }
  }
  
  Future<BackupModel?> getBackupSettings() async {
    try {
      final db = await _databaseProvider.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'backup_settings',
        limit: 1,
      );
      
      if (maps.isEmpty) {
        print('BackupRepository: No backup settings found');
        return null;
      }
      
      print('BackupRepository: Backup settings loaded');
      return BackupModel.fromMap(maps.first);
    } catch (e) {
      print('BackupRepository: Error getting backup settings: $e');
      rethrow;
    }
  }
  
  Future<void> updateLastBackup() async {
    try {
      final settings = await getBackupSettings();
      if (settings != null) {
        final updated = settings.copyWith(
          lastBackup: DateTime.now(),
        );
        await saveBackupSettings(updated);
        print('BackupRepository: Last backup timestamp updated');
      }
    } catch (e) {
      print('BackupRepository: Error updating last backup: $e');
      rethrow;
    }
  }
  
  Future<void> clearBackupSettings() async {
    try {
      final db = await _databaseProvider.database;
      await db.delete('backup_settings');
      print('BackupRepository: Backup settings cleared');
    } catch (e) {
      print('BackupRepository: Error clearing backup settings: $e');
      rethrow;
    }
  }
  
  Future<bool> shouldPerformBackup() async {
    try {
      final settings = await getBackupSettings();
      if (settings == null || !settings.autoBackupEnabled) {
        print('BackupRepository: Auto backup disabled or no settings found');
        return false;
      }
      
      if (settings.lastBackup == null) {
        print('BackupRepository: No last backup found, should perform backup');
        return true;
      }
      
      final now = DateTime.now();
      final lastBackup = settings.lastBackup!;
      
      final shouldBackup = switch (settings.backupFrequency) {
        'Daily' => now.difference(lastBackup).inDays >= 1,
        'Weekly' => now.difference(lastBackup).inDays >= 7,
        'Monthly' => now.difference(lastBackup).inDays >= 30,
        _ => false,
      };
      
      print('BackupRepository: Should perform backup: $shouldBackup');
      return shouldBackup;
    } catch (e) {
      print('BackupRepository: Error checking if backup should run: $e');
      return false;
    }
  }
  
  Future<String?> getCloudAccount() async {
    try {
      final settings = await getBackupSettings();
      print('BackupRepository: Cloud account retrieved: ${settings?.accountEmail}');
      return settings?.accountEmail;
    } catch (e) {
      print('BackupRepository: Error getting cloud account: $e');
      rethrow;
    }
  }
  
  Future<void> setCloudAccount(String email) async {
    try {
      final settings = await getBackupSettings() ??
          BackupModel(
            cloudType: 'Google Drive',
            backupFrequency: 'Never',
          );
      
      final updated = settings.copyWith(accountEmail: email);
      await saveBackupSettings(updated);
      print('BackupRepository: Cloud account set to: $email');
    } catch (e) {
      print('BackupRepository: Error setting cloud account: $e');
      rethrow;
    }
  }
  
  Future<void> disconnectCloud() async {
    try {
      final settings = await getBackupSettings();
      if (settings != null) {
        final updated = settings.copyWith(
          accountEmail: null,
          autoBackupEnabled: false,
        );
        await saveBackupSettings(updated);
        print('BackupRepository: Cloud account disconnected');
      }
    } catch (e) {
      print('BackupRepository: Error disconnecting cloud: $e');
      rethrow;
    }
  }
}