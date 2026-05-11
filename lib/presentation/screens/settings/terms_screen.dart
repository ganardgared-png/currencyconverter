import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expenses_plan/core/constants/app_constants.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _accepted = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.description,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Terms of Service',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Last updated: ${DateTime.now().year}',
                      style: TextStyle(
                        color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      '1. Acceptance of Terms',
                      'By accessing or using Smart Expenses Plan, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any part of these terms, you may not use our services.',
                    ),
                    
                    _buildSection(
                      '2. User Accounts',
                      'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account.',
                    ),
                    
                    _buildSection(
                      '3. Privacy',
                      'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your personal information. By using our services, you consent to our data practices as described in the Privacy Policy.',
                    ),
                    
                    _buildSection(
                      '4. Financial Data',
                      'Smart Expenses Plan is a tool to help you track your expenses and payments. We are not a financial institution and do not provide financial advice. You are solely responsible for your financial decisions.',
                    ),
                    
                    _buildSection(
                      '5. Data Backup',
                      'We recommend regularly backing up your data. While we provide backup features, we are not responsible for any loss of data. You should maintain your own backups of important information.',
                    ),
                    
                    _buildSection(
                      '6. Prohibited Activities',
                      'You agree not to: (a) use the service for any illegal purpose; (b) attempt to gain unauthorized access to our systems; (c) interfere with the proper functioning of the service; (d) bypass any measures we may use to prevent or restrict access.',
                    ),
                    
                    _buildSection(
                      '7. Termination',
                      'We may terminate or suspend your account and access to the service immediately, without prior notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties.',
                    ),
                    
                    _buildSection(
                      '8. Changes to Terms',
                      'We reserve the right to modify these terms at any time. We will notify you of any changes by posting the new terms on this page. Your continued use of the service after such modifications constitutes your acceptance of the new terms.',
                    ),
                    
                    _buildSection(
                      '9. Contact Information',
                      'If you have any questions about these Terms, please contact us at:\nEmail: smartsexpensesganard@gmail.com\nDeveloper: Faustine\nManager: Goodluck',
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSubtext
                  : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

}