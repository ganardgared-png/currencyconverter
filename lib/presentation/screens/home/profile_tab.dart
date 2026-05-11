import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/repositories/auth_repository.dart';
import 'package:smart_expenses_plan/data/repositories/income_repository.dart';
import 'package:smart_expenses_plan/data/repositories/payment_repository.dart';
import 'package:smart_expenses_plan/data/repositories/expense_repository.dart';
import 'package:smart_expenses_plan/data/models/user_model.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:smart_expenses_plan/core/utils/export_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_expenses_plan/presentation/screens/backup/backup_setup_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/backup/restore_screen.dart';
import 'package:provider/provider.dart';
import 'package:smart_expenses_plan/services/theme_service.dart';
import 'package:smart_expenses_plan/services/biometric_service.dart';
import 'package:smart_expenses_plan/presentation/screens/settings/notification_settings.dart';
import 'package:smart_expenses_plan/presentation/screens/settings/terms_screen.dart';
import 'package:smart_expenses_plan/data/providers/database_provider.dart';
import 'package:smart_expenses_plan/services/google_auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late AuthRepository _authRepository;
  late IncomeRepository _incomeRepository;
  late PaymentRepository _paymentRepository;
  late ExpenseRepository _expenseRepository;
  UserModel? _user;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  // Settings state
  bool _useBiometrics = false;
  bool _biometricAvailable = false;
  bool _hasAuthentication = false;
  GoogleSignInAccount? _googleAccount;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _incomeRepository = IncomeRepository();
    _paymentRepository = PaymentRepository();
    _expenseRepository = ExpenseRepository();
    _loadUserData();
    _checkBiometrics();
    _checkGoogleSignIn();
  }

  Future<void> _loadUserData() async {
    print('ProfileTab: Starting _loadUserData');
    setState(() => _isLoading = true);

    try {
      print('ProfileTab: Getting current user');
      final user = await _authRepository.getCurrentUser();
      print('ProfileTab: User loaded: ${user?.username}');
      
      print('ProfileTab: Getting incomes');
      final incomes = await _incomeRepository.getAllIncomes();
      print('ProfileTab: Incomes loaded: ${incomes.length}');
      
      print('ProfileTab: Getting payments');
      final payments = await _paymentRepository.getAllPayments();
      print('ProfileTab: Payments loaded: ${payments.length}');
      
      print('ProfileTab: Getting expenses');
      final expenses = await _expenseRepository.getAllExpenses();
      print('ProfileTab: Expenses loaded: ${expenses.length}');
      
      print('ProfileTab: Getting upcoming payments');
      final upcoming = await _paymentRepository.getUpcomingPayments();
      print('ProfileTab: Upcoming payments loaded: ${upcoming.length}');
      
      print('ProfileTab: Getting paid payments');
      final paid = await _paymentRepository.getPaidPayments();
      print('ProfileTab: Paid payments loaded: ${paid.length}');
      
      final totalIncome = incomes.fold(0.0, (sum, income) => sum + income.amount);
      final totalPayments = payments.fold(0.0, (sum, p) => sum + p.amount);
      final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);
      final totalPaidPayments = paid.fold(0.0, (sum, p) => sum + p.amount);

      final hasPin = user?.pin?.isNotEmpty ?? false;
      final hasPassword = user?.password?.isNotEmpty ?? false;

      setState(() {
        _user = user;
        _useBiometrics = user?.useBiometrics ?? false;
        _hasAuthentication = hasPin || hasPassword;
        _stats = {
          'totalPayments': payments.length,
          'totalExpenses': expenses.length,
          'totalPaymentAmount': totalPayments,
          'totalExpenseAmount': totalExpenses,
          'totalIncome': totalIncome,
          'upcomingCount': upcoming.length,
          'paidCount': paid.length,
          'balance': totalIncome - totalExpenses + totalPaidPayments,
        };
        _isLoading = false;
      });
      print('ProfileTab: Data loaded successfully');
      await _checkBiometrics();
    } catch (e) {
      print('ProfileTab: Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final user = _user;
      if (user != null) {
        final useBiometrics = user.useBiometrics;
        final hasPin = user.pin?.isNotEmpty ?? false;
        final hasPassword = user.password?.isNotEmpty ?? false;

        setState(() {
          _useBiometrics = useBiometrics;
          _hasAuthentication = hasPin || hasPassword;
        });
      }
    } catch (e) {
      print('ProfileTab: Error checking biometrics: $e');
    }

    // Also check if biometric is available on device
    final available = await BiometricService.isBiometricAvailable();
    setState(() {
      _biometricAvailable = available;
    });
  }

  Future<void> _checkGoogleSignIn() async {
    try {
      final isSignedIn = await GoogleAuthService.isSignedInWithGoogle();
      if (isSignedIn) {
        final account = await GoogleAuthService.getCurrentGoogleUser();
        setState(() {
          _googleAccount = account;
        });
      }
    } catch (e) {
      print('ProfileTab: Error checking Google sign-in: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: CustomScrollView(
                slivers: [
                  // Profile Header
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            
// Profile Image with edit button
                            Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    image: (_googleAccount?.photoUrl != null || _user?.profilePicture != null)
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              _googleAccount?.photoUrl ?? _user!.profilePicture!
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: (_googleAccount?.photoUrl != null || _user?.profilePicture != null)
                                      ? null
                                      : const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: AppColors.primary,
                                        ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: GestureDetector(
                                    onTap: _editProfile,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                             
                            const SizedBox(height: 16),
                             
                            // User Name
                            Text(
                              _googleAccount?.displayName ?? _user?.username ?? 'User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                             
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                _googleAccount?.email ?? _user?.email ?? 'user@example.com',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Stats Row
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    'Payments',
                                    _getStatInt('totalPayments').toString(),
                                    Icons.payment,
                                  ),
                                  _buildStatItem(
                                    'Expenses',
                                    _getStatInt('totalExpenses').toString(),
                                    Icons.receipt,
                                  ),
                                  _buildStatItem(
                                    'Upcoming',
                                    _getStatInt('upcomingCount').toString(),
                                    Icons.schedule,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Stats Cards
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Balance Card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Text(
                                  'Current Balance',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  CurrencyFormatter.format(_getStatDouble('balance')),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: _stats['balance'] >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Financial Summary
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
                                  'Financial Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildSummaryRow(
                                  'Total Income',
                                  CurrencyFormatter.format(_getStatDouble('totalIncome')),
                                  AppColors.success,
                                ),
                                const Divider(),
                                _buildSummaryRow(
                                  'Total Expenses',
                                  CurrencyFormatter.format(_getStatDouble('totalExpenseAmount')),
                                  AppColors.warning,
                                ),
                                const Divider(),
                                _buildSummaryRow(
                                  'Paid This Month',
                                  CurrencyFormatter.format(_getStatInt('paidCount') * 100000.0), // Example
                                  AppColors.info,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        
                        // Security
                        _buildSettingsSection(
                          'Security',
                          [
                            if (_biometricAvailable)
                              _buildSwitchTile(
                                'Biometric Login',
                                'Use fingerprint/face to login',
                                Icons.fingerprint,
                                _useBiometrics,
                                _toggleBiometrics,
                              ),
                            _buildListTile(
                              'Setup Password',
                              'Update your password',
                              Icons.lock,
                              _changePassword,
                            ),
                            _buildListTile(
                              'Setup PIN',
                              'Create a PIN for quick access',
                              Icons.pin,
                              _setupPin,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Notification Settings
                        _buildSettingsSection(
                          'Notifications',
                          [
                            _buildListTile(
                              'Notification Settings',
                              'Manage reminders and alerts',
                              Icons.notifications,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotificationSettings(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Settings Sections
                        _buildSettingsSection(
                          'Appearance',
                          [
                            _buildSwitchTile(
                              'Dark Mode',
                              'Toggle dark/light theme',
                              Icons.dark_mode,
                              Provider.of<ThemeService>(context).isDarkMode,
                              (value) {
                                Provider.of<ThemeService>(context, listen: false).toggleTheme();
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Backup & Restore
                        _buildSettingsSection(
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
                                    builder: (context) => const BackupSetupScreen(),
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
                                    builder: (context) => const RestoreScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildListTile(
                              'Export Data',
                              'Export to PDF/Excel/CSV',
                              Icons.download,
                              _showExportOptions,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Data Management
                        _buildSettingsSection(
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
                        
                        // About Section
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
                                  'About',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('Version', '1.0.0'),
                                _buildInfoRow('Developer', 'Faustine'),
                                _buildInfoRow('Manager', 'Goodluck'),
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),
                                ListTile(
                                  leading: const Icon(Icons.description, color: AppColors.primary),
                                  title: const Text('Terms of Service'),
                                  subtitle: const Text('Read our terms'),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TermsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.feedback, color: AppColors.primary),
                                  title: const Text('Send Feedback'),
                                  subtitle: const Text('smartsexpensesganard@gmail.com'),
                                  onTap: _sendFeedback,
                                ),
                                ListTile(
                                  leading: const Icon(Icons.logout, color: AppColors.error),
                                  title: const Text(
                                    'Logout',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                  onTap: _showLogoutDialog,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      value: value,
      onChanged: onChanged,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildListTile(String title, String subtitle, IconData icon, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSubtext
                  : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  int _getStatInt(String key) {
    final value = _stats[key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    return 0;
  }

  double _getStatDouble(String key) {
    final value = _stats[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return 0.0;
  }

  Future<void> _toggleBiometrics(bool value) async {
    try {
      final authRepo = AuthRepository();
      final user = _user;
      if (user == null) {
        _showErrorMessage('Unable to update biometric settings');
        return;
      }

      if (value) {
        final hasPin = user.pin?.isNotEmpty ?? false;
        final hasPassword = user.password?.isNotEmpty ?? false;

        if (!hasPin && !hasPassword) {
          final shouldSetupPin = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Setup PIN Required'),
              content: const Text(
                'To enable biometric login, you need a backup authentication method. Would you like to set up a PIN now?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Setup PIN'),
                ),
              ],
            ),
          );

          if (shouldSetupPin == true) {
            if (mounted) {
              context.go('/pin-setup');
            }
          }
          return;
        }
      }

      await authRepo.setUseBiometrics(value);
      final db = await DatabaseProvider.instance.database;
      await db.update(
        'users',
        {'use_biometrics': value ? 1 : 0},
        where: 'id = ?',
        whereArgs: [user.id],
      );

      setState(() {
        _useBiometrics = value;
      });

      if (value) {
        _showSuccessMessage('Biometric authentication enabled');
      } else {
        _showSuccessMessage('Biometric authentication disabled');
      }
    } catch (e) {
      print('ProfileTab: Error toggling biometrics: $e');
      _showErrorMessage('Failed to update biometric settings');
    }
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    try {
      // Try to load current user
      final user = _user;
      
      if (user != null) {
        nameController.text = user.username ?? '';
        emailController.text = user.email ?? '';
      } else {
        if (mounted) {
          _showErrorMessage('Unable to load current user information');
        }
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (nameController.text.isEmpty || emailController.text.isEmpty) {
                    _showErrorMessage('Please fill in all fields');
                    return;
                  }
                  
                  // Validate email format
                  if (!_isValidEmail(emailController.text)) {
                    _showErrorMessage('Please enter a valid email address');
                    return;
                  }
                  
                  print('ProfileTab: Updating user profile');
                  
                  // Save to database
                  final authRepo = AuthRepository();
                  await authRepo.updateUserProfile(
                    username: nameController.text.trim(),
                    email: emailController.text.trim(),
                  );
                  
                  // Reload user data
                  await _loadUserData();
                  
                  if (context.mounted) {
                    _showSuccessMessage('Profile updated successfully');
                    Navigator.pop(context);
                  }
                } catch (e) {
                  print('ProfileTab: Error updating profile: $e');
                  if (context.mounted) {
                    _showErrorMessage('Failed to update profile: Please check your email is unique and try again');
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('ProfileTab: Error in _editProfile: $e');
      _showErrorMessage('Error loading profile: ${e.toString()}');
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(email);
  }

  void _changePassword() async {
    context.push('/password-setup');
  }

  void _setupPin() async {
    context.push('/pin-setup');
  }

  Future<void> _connectGoogle() async {
    try {
      final account = await GoogleAuthService.signInWithGoogle();
      if (account != null && _user != null) {
        // Update user profile with Google account info
        await GoogleAuthService.updateUserProfileFromGoogle(_user!, account);

        // Reload user data and check Google sign-in status
        await _loadUserData();
        await _checkGoogleSignIn();

        _showSuccessMessage('Google account connected successfully');
      } else if (account == null) {
        _showErrorMessage('Google Sign-In was cancelled');
      }
    } on Exception catch (e) {
      print('ProfileTab: Exception connecting Google account: $e');
      _showErrorMessage('Google Sign-In Error: Check your internet connection and Google API configuration');
    } catch (e) {
      print('ProfileTab: Error connecting Google account: $e');
      _showErrorMessage('Failed to connect Google account: $e');
    }
  }

  Future<void> _disconnectGoogle() async {
    try {
      await GoogleAuthService.signOutFromGoogle();

      // Clear Google account info from user profile
      if (_user != null) {
        final authRepo = AuthRepository();
        final updatedUser = UserModel(
          id: _user!.id,
          username: _user!.username, // Keep current username
          email: _user!.email, // Keep current email
          profilePicture: null, // Remove profile picture
          password: _user!.password,
          pin: _user!.pin,
          pattern: _user!.pattern,
          useBiometrics: _user!.useBiometrics,
          income: _user!.income,
          incomeType: _user!.incomeType,
          currency: _user!.currency,
          createdAt: _user!.createdAt,
        );

        await authRepo.updateUser(updatedUser);
      }

      setState(() {
        _googleAccount = null;
      });

      await _loadUserData();
      _showSuccessMessage('Google account disconnected');
    } catch (e) {
      print('ProfileTab: Error disconnecting Google account: $e');
      _showErrorMessage('Failed to disconnect Google account');
    }
  }

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
      await db.delete('incomes');

      _showSuccessMessage('All data cleared');
      await _loadUserData();
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
              onTap: () {
                Navigator.pop(context);
                _exportData('PDF');
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_on, color: Colors.green),
              title: const Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                _exportData('Excel');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.blue),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportData('CSV');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(String format) async {
    try {
      // Show loading dialog
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get all payments, expenses, and incomes
      final payments = await _paymentRepository.getAllPayments();
      final expenses = await _expenseRepository.getAllExpenses();
      final incomes = await _incomeRepository.getAllIncomes();
      
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'SmartExpenses_$timestamp';
      
      String exportPath;
      
      switch (format) {
        case 'PDF':
          exportPath = await ExportHelper.exportToPDF(
            payments: payments,
            expenses: expenses,
            incomes: incomes,
            fileName: fileName,
          );
          break;
        case 'Excel':
          exportPath = await ExportHelper.exportToExcel(
            payments: payments,
            expenses: expenses,
            incomes: incomes,
            fileName: fileName,
          );
          break;
        case 'CSV':
          exportPath = await ExportHelper.exportToCSV(
            payments: payments,
            expenses: expenses,
            incomes: incomes,
            fileName: fileName,
          );
          break;
        default:
          exportPath = '';
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to $exportPath'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendFeedback() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'smartsexpensesganard@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Smart Expenses Plan Feedback',
      }),
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email client'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authRepository.logout();
              if (mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
