import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/constants/app_constants.dart';
import 'package:smart_expenses_plan/services/theme_service.dart';
import 'package:smart_expenses_plan/services/biometric_service.dart';
import 'package:smart_expenses_plan/presentation/screens/settings/notification_settings.dart';
import 'package:smart_expenses_plan/presentation/screens/settings/terms_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expenses_plan/data/providers/database_provider.dart';
import 'package:smart_expenses_plan/data/repositories/auth_repository.dart';
import 'package:smart_expenses_plan/presentation/screens/backup/backup_setup_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/backup/restore_screen.dart';
import 'package:smart_expenses_plan/services/export_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all your payments, expenses, and settings. '
          'This action cannot be undone. Are you sure?'
        ),
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
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear database
      final db = await DatabaseProvider.instance.database;
      await db.delete('payment_plans');
      await db.delete('expenses');
      await db.delete('settings');
      
      _showSuccessMessage('All data cleared');
    }
  }

  Future<void> _sendFeedback() async {
    try {
      await Share.share(
        'Please provide your feedback for Smart Expenses Plan',
        subject: 'Smart Expenses Plan Feedback',
      );
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Could not share feedback: $e');
      }
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
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

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authRepo = AuthRepository();
      await authRepo.logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // Appearance
          _buildSection(
            'Appearance',
            [
              _buildSwitchTile(
                'Dark Mode',
                'Toggle dark/light theme',
                Icons.dark_mode,
                themeService.isDarkMode,
                (value) {
                  themeService.toggleTheme();
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Backup & Restore
          _buildSection(
            'Backup & Restore',
            [
              _buildListTile(
                'Backup Settings',
                'Configure cloud backup',
                Icons.cloud_upload,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BackupSetupScreen(),
                    ),
                  );
                },
              ),
              _buildListTile(
                'Restore Data',
                'Restore from backup',
                Icons.cloud_download,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestoreScreen(),
                    ),
                  );
                },
              ),
              _buildListTile(
                'Export Data',
                'Export to PDF/Excel/CSV',
                Icons.download,
                () {
                  _showExportOptions();
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Data Management
          _buildSection(
            'Data Management',
            [
              _buildListTile(
                'Clear All Data',
                'Delete all app data',
                Icons.delete_forever,
                _clearAllData,
                color: AppColors.error,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // About
          _buildSection(
            'About',
            [
              _buildListTile(
                'Send Feedback',
                'smartsexpensesganard@gmail.com',
                Icons.feedback,
                _sendFeedback,
              ),
              _buildListTile(
                'Logout',
                'Sign out of your account',
                Icons.logout,
                _logout,
                color: AppColors.error,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Developer Info
          Center(
            child: Column(
              children: [
                Text(
                  'Developed with ❤️',
                  style: TextStyle(
                    color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Developer: Faustine | Manager: Goodluck',
                  style: TextStyle(
                    color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Export Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  _showSuccessMessage('Exporting to PDF...');
                  final exportService = ExportService();
                  final filePath = await exportService.exportToPDF();
                  await exportService.shareFile(filePath);
                  _showSuccessMessage('PDF exported successfully');
                } catch (e) {
                  _showErrorMessage('Failed to export PDF: ${e.toString()}');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_on, color: Colors.green),
              title: const Text('Export as Excel'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  _showSuccessMessage('Exporting to Excel...');
                  final exportService = ExportService();
                  final filePath = await exportService.exportToExcel();
                  await exportService.shareFile(filePath);
                  _showSuccessMessage('Excel exported successfully');
                } catch (e) {
                  _showErrorMessage('Failed to export Excel: ${e.toString()}');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.blue),
              title: const Text('Export as CSV'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  _showSuccessMessage('Exporting to CSV...');
                  final exportService = ExportService();
                  final filePath = await exportService.exportToCSV();
                  await exportService.shareFile(filePath);
                  _showSuccessMessage('CSV exported successfully');
                } catch (e) {
                  _showErrorMessage('Failed to export CSV: ${e.toString()}');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

}