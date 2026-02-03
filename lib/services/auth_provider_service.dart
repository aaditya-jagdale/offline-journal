import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  AuthResult.success(this.user) : success = true, errorMessage = null;

  AuthResult.failure(this.errorMessage) : success = false, user = null;
}

class AuthProviderService {
  static final AuthProviderService instance = AuthProviderService._();
  AuthProviderService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<AuthResult> signInWithApple() async {
    try {
      debugPrint('[AuthService] Starting Apple Sign In flow');

      final AuthorizationCredentialAppleID appleCredential;
      try {
        appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
      } on SignInWithAppleAuthorizationException catch (e) {
        if (e.code == AuthorizationErrorCode.canceled) {
          debugPrint('[AuthService] User canceled Apple Sign In');
          return AuthResult.failure('Sign in canceled');
        }
        debugPrint('[AuthService] Apple authorization error: ${e.code}');
        return AuthResult.failure('Apple Sign In failed: ${e.message}');
      } catch (e) {
        debugPrint('[AuthService] Unexpected error in Apple Sign In: $e');
        return AuthResult.failure('Apple Sign In failed');
      }

      if (appleCredential.identityToken == null) {
        debugPrint('[AuthService] No identity token received from Apple');
        return AuthResult.failure('Apple Sign In incomplete');
      }

      final OAuthCredential oauthCredential = OAuthProvider("apple.com")
          .credential(
            idToken: appleCredential.identityToken,
            accessToken: appleCredential.authorizationCode,
          );

      final User? currentUser = _auth.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        debugPrint('[AuthService] Linking anonymous account to Apple');
        try {
          final UserCredential linkedCredential = await currentUser
              .linkWithCredential(oauthCredential);
          debugPrint(
            '[AuthService] Successfully linked Apple to anonymous account',
          );
          return AuthResult.success(linkedCredential.user);
        } on FirebaseAuthException catch (e) {
          debugPrint('[AuthService] Linking failed: ${e.code}');

          if (e.code == 'credential-already-in-use') {
            // The Apple account is already linked to another Firebase account
            // Sign in to that account directly (replaces anonymous session)
            debugPrint(
              '[AuthService] Credential already in use, signing in to existing account',
            );
            try {
              final UserCredential userCredential = await _auth
                  .signInWithCredential(oauthCredential);
              debugPrint(
                '[AuthService] Successfully signed in to existing Apple account',
              );
              return AuthResult.success(userCredential.user);
            } catch (signInError) {
              debugPrint('[AuthService] Sign in failed: $signInError');
              return AuthResult.failure(
                'Unable to sign in with this Apple account. Please try again.',
              );
            }
          } else if (e.code == 'email-already-in-use') {
            return AuthResult.failure(
              'An account with this email already exists. Please sign in with your existing method.',
            );
          } else if (e.code == 'provider-already-linked') {
            return AuthResult.failure(
              'This account is already linked to Apple',
            );
          }

          return AuthResult.failure('Failed to link account: ${e.message}');
        }
      } else {
        debugPrint(
          '[AuthService] Signing in with Apple (no anonymous account)',
        );
        try {
          final UserCredential userCredential = await _auth
              .signInWithCredential(oauthCredential);
          debugPrint('[AuthService] Successfully signed in with Apple');
          return AuthResult.success(userCredential.user);
        } on FirebaseAuthException catch (e) {
          debugPrint('[AuthService] Apple sign in error: ${e.code}');
          if (e.code == 'account-exists-with-different-credential') {
            return AuthResult.failure(
              'An account already exists with the same email from a different sign-in method',
            );
          } else if (e.code == 'invalid-credential') {
            return AuthResult.failure('The Apple credential is invalid');
          }
          return AuthResult.failure('Sign in failed: ${e.message}');
        }
      }
    } catch (e, stack) {
      debugPrint('[AuthService] Unexpected error in Apple Sign In: $e');
      debugPrint('[AuthService] Stack trace: $stack');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AuthService] Starting Email/Password authentication');

      if (!_isValidEmail(email)) {
        return AuthResult.failure('Please enter a valid email address');
      }

      if (password.length < 6) {
        return AuthResult.failure('Password must be at least 6 characters');
      }

      final User? currentUser = _auth.currentUser;

