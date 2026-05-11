import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      print('LocalAuthService: Biometric available: $isAvailable');
      if (!isAvailable) return false;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      print('LocalAuthService: Biometric authentication result: $authenticated');
      return authenticated;
    } catch (e) {
      print('LocalAuthService: Error authenticating with biometrics: $e');
      return false;
    }
  }

  static Future<bool> authenticateWithPin(String pin, String storedPin) async {
    try {
      final result = pin == storedPin;
      print('LocalAuthService: PIN authentication result: $result');
      return result;
    } catch (e) {
      print('LocalAuthService: Error authenticating with PIN: $e');
      return false;
    }
  }

  static Future<bool> authenticateWithPattern(
    List<int> pattern,
    List<int> storedPattern,
  ) async {
    try {
      if (pattern.length != storedPattern.length) {
        print('LocalAuthService: Pattern length mismatch');
        return false;
      }
      
      for (int i = 0; i < pattern.length; i++) {
        if (pattern[i] != storedPattern[i]) {
          print('LocalAuthService: Pattern mismatch at index $i');
          return false;
        }
      }
      
      print('LocalAuthService: Pattern authentication successful');
      return true;
    } catch (e) {
      print('LocalAuthService: Error authenticating with pattern: $e');
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      print('LocalAuthService: Available biometrics: $biometrics');
      return biometrics;
    } catch (e) {
      print('LocalAuthService: Error getting available biometrics: $e');
      return [];
    }
  }

  static Future<bool> isBiometricSupported() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      print('LocalAuthService: Biometric supported: $isSupported');
      return isSupported;
    } catch (e) {
      print('LocalAuthService: Error checking biometric support: $e');
      return false;
    }
  }

  static Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      print('LocalAuthService: Can check biometrics: $canCheck');
      return canCheck;
    } catch (e) {
      print('LocalAuthService: Error checking biometric capability: $e');
      return false;
    }
  }

  static Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      print('LocalAuthService: Authentication stopped');
    } catch (e) {
      print('LocalAuthService: Error stopping authentication: $e');
    }
  }
}