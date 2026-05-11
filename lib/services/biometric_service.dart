import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  
  static Future<bool> isBiometricAvailable() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        print('BiometricService: Device does not support biometrics');
        return false;
      }
      
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final hasBiometrics = availableBiometrics.isNotEmpty;
      
      print('BiometricService: isDeviceSupported=$isDeviceSupported, availableBiometrics=$availableBiometrics, hasBiometrics=$hasBiometrics');
      
      return hasBiometrics;
    } catch (e) {
      print('BiometricService: Error checking biometric availability: $e');
      return false;
    }
  }
  
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      print('BiometricService: Available biometrics: $biometrics');
      return biometrics;
    } catch (e) {
      print('BiometricService: Error getting available biometrics: $e');
      return [];
    }
  }
  
  static Future<bool> authenticate() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('BiometricService: Biometric not available');
        return false;
      }
      
      print('BiometricService: Starting biometric authentication');
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow device credentials as fallback
          useErrorDialogs: true,
        ),
      );
      
      print('BiometricService: Authentication result: $authenticated');
      return authenticated;
    } catch (e) {
      print('BiometricService: Error during authentication: $e');
      rethrow;
    }
  }
  
  static Future<bool> authenticateWithPin(String pin) async {
    try {
      // Implement PIN authentication logic
      print('BiometricService: PIN authentication (not fully implemented)');
      return true;
    } catch (e) {
      print('BiometricService: Error authenticating with PIN: $e');
      return false;
    }
  }
  
  static Future<bool> authenticateWithPattern(List<int> pattern) async {
    try {
      // Implement pattern authentication logic
      print('BiometricService: Pattern authentication (not fully implemented)');
      return true;
    } catch (e) {
      print('BiometricService: Error authenticating with pattern: $e');
      return false;
    }
  }
}