import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jrnl/riverpod/preferences_rvpd.dart';
import 'package:jrnl/services/auth_provider_service.dart';
import 'package:jrnl/services/revenuecat_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailPasswordSignIn() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthProviderService.instance.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        // Success! Go back to settings
        Navigator.pop(context);
      } else {
        // Show error
        setState(() {
          _errorMessage = result.errorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthProviderService.instance.signInWithApple();

      if (!mounted) return;

      if (result.success) {
        RevenueCatService.instance.logIn(result.user!.uid);
        Navigator.pop(context);
      } else {
        // Only show error if it's not a cancellation
        if (result.errorMessage != 'Sign in canceled') {
          setState(() {
            _errorMessage = result.errorMessage;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final webClientId = dotenv.env['GOOGLE_CLIENT_ID_WEB'];
    final iosClientId = dotenv.env['GOOGLE_CLIENT_ID_IOS'];
    final GoogleSignIn signIn = GoogleSignIn.instance;

    try {
      unawaited(
        signIn.initialize(clientId: iosClientId, serverClientId: webClientId),
      );

      // Perform the sign in
      final googleAccount = await signIn.authenticate();
      final googleAuthorization = await googleAccount.authorizationClient
          .authorizationForScopes([
            "https://www.googleapis.com/auth/userinfo.email",
            "https://www.googleapis.com/auth/userinfo.profile",
          ]);
      final googleAuthentication = googleAccount.authentication;
      final idToken = googleAuthentication.idToken;
      final accessToken = googleAuthorization!.accessToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      final OAuthCredential oauthCredential = OAuthProvider(
        "google.com",
      ).credential(idToken: idToken, accessToken: accessToken);

      await AuthProviderService.instance.signInWithGoogle(oauthCredential);
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        // Logo
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              "assets/images/logo.png",
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            // Basic email validation
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return 'Invalid email format';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? CupertinoIcons.eye_slash_fill
                                  : CupertinoIcons.eye_fill,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.exclamationmark_circle_fill,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Sign In Button
                        _buildPrimaryButton(
                          label: 'Sign In',
                          onPressed: _isLoading
                              ? null
                              : _handleEmailPasswordSignIn,
                          isLoading: _isLoading,
                        ),

                        const SizedBox(height: 32),

                        // Divider with "or"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[300],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[300],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Apple Sign In Button
                        SignInWithAppleButton(
                          height: 52,
                          borderRadius: BorderRadius.circular(12),
                          style:
                              ref.watch(preferencesProvider).value!.theme ==
                                  AppTheme.dark
                              ? SignInWithAppleButtonStyle.white
                              : SignInWithAppleButtonStyle.black,
                          onPressed: _isLoading ? () {} : _handleAppleSignIn,
                        ),

                        const SizedBox(height: 16),

                        // Google Sign In Button (Placeholder)
                        _buildSocialButton(
                          label: 'Continue with Google',
                          icon: SvgPicture.asset("assets/icons/google.svg"),
                          onPressed: _handleGoogleSignIn,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 16,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor:
                        ref.watch(preferencesProvider).value?.theme ==
                            AppTheme.dark
                        ? Colors.black
                        : Colors.white,
                    foregroundColor:
                        ref.watch(preferencesProvider).value?.theme ==
                            AppTheme.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context); // Added this line

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: !_isLoading,
      style: TextStyle(
        fontSize: 16,
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey, fontSize: 16),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    final isDark = ref.read(preferencesProvider).value!.theme == AppTheme.dark;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : Colors.black,
          side: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
