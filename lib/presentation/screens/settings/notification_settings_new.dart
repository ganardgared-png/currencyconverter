import 'package:flutter/material.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool _paymentReminders = true;
  bool _expenseReminders = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _reminderTime = 1; // hours before

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _paymentReminders = prefs.getBool('payment_reminders') ?? true;
      _expenseReminders = prefs.getBool('expense_reminders') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _reminderTime = prefs.getInt('reminder_time') ?? 1;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('payment_reminders', _paymentReminders);
    await prefs.setBool('expense_reminders', _expenseReminders);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setInt('reminder_time', _reminderTime);

    // Save notification settings
    NotificationService.initialize(); // Reinitialize with new settings

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification settings saved'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payment,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: const Text('Payment Reminders'),
                    subtitle: const Text('Get notified about upcoming payments'),
                    value: _paymentReminders,
                    onChanged: (value) {
                      setState(() => _paymentReminders = value);
                    },
                    activeColor: AppColors.primary,
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt,
                        color: AppColors.warning,
                        size: 20,
                      ),
                    ),
                    title: const Text('Expense Reminders'),
                    subtitle: const Text('Get notified about expense dates'),
                    value: _expenseReminders,
                    onChanged: (value) {
                      setState(() => _expenseReminders = value);
                    },
                    activeColor: AppColors.warning,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volume_up,
                        color: AppColors.info,
                        size: 20,
                      ),
                    ),
                    title: const Text('Sound'),
                    subtitle: const Text('Play sound for notifications'),
                    value: _soundEnabled,
                    onChanged: (value) {
                      setState(() => _soundEnabled = value);
                    },
                    activeColor: AppColors.info,
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.vibration,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    title: const Text('Vibration'),
                    subtitle: const Text('Vibrate for notifications'),
                    value: _vibrationEnabled,
                    onChanged: (value) {
                      setState(() => _vibrationEnabled = value);
                    },
                    activeColor: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

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
                  const Text(
                    'Reminder Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('1 hour before'),
                    leading: Radio<int>(
                      value: 1,
                      groupValue: _reminderTime,
                      onChanged: (value) {
                        setState(() => _reminderTime = value!);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                  ListTile(
                    title: const Text('3 hours before'),
                    leading: Radio<int>(
                      value: 3,
                      groupValue: _reminderTime,
                      onChanged: (value) {
                        setState(() => _reminderTime = value!);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                  ListTile(
                    title: const Text('1 day before'),
                    leading: Radio<int>(
                      value: 24,
                      groupValue: _reminderTime,
                      onChanged: (value) {
                        setState(() => _reminderTime = value!);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                  ListTile(
                    title: const Text('2 days before'),
                    leading: Radio<int>(
                      value: 48,
                      groupValue: _reminderTime,
                      onChanged: (value) {
                        setState(() => _reminderTime = value!);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Settings'),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}