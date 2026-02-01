import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jrnl/riverpod/preferences_rvpd.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ClipRRect(
                    clipBehavior: Clip.hardEdge,
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      "assets/images/logo.png",
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SignInWithAppleButton(
                height: 52,
                style:
                    ref.watch(preferencesProvider).value!.theme == AppTheme.dark
                    ? SignInWithAppleButtonStyle.white
                    : SignInWithAppleButtonStyle.black,
                onPressed: () async {
                  try {
                    final credential =
                        await SignInWithApple.getAppleIDCredential(
                          scopes: [
                            AppleIDAuthorizationScopes.email,
                            AppleIDAuthorizationScopes.fullName,
                          ],
                        );

                    final AuthCredential oauthCredential =
                        OAuthProvider("apple.com").credential(
                          idToken: credential.identityToken,
                          accessToken: credential.authorizationCode,
                          rawNonce: credential.state,
                        );

                    final currentUser = FirebaseAuth.instance.currentUser;

                    try {
                      await currentUser!.linkWithCredential(oauthCredential);
                    } catch (e) {
                      await FirebaseAuth.instance.signInWithCredential(
                        oauthCredential,
                      );
                    }

                    Navigator.pop(context);
                  } catch (e, stack) {
                    print(stack.toString());
                    print(e);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
