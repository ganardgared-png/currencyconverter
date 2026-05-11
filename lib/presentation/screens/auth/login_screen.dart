import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/repositories/auth_repository.dart';
import 'package:smart_expenses_plan/services/biometric_service.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

enum AuthMethod { password, pin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  AuthMethod _selectedAuthMethod = AuthMethod.password;
  bool _authMethodDetermined = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  
  @override
  void initState() {
    super.initState();
    _checkIfLockWasSet();
  }
  
  Future<void> _checkIfLockWasSet() async {
    try {
      final authRepo = AuthRepository();
      final user = await authRepo.getCurrentUser();
      
      if (user == null) {
        // No user logged in, go to login
        if (mounted) {
          context.go('/login');
        }
        return;
      }
      
      // Check if user has PIN or password authentication
      final hasPin = user.pin != null && user.pin!.isNotEmpty;
      final hasPassword = user.password != null && user.password!.isNotEmpty;
      final useBiometrics = user.useBiometrics ?? false;
      
      print('Login: User has PIN: $hasPin, Password: $hasPassword, Biometric: $useBiometrics');
      
      // Check biometric availability
      final biometricAvailable = await BiometricService.isBiometricAvailable();
      
      setState(() {
        _biometricEnabled = useBiometrics;
        _biometricAvailable = biometricAvailable;
      });
      
      // If no authentication is set up, go directly to home
      if (!hasPin && !hasPassword && !useBiometrics) {
        if (mounted) {
          context.go('/home');
        }
        return;
      }
      
      // Determine which authentication method to show
      // Prioritize PIN over password if both exist (shouldn't happen but handle gracefully)
      if (hasPin) {
        _selectedAuthMethod = AuthMethod.pin;
      } else if (hasPassword) {
        _selectedAuthMethod = AuthMethod.password;
      } else {
        // No authentication method set, but biometrics enabled - still show login screen
        _selectedAuthMethod = AuthMethod.password; // Default to password input (though it won't work)
      }
      
      setState(() {
        _authMethodDetermined = true;
      });
      
      // If biometrics is enabled, show biometric prompt automatically
      if (useBiometrics && biometricAvailable) {
        _checkBiometrics(autoPopup: true);
      }
    } catch (e) {
      print('Login: Error checking authentication: $e');
      // On error, go to login
      if (mounted) {
        context.go('/login');
      }
    }
  }
  
  Future<void> _checkBiometrics({bool autoPopup = false}) async {
    if (_biometricAvailable) {
      if (autoPopup) {
        // Auto-popup biometric authentication
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showBiometricPrompt();
        });
      }
    }
  }
  
  Future<void> _showBiometricPrompt() async {
    try {
      final isAuthenticated = await BiometricService.authenticate();
      if (isAuthenticated) {
        _navigateToHome();
      } else {
        // Biometric failed or cancelled, user can try again or use PIN/password
        print('Login: Biometric authentication failed or cancelled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication failed. Please try again or use PIN/password.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Login: Error during biometric authentication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric authentication error: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  void _navigateToHome() {
    if (mounted) {
      context.go('/home');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    left: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Authentication Content
            Expanded(
              child: _authMethodDetermined 
                ? _buildAuthContent()
                : const Center(child: CircularProgressIndicator()),
            ),
            
            // Biometric Option
            if (_biometricEnabled && _biometricAvailable)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showBiometricPrompt,
                      icon: Icon(
                        Icons.fingerprint,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      label: Text(
                        'Use Biometrics',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAuthContent() {
    switch (_selectedAuthMethod) {
      case AuthMethod.password:
        return _buildPasswordInput();
      case AuthMethod.pin:
        return _buildPinInput();
      default:
        return _buildPasswordInput();
    }
  }

  Widget _buildPasswordInput() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _loginWithPassword,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Login'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Forgot password
            },
            child: const Text('Forgot Password?'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPinInput() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PinCodeTextField(
            appContext: context,
            length: 4,
            controller: _pinController,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(8),
              fieldHeight: 50,
              fieldWidth: 50,
              activeFillColor: AppColors.primary.withOpacity(0.1),
              inactiveFillColor: Colors.grey.withOpacity(0.1),
              selectedFillColor: AppColors.primary.withOpacity(0.2),
              activeColor: AppColors.primary,
              inactiveColor: Colors.grey,
              selectedColor: AppColors.primary,
            ),
            onCompleted: (pin) {
              _loginWithPin(pin);
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _loginWithPin(_pinController.text),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Login'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _loginWithPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authRepo = AuthRepository();
      final user = await authRepo.getCurrentUser();
      
      if (user != null && user.password == password) {
        print('Login: Password authentication successful');
        _navigateToHome();
      } else {
        print('Login: Password authentication failed');
        _showErrorMessage('Invalid password');
      }
    } catch (e) {
      print('Login: Error during password authentication: $e');
      _showErrorMessage('Authentication error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loginWithPin(String pin) async {
    if (pin.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authRepo = AuthRepository();
      final user = await authRepo.loginWithPin(pin);
      
      if (user != null) {
        print('Login: PIN authentication successful');
        _navigateToHome();
      } else {
        print('Login: PIN authentication failed');
        _showErrorMessage('Invalid PIN');
      }
    } catch (e) {
      print('Login: Error during PIN authentication: $e');
      _showErrorMessage('Authentication error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}