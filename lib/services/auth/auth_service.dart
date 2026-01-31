import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../storage/preferences_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== Email/Password Authentication ====================

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Save user data to SharedPreferences
      if (userCredential.user != null) {
        final prefs = await PreferencesService.getInstance();
        await prefs.saveUserData(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? email,
          displayName: userCredential.user!.displayName,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // Update display name if provided
      if (displayName != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        await userCredential.user!.reload();
      }

      // Save user data to SharedPreferences
      if (userCredential.user != null) {
        final prefs = await PreferencesService.getInstance();
        await prefs.saveUserData(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? email,
          displayName: displayName ?? userCredential.user!.displayName,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  /// Sign in with email link
  Future<UserCredential?> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    try {
      if (!_auth.isSignInWithEmailLink(emailLink)) {
        throw 'Invalid sign-in link';
      }

      UserCredential userCredential = await _auth.signInWithEmailLink(
        email: email.trim(),
        emailLink: emailLink,
      );

      // Save user data to SharedPreferences
      if (userCredential.user != null) {
        final prefs = await PreferencesService.getInstance();
        await prefs.saveUserData(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? email,
          displayName: userCredential.user!.displayName,
        );
      }

      // Clear saved email
      final prefsInstance = await SharedPreferences.getInstance();
      await prefsInstance.remove('email_for_signin');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to sign in with email link. Please try again.';
    }
  }

  // ==================== Google Sign-In ====================

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Save user data to SharedPreferences
      if (userCredential.user != null) {
        final prefs = await PreferencesService.getInstance();
        await prefs.saveUserData(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Log error for debugging if needed
      throw 'Failed to sign in with Google. Please try again.';
    }
  }

  // ==================== Apple Sign-In ====================

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuth credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      UserCredential userCredential = await _auth.signInWithCredential(
        oauthCredential,
      );

      // Update display name from Apple if available
      if (appleCredential.givenName != null &&
          appleCredential.familyName != null) {
        final displayName =
            '${appleCredential.givenName} ${appleCredential.familyName}';
        await userCredential.user?.updateDisplayName(displayName);
      }

      // Save user data to SharedPreferences
      if (userCredential.user != null) {
        final prefs = await PreferencesService.getInstance();
        await prefs.saveUserData(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? appleCredential.email ?? '',
          displayName: userCredential.user!.displayName,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        // User cancelled
        return null;
      }
      throw 'Apple sign-in failed: ${e.message}';
    } catch (e) {
      // Log error for debugging if needed
      throw 'Failed to sign in with Apple. Please try again.';
    }
  }

  // ==================== Sign Out ====================

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      await _googleSignIn.signOut();

      // Sign out from Firebase
      await _auth.signOut();

      // Clear SharedPreferences
      final prefs = await PreferencesService.getInstance();
      await prefs.clearUserData();
    } catch (e) {
      // Log error for debugging if needed
      throw 'Failed to sign out. Please try again.';
    }
  }

  // ==================== Helper Methods ====================

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      default:
        return 'Authentication failed: ${e.message ?? 'Unknown error'}';
    }
  }
}
