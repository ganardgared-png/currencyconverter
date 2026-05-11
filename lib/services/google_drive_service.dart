import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:smart_expenses_plan/services/google_auth_service.dart';

class GoogleDriveService {
  static const String _driveApiUrl = 'https://www.googleapis.com/drive/v3';
  static const String _uploadUrl = 'https://www.googleapis.com/upload/drive/v3/files';

  static Future<String?> getAccessToken() async {
    try {
      return await GoogleAuthService.getAccessToken();
    } catch (e) {
      print('GoogleDriveService: Error getting access token: $e');
      return null;
    }
  }

  static Future<bool> isSignedIn() async {
    try {
      return await GoogleAuthService.isSignedInWithGoogle();
    } catch (e) {
      print('GoogleDriveService: Error checking sign-in status: $e');
      return false;
    }
  }

  static Future<String?> uploadBackupToDrive(String filePath, String fileName) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file does not exist');
      }

      // Create metadata for the file
      final metadata = {
        'name': fileName,
        'parents': ['appDataFolder'], // Store in app data folder
        'description': 'Smart Expenses Plan Backup - ${DateTime.now().toIso8601String()}',
      };

      // Create multipart request
      final uri = Uri.parse('$_uploadUrl?uploadType=multipart');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..fields['metadata'] = jsonEncode(metadata)
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        print('GoogleDriveService: Backup uploaded successfully. File ID: ${data['id']}');
        return data['id'];
      } else {
        print('GoogleDriveService: Upload failed with status ${response.statusCode}: $responseBody');
        return null;
      }
    } catch (e) {
      print('GoogleDriveService: Error uploading backup: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> listBackupFiles() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final query = "name contains 'smart_expenses_backup' and trashed = false";
      final uri = Uri.parse('$_driveApiUrl/files?q=${Uri.encodeQueryComponent(query)}&spaces=appDataFolder&fields=files(id,name,createdTime,size,description)');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List<dynamic>;

        return files.map((file) => {
          'id': file['id'],
          'name': file['name'],
          'createdTime': file['createdTime'],
          'size': file['size'] ?? 0,
          'description': file['description'] ?? '',
        }).toList();
      } else {
        print('GoogleDriveService: List files failed with status ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('GoogleDriveService: Error listing backup files: $e');
      return [];
    }
  }

  static Future<String?> downloadBackupFromDrive(String fileId) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final uri = Uri.parse('$_driveApiUrl/files/$fileId?alt=media');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        // Save to temporary directory
        final tempDir = await getTemporaryDirectory();
        final fileName = 'downloaded_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
        final filePath = '${tempDir.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        print('GoogleDriveService: Backup downloaded successfully to $filePath');
        return filePath;
      } else {
        print('GoogleDriveService: Download failed with status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('GoogleDriveService: Error downloading backup: $e');
      return null;
    }
  }

  static Future<bool> deleteBackupFromDrive(String fileId) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final uri = Uri.parse('$_driveApiUrl/files/$fileId');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 204) {
        print('GoogleDriveService: Backup deleted successfully');
        return true;
      } else {
        print('GoogleDriveService: Delete failed with status ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('GoogleDriveService: Error deleting backup: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getFileInfo(String fileId) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final uri = Uri.parse('$_driveApiUrl/files/$fileId?fields=id,name,createdTime,size,description');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('GoogleDriveService: Get file info failed with status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('GoogleDriveService: Error getting file info: $e');
      return null;
    }
  }
}