import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';

class LanguageSettings extends StatefulWidget {
  const LanguageSettings({super.key});

  @override
  State<LanguageSettings> createState() => _LanguageSettingsState();
}

class _LanguageSettingsState extends State<LanguageSettings> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _selectedLanguage = context.locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
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
            child: Column(
              children: [
                _buildLanguageTile(
                  'English',
                  'English',
                  'en',
                  Icons.language,
                ),
                const Divider(),
                _buildLanguageTile(
                  'Swahili',
                  'Kiswahili',
                  'sw',
                  Icons.language,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Preview Card
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
                    'Preview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.home, color: AppColors.primary),
                          title: Text(tr('home')),
                          subtitle: Text(tr('recent_activity')),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.payment, color: AppColors.success),
                          title: Text(tr('add_payment')),
                          subtitle: Text(tr('payment_name')),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.settings, color: AppColors.warning),
                          title: Text(tr('settings')),
                          subtitle: Text(tr('notifications')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _changeLanguage,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Apply Language'),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(
    String language,
    String nativeName,
    String code,
    IconData icon,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Text(
          code.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      title: Text(language),
      subtitle: Text(nativeName),
      trailing: Radio<String>(
        value: code,
        groupValue: _selectedLanguage,
        onChanged: (value) {
          setState(() {
            _selectedLanguage = value!;
          });
        },
        activeColor: AppColors.primary,
      ),
      onTap: () {
        setState(() {
          _selectedLanguage = code;
        });
      },
    );
  }

  void _changeLanguage() {
    context.setLocale(Locale(_selectedLanguage));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language changed to ${_selectedLanguage == 'en' ? 'English' : 'Swahili'}'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    
    Navigator.pop(context);
  }
}