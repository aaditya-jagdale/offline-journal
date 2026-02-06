import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jrnl/modules/home/screens/home_screen.dart';
import 'package:jrnl/modules/shared/widgets/custom_progress_indicator.dart';
import 'package:jrnl/modules/shared/widgets/transitions.dart';
// import 'package:superwallkit_flutter/superwallkit_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      // Superwall.shared.identify(FirebaseAuth.instance.currentUser!.uid);
      clearAllAndPush(context, const HomeScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: CustomProgressIndicator());
  }
}
