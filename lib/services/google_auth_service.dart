import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_expenses_plan/data/models/user_model.dart';
import 'package:smart_expenses_plan/data/repositories/auth_repository.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // clientId is only for web. For Android/iOS, use serverClientId if you need an ID token.
    serverClientId: '695528784213-49lf42j7o1o0dqno3qeiabtgg9tkv8fa.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/drive.file', // For backup
    ],
  );

  static Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      print('GoogleAuthService: Starting Google Sign-In');

      // Try existing signed-in account first
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      if (account == null) {
        account = await _googleSignIn.signInSilently();
      }

      if (account == null) {
        account = await _googleSignIn.signIn();
      }

      if (account != null) {
        print('GoogleAuthService: Sign-in successful for ${account.email}');
        final auth = await account.authentication;
        if (auth.accessToken != null || auth.idToken != null) {
          return account;
        }
        print('GoogleAuthService: Failed to get authentication token');
        return null;
      }

      print('GoogleAuthService: Sign-in cancelled by user');
      return null;
    } on Exception catch (error) {
      print('GoogleAuthService: Exception during sign-in: $error');
      print('GoogleAuthService: Error details - Type: ${error.runtimeType}');
      throw Exception('Google Sign-In failed: ${error.toString()}');
    } catch (error) {
      print('GoogleAuthService: Error during sign-in: $error');
      print('GoogleAuthService: Error details - Type: ${error.runtimeType}');
      throw Exception('Google Sign-In failed: ${error.toString()}');
    }
  }

  static Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      print('GoogleAuthService: Signed out from Google');
    } catch (error) {
      print('GoogleAuthService: Error during sign-out: $error');
    }
  }

  static Future<bool> isSignedInWithGoogle() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (error) {
      print('GoogleAuthService: Error checking sign-in status: $error');
      return false;
    }
  }

  static Future<GoogleSignInAccount?> getCurrentGoogleUser() async {
    try {
      return _googleSignIn.currentUser;
    } catch (error) {
      print('GoogleAuthService: Error getting current user: $error');
      return null;
    }
  }

  static Future<void> updateUserProfileFromGoogle(UserModel user, GoogleSignInAccount googleAccount) async {
    try {
      print('GoogleAuthService: Updating user profile from Google account');

      final authRepo = AuthRepository();
      final updatedUser = UserModel(
        id: user.id,
        username: googleAccount.displayName ?? user.username,
        email: googleAccount.email,
        profilePicture: googleAccount.photoUrl,
        password: user.password,
        pin: user.pin,
        pattern: user.pattern,
        useBiometrics: user.useBiometrics,
        income: user.income,
        incomeType: user.incomeType,
        currency: user.currency,
        createdAt: user.createdAt,
      );

      await authRepo.updateUser(updatedUser);
      print('GoogleAuthService: User profile updated successfully');
    } catch (error) {
      print('GoogleAuthService: Error updating user profile: $error');
      rethrow;
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account != null) {
        final auth = await account.authentication;
        return auth.accessToken;
      }
      return null;
    } catch (error) {
      print('GoogleAuthService: Error getting access token: $error');
      return null;
    }
  }
}