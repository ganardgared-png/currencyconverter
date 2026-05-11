import 'package:flutter/material.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/constants/app_constants.dart';
import 'package:smart_expenses_plan/core/utils/backup_helper.dart';
import 'package:smart_expenses_plan/data/repositories/backup_repository.dart';
import 'package:smart_expenses_plan/data/models/backup_model.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';
import 'package:smart_expenses_plan/services/cloud_backup_service.dart';
import 'package:intl/intl.dart';
import 'package:smart_expenses_plan/services/google_auth_service.dart';

class BackupSetupScreen extends StatefulWidget {
  const BackupSetupScreen({super.key});

  @override
  State<BackupSetupScreen> createState() => _BackupSetupScreenState();
}

class _BackupSetupScreenState extends State<BackupSetupScreen> {
  late BackupRepository _backupRepository;
  BackupModel? _backupSettings;
  bool _isLoading = true;

  String _selectedProvider = 'google_drive'; // Only Google Drive is supported
  String _selectedFrequency = 'Never';
  bool _autoBackup = false;
  String? _accountEmail;

  @override
  void initState() {
    super.initState();
    _backupRepository = BackupRepository();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _backupRepository.getBackupSettings();
      final provider = await CloudBackupService.getBackupProvider();
      setState(() {
        _backupSettings = settings;
        _selectedProvider = provider;
        _selectedFrequency = settings?.backupFrequency ?? 'Never';
        _autoBackup = settings?.autoBackupEnabled ?? false;
        _accountEmail = settings?.accountEmail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectCloud() async {
    try {
      print('BackupSetupScreen: Connecting to Google Drive');

      // Use Google Sign-In for Google Drive
      final account = await GoogleAuthService.signInWithGoogle();

      if (account != null) {
        print('BackupSetupScreen: Google Sign-In successful for ${account.email}');

        // Set backup provider to Google Drive
        await CloudBackupService.setBackupProvider('google_drive');

        // Save backup settings with Google account info
        final settings = BackupModel(
          cloudType: 'Google Drive',
          accountEmail: account.email,
          backupFrequency: _selectedFrequency,
          autoBackupEnabled: _autoBackup,
        );

        final success = await _backupRepository.saveBackupSettings(settings);

        if (success && context.mounted) {
          setState(() {
            _accountEmail = account.email;
          });
          _showSuccessMessage('Google Drive connected: ${account.email}');
        } else if (context.mounted) {
          _showErrorMessage('Failed to save backup settings');
        }
      } else {
        print('BackupSetupScreen: Google Sign-In cancelled');
        if (context.mounted) {
          _showErrorMessage('Google Sign-In was cancelled');
        }
      }
    } catch (e) {
      print('BackupSetupScreen: Error connecting to cloud: $e');
      if (context.mounted) {
        _showErrorMessage('Failed to connect: ${e.toString()}');
      }
    }
  }

  Future<void> _disconnectCloud() async {
    try {
      print('BackupSetupScreen: Starting cloud disconnect');

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disconnect Account'),
          content: const Text('Are you sure you want to disconnect your Google Drive account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Disconnect'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Sign out from Google Drive
        await GoogleAuthService.signOutFromGoogle();

        await _backupRepository.disconnectCloud();
        setState(() {
          _accountEmail = null;
          _autoBackup = false;
        });
        _showSuccessMessage('Google Drive account disconnected');
        print('BackupSetupScreen: Google Drive account disconnected');
      }
    } catch (e) {
      print('BackupSetupScreen: Error disconnecting cloud: $e');
      _showErrorMessage('Failed to disconnect: ${e.toString()}');
    }
  }

  Future<void> _performBackup() async {
    try {
      final isAuthenticated = await CloudBackupService.isAuthenticated();
      if (!isAuthenticated) {
        _showErrorMessage('Please connect a cloud account first');
        return;
      }

      print('BackupSetupScreen: Starting backup to $_selectedProvider');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create backup data
      final backupData = await BackupHelper.createBackupData();
      final backupPath = await BackupHelper.saveBackupToFile(backupData);

      // Upload using unified method
      final success = await CloudBackupService.uploadBackup(backupPath);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          await _backupRepository.updateLastBackup();
          _showSuccessMessage('Backup completed successfully');
          print('BackupSetupScreen: Backup completed');
        } else {
          _showErrorMessage('Backup failed');
        }
      }
    } catch (e) {
      print('BackupSetupScreen: Error during backup: $e');
      if (mounted) {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog
        }
        _showErrorMessage('Backup failed: ${e.toString()}');
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      print('BackupSetupScreen: Saving backup settings');

      final settings = BackupModel(
        cloudType: 'Google Drive',
        accountEmail: _accountEmail,
        backupFrequency: _selectedFrequency,
        autoBackupEnabled: _autoBackup,
      );

      final success = await _backupRepository.saveBackupSettings(settings);

      if (success) {
        await CloudBackupService.setBackupProvider('google_drive');
        await CloudBackupService.setAutoBackupEnabled(_autoBackup);
        _showSuccessMessage('Settings saved successfully');
        print('BackupSetupScreen: Settings saved');
      } else {
        _showErrorMessage('Failed to save settings');
        print('BackupSetupScreen: Save returned false');
      }
    } catch (e) {
      print('BackupSetupScreen: Error saving settings: $e');
      _showErrorMessage('Error saving settings: ${e.toString()}');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cloud Account Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Cloud Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (_accountEmail != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.drive_file_move,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Connected to Google Drive',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        _accountEmail!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'Using your personal Google Drive storage',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout, color: AppColors.error),
                                  onPressed: _disconnectCloud,
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Cloud Provider Selection - Only Google Drive
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cloud Provider',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.drive_file_move,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Google Drive',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          Text(
                                            'Your personal Google Drive storage',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          CustomButton(
                            text: 'Connect Google Drive',
                            onPressed: _connectCloud,
                            icon: Icons.drive_file_move,
                            isFullWidth: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Backup Settings Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.settings_backup_restore,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Backup Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Backup Frequency
                        DropdownButtonFormField<String>(
                          value: _selectedFrequency,
                          decoration: InputDecoration(
                            labelText: 'Backup Frequency',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: AppConstants.backupFrequencies.map((freq) {
                            return DropdownMenuItem(
                              value: freq,
                              child: Text(freq),
                            );
                          }).toList(),
                          onChanged: _accountEmail != null
                              ? (value) {
                                  setState(() => _selectedFrequency = value!);
                                }
                              : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Auto Backup Switch
                        SwitchListTile(
                          title: const Text('Auto Backup'),
                          subtitle: const Text('Automatically backup data based on frequency'),
                          value: _autoBackup && _accountEmail != null,
                          onChanged: _accountEmail != null
                              ? (value) {
                                  setState(() => _autoBackup = value);
                                }
                              : null,
                          activeColor: AppColors.primary,
                        ),
                        
                        if (_backupSettings?.lastBackup != null) ...[
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.access_time, color: Colors.grey),
                            title: const Text('Last Backup'),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy HH:mm').format(
                                _backupSettings!.lastBackup!,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Actions Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CustomButton(
                          text: 'Backup Now',
                          onPressed: _performBackup,
                          icon: Icons.cloud_upload,
                          isFullWidth: true,
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Save Settings',
                          onPressed: _saveSettings,
                          icon: Icons.save,
                          isFullWidth: true,
                          isOutlined: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: AppColors.info.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: AppColors.info),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Backup Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your data is encrypted before being uploaded to the cloud. '
                                'Regular backups ensure you never lose your financial data.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkSubtext : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}