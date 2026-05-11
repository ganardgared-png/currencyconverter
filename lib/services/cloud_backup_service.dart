import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:smart_expenses_plan/core/utils/backup_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expenses_plan/services/google_drive_service.dart';

class CloudBackupService {
  static const String _lastBackupKey = 'last_backup_timestamp';
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';
  static const String _backupProviderKey = 'backup_provider'; // Always 'google_drive'

  /// Upload backup to Google Drive
  static Future<bool> uploadToGoogleDrive(String filePath) async {
    try {
      final isSignedIn = await GoogleDriveService.isSignedIn();
      if (!isSignedIn) {
        print('CloudBackupService: User not signed in to Google Drive');
        throw Exception('User not signed in to Google Drive');
      }

      print('CloudBackupService: Starting Google Drive upload for $filePath');

      final fileName = 'smart_expenses_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
      final fileId = await GoogleDriveService.uploadBackupToDrive(filePath, fileName);

      if (fileId != null) {
        // Update last backup timestamp in preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());

        print('CloudBackupService: Google Drive upload completed');
        return true;
      } else {
        print('CloudBackupService: Google Drive upload failed');
        return false;
      }
    } catch (e) {
      print('CloudBackupService: Error uploading to Google Drive: $e');
      return false;
    }
  }

  /// Download backup from Google Drive
  static Future<String?> downloadFromGoogleDrive(String fileId) async {
    try {
      final isSignedIn = await GoogleDriveService.isSignedIn();
      if (!isSignedIn) {
        print('CloudBackupService: User not signed in to Google Drive');
        return null;
      }

      print('CloudBackupService: Starting Google Drive download');

      final filePath = await GoogleDriveService.downloadBackupFromDrive(fileId);

      if (filePath != null) {
        print('CloudBackupService: Google Drive download completed to $filePath');
        return filePath;
      } else {
        print('CloudBackupService: Google Drive download failed');
        return null;
      }
    } catch (e) {
      print('CloudBackupService: Error downloading from Google Drive: $e');
      return null;
    }
  }

  /// List all backups from Google Drive
  static Future<List<Map<String, dynamic>>> listGoogleDriveBackups() async {
    try {
      final isSignedIn = await GoogleDriveService.isSignedIn();
      if (!isSignedIn) {
        print('CloudBackupService: User not signed in to Google Drive');
        return [];
      }

      print('CloudBackupService: Listing Google Drive backups');

      final backups = await GoogleDriveService.listBackupFiles();

      print('CloudBackupService: Found ${backups.length} Google Drive backups');
      return backups;
    } catch (e) {
      print('CloudBackupService: Error listing Google Drive backups: $e');
      return [];
    }
  }

  /// Delete a specific backup from Google Drive
  static Future<bool> deleteGoogleDriveBackup(String fileId) async {
    try {
      final isSignedIn = await GoogleDriveService.isSignedIn();
      if (!isSignedIn) {
        print('CloudBackupService: User not signed in to Google Drive');
        return false;
      }

      print('CloudBackupService: Deleting Google Drive backup: $fileId');

      final success = await GoogleDriveService.deleteBackupFromDrive(fileId);

      if (success) {
        print('CloudBackupService: Google Drive backup deleted');
        return true;
      } else {
        print('CloudBackupService: Google Drive backup deletion failed');
        return false;
      }
    } catch (e) {
      print('CloudBackupService: Error deleting Google Drive backup: $e');
      return false;
    }
  }

  /// Unified upload method (always uses Google Drive)
  static Future<bool> uploadBackup(String filePath) async {
    return await uploadToGoogleDrive(filePath);
  }

  /// Unified download method (always uses Google Drive)
  static Future<String?> downloadBackup(String identifier) async {
    return await downloadFromGoogleDrive(identifier);
  }

  /// Unified list backups method (always uses Google Drive)
  static Future<List<Map<String, dynamic>>> listBackups() async {
    return await listGoogleDriveBackups();
  }

  /// Unified delete backup method (always uses Google Drive)
  static Future<bool> deleteBackup(String identifier) async {
    return await deleteGoogleDriveBackup(identifier);
  }

  /// Check if user is authenticated (Google Drive)
  static Future<bool> isAuthenticated() async {
    return await GoogleDriveService.isSignedIn();
  }

  /// Perform auto backup if enabled
  static Future<bool> performAutoBackup() async {
    try {
      print('CloudBackupService: Starting auto backup');

      final prefs = await SharedPreferences.getInstance();
      final isAutoBackupEnabled = prefs.getBool(_autoBackupEnabledKey) ?? false;

      if (!isAutoBackupEnabled) {
        print('CloudBackupService: Auto backup is disabled');
        return false;
      }

      final isAuthenticated = await GoogleDriveService.isSignedIn();
      if (!isAuthenticated) {
        print('CloudBackupService: User not authenticated for auto backup');
        return false;
      }

      // Create backup
      final backupData = await BackupHelper.createBackupData();
      final backupPath = await BackupHelper.saveBackupToFile(backupData);

      // Upload to Google Drive
      final success = await uploadToGoogleDrive(backupPath);

      if (success) {
        print('CloudBackupService: Auto backup completed successfully');
      }

      return success;
    } catch (e) {
      print('CloudBackupService: Error performing auto backup: $e');
      return false;
    }
  }

  /// Enable or disable auto backup
  static Future<void> setAutoBackupEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoBackupEnabledKey, enabled);
      print('CloudBackupService: Auto backup ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('CloudBackupService: Error setting auto backup: $e');
    }
  }

  /// Get last backup timestamp
  static Future<DateTime?> getLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastBackupKey);

      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      print('CloudBackupService: Error getting last backup time: $e');
      return null;
    }
  }

  /// Set backup provider (always 'google_drive')
  static Future<void> setBackupProvider(String provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupProviderKey, 'google_drive'); // Always set to google_drive
      print('CloudBackupService: Backup provider set to google_drive');
    } catch (e) {
      print('CloudBackupService: Error setting backup provider: $e');
    }
  }

  /// Get current backup provider (always 'google_drive')
  static Future<String> getBackupProvider() async {
    return 'google_drive'; // Always return google_drive
  }
}
