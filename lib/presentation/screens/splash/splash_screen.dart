import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expenses_plan/core/constants/app_constants.dart';
import 'package:smart_expenses_plan/data/repositories/auth_repository.dart';
import 'package:smart_expenses_plan/services/ad_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    
    _controller.forward();
    
    _checkFirstLaunch();
  }
  
  Future<void> _checkFirstLaunch() async {
    // Database is already initialized in main.dart
    // Just add a short delay for animation and then navigate
    print('Splash: Starting navigation check');
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Show app-open ad after animation completes
    await AdService.instance.showAppOpenAd();
    
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(AppConstants.firstLaunchKey) ?? true;
    final termsAccepted = prefs.getBool(AppConstants.termsAcceptedKey) ?? false;
    
    print('Splash: isFirstLaunch=$isFirstLaunch, termsAccepted=$termsAccepted');
    
    if (!mounted) return;
    
    if (isFirstLaunch) {
      if (!termsAccepted) {
        print('Splash: Navigating to /terms');
        context.go('/terms');
      } else {
        // Terms accepted but not yet fully set up
        print('Splash: Navigating to /initial-setup');
        context.go('/initial-setup');
      }
    } else {
      // Check if user has authentication set up
      final authRepo = AuthRepository();
      final user = await authRepo.getCurrentUser();
      
      if (user != null) {
        // Check if user has PIN, Password or biometric authentication
        final hasPin = user.pin != null && user.pin!.isNotEmpty;
        final hasPassword = user.password != null && user.password!.isNotEmpty;
        final useBiometrics = user.useBiometrics ?? false;
        
        if (hasPin || hasPassword || useBiometrics) {
          print('Splash: User has authentication (PIN: $hasPin, Password: $hasPassword, Biometric: $useBiometrics) - navigating to /login');
          context.go('/login');
        } else {
          print('Splash: No authentication set up - navigating to /home');
          context.go('/home');
        }
      } else {
        print('Splash: No current user - navigating to /login');
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Smart Expenses Plan',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your finances smartly',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 48),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}