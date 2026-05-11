import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/utils/validators.dart';
import 'package:smart_expenses_plan/data/providers/database_provider.dart';
import 'package:smart_expenses_plan/data/repositories/auth_repository.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup PIN'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pin,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Create your PIN',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Enter a 4-digit PIN to secure your account',
                style: TextStyle(
                  color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // PIN Input
              PinCodeTextField(
                appContext: context,
                length: 4,
                controller: _pinController,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 60,
                  fieldWidth: 60,
                  activeFillColor: AppColors.primary.withOpacity(0.1),
                  inactiveFillColor: Colors.grey.withOpacity(0.1),
                  selectedFillColor: AppColors.primary.withOpacity(0.2),
                  activeColor: AppColors.primary,
                  inactiveColor: Colors.grey,
                  selectedColor: AppColors.primary,
                ),
                onChanged: (value) {
                  setState(() {
                    _errorText = null;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Confirm PIN Input
              PinCodeTextField(
                appContext: context,
                length: 4,
                controller: _confirmPinController,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 60,
                  fieldWidth: 60,
                  activeFillColor: AppColors.primary.withOpacity(0.1),
                  inactiveFillColor: Colors.grey.withOpacity(0.1),
                  selectedFillColor: AppColors.primary.withOpacity(0.2),
                  activeColor: AppColors.primary,
                  inactiveColor: Colors.grey,
                  selectedColor: AppColors.primary,
                ),
                onChanged: (value) {
                  setState(() {
                    _errorText = null;
                  });
                },
              ),
              
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Save Button
              CustomButton(
                text: 'Save PIN',
                onPressed: _savePin,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePin() async {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    // Validate PIN
    final pinError = Validators.validatePin(pin);
    if (pinError != null) {
      setState(() {
        _errorText = pinError;
      });
      return;
    }

    // Validate confirmation
    if (pin != confirmPin) {
      setState(() {
        _errorText = 'PINs do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Save PIN logic here
    // Save PIN to current user and clear any password (one lock type at a time)
    try {
      final authRepo = AuthRepository();
      final user = await authRepo.getCurrentUser();
      if (user != null) {
        final db = await DatabaseProvider.instance.database;
        await db.update(
          'users',
          {
            'pin': pin,
            'password': null,
            'use_biometrics': user.useBiometrics ? 1 : 0,
          },
          where: 'id = ?',
          whereArgs: [user.id],
        );
        await authRepo.setHasPassword(false);
      }
    } catch (e) {
      print('PinSetupScreen: Failed to save PIN: $e');
    } finally {
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          context.go('/login');
        }
      }
    }
  }
}