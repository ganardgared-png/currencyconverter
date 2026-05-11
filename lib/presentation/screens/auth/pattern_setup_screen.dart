import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/constants/app_constants.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';

class PatternSetupScreen extends StatefulWidget {
  const PatternSetupScreen({super.key});

  @override
  State<PatternSetupScreen> createState() => _PatternSetupScreenState();
}

class _PatternSetupScreenState extends State<PatternSetupScreen> {
  List<int>? _pattern;
  List<int>? _confirmPattern;
  bool _isConfirming = false;
  String _message = 'Draw your pattern';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isConfirming ? 'Confirm Pattern' : 'Setup Pattern'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
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
                  Icons.grid_3x3,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 24),

              // Message
              Text(
                _message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _getMessageColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _isConfirming
                    ? 'Draw the same pattern again to confirm'
                    : 'Connect at least 3 dots to create your pattern',
                style: TextStyle(
                  color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Pattern Lock
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: PatternLock(
                  selectedColor: AppColors.primary,
                  onInputComplete: _onPatternComplete,
                ),
              ),

              const SizedBox(height: 24),

              // Reset button
              TextButton(
                onPressed: _resetPattern,
                child: const Text('Reset Pattern'),
              ),

              const Spacer(),

              // Save Button
              if (_isConfirming && _confirmPattern != null)
                CustomButton(
                  text: 'Save Pattern',
                  onPressed: _savePattern,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),

              const SizedBox(height: 16),

              // Skip for now
              Center(
                child: TextButton(
                  onPressed: () {
                    if (mounted) {
                      context.go('/home');
                    }
                  },
                  child: const Text('Skip for now'),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _onPatternComplete(List<int> pattern) {
    if (pattern.length < 3) {
      setState(() {
        _message = 'Please connect at least 3 dots';
        _pattern = null;
        _confirmPattern = null;
        _isConfirming = false;
      });
      return;
    }

    if (!_isConfirming) {
      // First pattern entry
      setState(() {
        _pattern = pattern;
        _isConfirming = true;
        _message = 'Confirm your pattern';
      });
    } else {
      // Confirm pattern
      if (_arePatternsEqual(pattern, _pattern!)) {
        setState(() {
          _confirmPattern = pattern;
          _message = 'Pattern confirmed!';
        });
      } else {
        setState(() {
          _message = 'Patterns do not match. Try again';
          _isConfirming = false;
          _pattern = null;
        });
      }
    }
  }

  bool _arePatternsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _resetPattern() {
    setState(() {
      _pattern = null;
      _confirmPattern = null;
      _isConfirming = false;
      _message = 'Draw your pattern';
    });
  }

  Color _getMessageColor() {
    if (_message.contains('match') || _message.contains('least')) {
      return AppColors.error;
    } else if (_message.contains('confirmed')) {
      return AppColors.success;
    }
    return Theme.of(context).textTheme.titleMedium?.color ?? Colors.black;
  }

  void _savePattern() {
    setState(() {
      _isLoading = true;
    });

    // Save pattern and mark that a lock was set up
    _savePatternToStorage(_confirmPattern!);
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  Future<void> _savePatternToStorage(List<int> pattern) async {
    final prefs = await SharedPreferences.getInstance();
    // Store the pattern (convert to string for storage)
    final patternString = pattern.join(',');
    await prefs.setString('pattern_lock', patternString);
    // Mark that a password/lock was set up
    await prefs.setBool(AppConstants.hasPasswordKey, true);
  }
}