      try {
        debugPrint('[AuthService] Attempting to sign in existing user');
        final UserCredential userCredential = await _auth
            .signInWithEmailAndPassword(email: email, password: password);

        debugPrint('[AuthService] Successfully signed in with email/password');
        return AuthResult.success(userCredential.user);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          debugPrint('[AuthService] User not found, creating new account');
          return await _createEmailPasswordAccount(
            email: email,
            password: password,
            currentUser: currentUser,
          );
        } else if (e.code == 'wrong-password') {
          return AuthResult.failure('Incorrect password');
        } else if (e.code == 'invalid-email') {
          return AuthResult.failure('Invalid email address');
        } else if (e.code == 'user-disabled') {
          return AuthResult.failure('This account has been disabled');
        } else if (e.code == 'invalid-credential') {
          debugPrint(
            '[AuthService] Invalid credential, attempting to create account',
          );
          return await _createEmailPasswordAccount(
            email: email,
            password: password,
            currentUser: currentUser,
          );
        } else {
          debugPrint('[AuthService] Sign in error: ${e.code}');
          return AuthResult.failure('Sign in failed: ${e.message}');
        }
      }
    } catch (e, stack) {
      debugPrint('[AuthService] Unexpected error in Email/Password auth: $e');
      debugPrint('[AuthService] Stack trace: $stack');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  Future<AuthResult> _createEmailPasswordAccount({
    required String email,
    required String password,
    required User? currentUser,
  }) async {
    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      if (currentUser != null && currentUser.isAnonymous) {
        debugPrint('[AuthService] Linking email/password to anonymous account');
        try {
          final UserCredential linkedCredential = await currentUser
              .linkWithCredential(credential);
          debugPrint(
            '[AuthService] Successfully linked email/password to anonymous account',
          );
          return AuthResult.success(linkedCredential.user);
        } on FirebaseAuthException catch (e) {
          debugPrint('[AuthService] Linking failed: ${e.code}');

          if (e.code == 'email-already-in-use') {
            return AuthResult.failure(
              'An account with this email already exists. Please use a different email or sign in.',
            );
          } else if (e.code == 'credential-already-in-use') {
            // Email/password is already linked to another Firebase account
            // Sign in to that account directly (replaces anonymous session)
            debugPrint(
              '[AuthService] Email credential already in use, signing in to existing account',
            );
            try {
              final UserCredential userCredential = await _auth
                  .signInWithCredential(credential);
              debugPrint(
                '[AuthService] Successfully signed in to existing email account',
              );
              return AuthResult.success(userCredential.user);
            } catch (signInError) {
              debugPrint('[AuthService] Sign in failed: $signInError');
              return AuthResult.failure(
                'Unable to sign in with this email. Please try again.',
              );
            }
          }

          return AuthResult.failure('Failed to create account: ${e.message}');
        }
      } else {
        debugPrint('[AuthService] Creating new email/password account');
        try {
          final UserCredential userCredential = await _auth
              .createUserWithEmailAndPassword(email: email, password: password);
          debugPrint(
            '[AuthService] Successfully created email/password account',
          );
          return AuthResult.success(userCredential.user);
        } on FirebaseAuthException catch (e) {
          debugPrint('[AuthService] Account creation error: ${e.code}');

          if (e.code == 'email-already-in-use') {
            return AuthResult.failure(
              'An account with this email already exists',
            );
          } else if (e.code == 'weak-password') {
            return AuthResult.failure('Password is too weak');
          } else if (e.code == 'invalid-email') {
            return AuthResult.failure('Invalid email address');
          }

          return AuthResult.failure('Failed to create account: ${e.message}');
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Unexpected error creating account: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  Future<AuthResult> signInWithGoogle(AuthCredential credential) async {
    try {
      debugPrint('[AuthService] Starting Google Sign In flow');

      final User? currentUser = _auth.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        debugPrint('[AuthService] Linking anonymous account to Google');
        try {
          final linkedCredential = await currentUser.linkWithCredential(
            credential,
          );
          debugPrint(
            '[AuthService] Successfully linked Google to anonymous account',
          );
          return AuthResult.success(linkedCredential.user);
        } on FirebaseAuthException catch (e) {
          debugPrint('[AuthService] Linking failed: ${e.code}');

          if (e.code == 'credential-already-in-use') {
            // The Google account is already linked to another Firebase account
            // Sign in to that account directly (replaces anonymous session)
            debugPrint(
              '[AuthService] Credential already in use, signing in to existing account',
            );
            try {
              final UserCredential userCredential = await _auth
                  .signInWithCredential(credential);
              debugPrint(
                '[AuthService] Successfully signed in to existing Google account',
              );
              return AuthResult.success(userCredential.user);
            } catch (signInError) {
              debugPrint('[AuthService] Sign in failed: $signInError');
              return AuthResult.failure(
                'Unable to sign in with this Google account. Please try again.',
              );
            }
          } else if (e.code == 'email-already-in-use') {
            return AuthResult.failure(
              'An account with this email already exists. Please sign in with your existing method.',
            );
          } else if (e.code == 'provider-already-linked') {
            return AuthResult.failure(
              'This account is already linked to Google',
            );
          }

          return AuthResult.failure('Failed to link account: ${e.message}');
        }
      } else {
        debugPrint(
          '[AuthService] Signing in with Google (no anonymous account)',
        );
        try {
          final UserCredential userCredential = await _auth
              .signInWithCredential(credential);
          debugPrint('[AuthService] Successfully signed in with Google');
          return AuthResult.success(userCredential.user);
        } on FirebaseAuthException catch (e) {
          debugPrint('[AuthService] Google sign in error: ${e.code}');
          if (e.code == 'account-exists-with-different-credential') {
            return AuthResult.failure(
              'An account already exists with the same email from a different sign-in method',
            );
          } else if (e.code == 'invalid-credential') {
            return AuthResult.failure('The Google credential is invalid');
          }
          return AuthResult.failure('Sign in failed: ${e.message}');
        }
      }
    } catch (e, stack) {
      debugPrint('[AuthService] Unexpected error in Google Sign In: $e');
      debugPrint('[AuthService] Stack trace: $stack');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('[AuthService] User signed out successfully');
    } catch (e) {
      debugPrint('[AuthService] Error signing out: $e');
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
