import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/constants/app_constants.dart';
import 'package:smart_expenses_plan/data/models/user_model.dart';
import 'package:smart_expenses_plan/data/providers/database_provider.dart';
import 'package:smart_expenses_plan/data/repositories/auth_repository.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';
import 'package:smart_expenses_plan/services/biometric_service.dart';
import 'package:smart_expenses_plan/services/google_auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  int _currentStep = 0;
  bool _useBiometric = false;
  bool _biometricAvailable = false;
  bool _isLoading = false;
  GoogleSignInAccount? _googleAccount;
  bool _connectGoogle = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricService.isBiometricAvailable();
    setState(() {
      _biometricAvailable = available;
    });
  }

  void _goToNextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _setupBiometric() async {
    // Note: We don't authenticate here to enable biometric, just like in settings
    // The authentication will be tested when actually logging in
    setState(() {
      _useBiometric = true;
    });
    _proceedToBiometricStep();
  }

  Future<void> _skipBiometric() async {
    _proceedToBiometricStep();
  }

  Future<void> _proceedToSecurityStep() async {
    // Go to Google account step
    _goToNextStep();
  }

  Future<void> _proceedToPinSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user already exists
      final authRepo = AuthRepository();
      final existingUser = await authRepo.getCurrentUser();
      
      if (existingUser != null) {
        print('InitialSetup: User already exists, updating biometric setting');
        // Update existing user with biometric setting
        final db = await DatabaseProvider.instance.database;
        await db.update(
          'users',
          {'use_biometrics': _useBiometric ? 1 : 0},
          where: 'id = ?',
          whereArgs: [existingUser.id],
        );
      } else {
        // Create a default user account
        final user = UserModel(
          username: 'User',
          email: 'user${DateTime.now().millisecondsSinceEpoch}@example.com', // Unique email
          useBiometrics: _useBiometric,
        );
        
        print('InitialSetup: Creating user with biometric: $_useBiometric');
        final id = await authRepo.createUser(user);
        print('InitialSetup: Created user with ID: $id');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.firstLaunchKey, false);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        print('InitialSetup: Navigating to /pin-setup');
        context.push('/pin-setup');
      }
    } catch (e, stackTrace) {
      print('InitialSetup: Error in user setup: $e');
      print('InitialSetup: Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting up account: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _connectGoogleAccount() async {
    try {
      final account = await GoogleAuthService.signInWithGoogle();
      if (account != null) {
        setState(() {
          _googleAccount = account;
          _connectGoogle = true;
        });
        _proceedToBiometricStep();
      }
    } catch (e) {
      print('InitialSetup: Error connecting Google account: $e');
      // Continue without Google account
      _proceedToBiometricStep();
    }
  }

  Future<void> _skipGoogleAccount() async {
    _proceedToBiometricStep();
  }

  Future<void> _createAccount() async {
    await _proceedToBiometricStep();
  }

  Future<void> _proceedToBiometricStep() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user already exists
      final authRepo = AuthRepository();
      final existingUser = await authRepo.getCurrentUser();
      
      if (existingUser != null) {
        print('InitialSetup: User already exists, updating settings');
        // Update existing user
        final db = await DatabaseProvider.instance.database;
        await db.update(
          'users',
          {'use_biometrics': _useBiometric ? 1 : 0},
          where: 'id = ?',
          whereArgs: [existingUser.id],
        );
      } else {
        // Create a new user account
        final user = UserModel(
          username: _googleAccount?.displayName ?? 'User',
          email: _googleAccount?.email ?? 'user${DateTime.now().millisecondsSinceEpoch}@example.com',
          profilePicture: _googleAccount?.photoUrl,
          useBiometrics: _useBiometric,
        );
        
        print('InitialSetup: Creating user with Google account: ${_googleAccount?.email}');
        final id = await authRepo.createUser(user);
        print('InitialSetup: Created user with ID: $id');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.firstLaunchKey, false);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        print('InitialSetup: Navigating to /home');
        context.go('/home');
      }
    } catch (e, stackTrace) {
      print('InitialSetup: Error in biometric step: $e');
      print('InitialSetup: Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting up account: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goToPreviousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 4,
                  minHeight: 8,
                  backgroundColor: isDark ? AppColors.darkSurface : Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildAuthenticationStep(isDark),
                  _buildGoogleAccountStep(isDark),
                  _buildSecurityStep(isDark),
                  _buildAccountStep(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Security Setup',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Protect your account with biometric authentication',
            style: TextStyle(
              color: isDark ? AppColors.darkSubtext : Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_biometricAvailable)
            Column(
              children: [
                CustomButton(
                  text: 'Enable Biometric Login',
                  onPressed: _setupBiometric,
                  isFullWidth: true,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),
              ],
            ),
          CustomButton(
            text: _biometricAvailable ? 'Skip for Now' : 'Continue',
            onPressed: _skipBiometric,
            isFullWidth: true,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticationStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Login Method',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to log in to your account',
            style: TextStyle(
              color: isDark ? AppColors.darkSubtext : Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Sign in with Google',
            onPressed: _proceedToSecurityStep,
            isFullWidth: true,
            color: Colors.blue[600],
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Create Account with Email',
            onPressed: _proceedToSecurityStep,
            isFullWidth: true,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Login Later',
            onPressed: _createAccount,
            isFullWidth: true,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleAccountStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cloud Backup Setup',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your Google account to enable automatic backup and restore',
            style: TextStyle(
              color: isDark ? AppColors.darkSubtext : Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Connect Google Account',
            onPressed: _connectGoogleAccount,
            isFullWidth: true,
            color: Colors.red[600],
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Skip for Now',
            onPressed: _skipGoogleAccount,
            isFullWidth: true,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Setup Complete',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all set! Start managing your expenses today.',
            style: TextStyle(
              color: isDark ? AppColors.darkSubtext : Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Get Started',
            onPressed: _createAccount,
            isFullWidth: true,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
