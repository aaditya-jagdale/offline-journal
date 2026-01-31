import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jrnl/modules/home/screens/splash_screen.dart';
import 'package:jrnl/riverpod/preferences_rvpd.dart';
import 'package:jrnl/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:jrnl/firebase_options.dart';
import 'package:jrnl/services/analytics_service.dart';

import 'package:superwallkit_flutter/superwallkit_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );
  await AnalyticsService.instance.setAnalyticsCollectionEnabled(!kDebugMode);

  FlutterError.onError = (errorDetails) {
    debugPrint("==================CRASHLYTICS==================");
    debugPrint(errorDetails.toString());
    debugPrint("=============================================");
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("==================CRASHLYTICS==================");
    debugPrint(error.toString());
    debugPrint(stack.toString());
    debugPrint("=============================================");
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  final apiKey = Platform.isIOS
      ? dotenv.env['SUPERWALL_API_KEY_IOS']!
      : dotenv.env['SUPERWALL_API_KEY_ANDROID']!;
  Superwall.configure(apiKey);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesProvider);

    return prefsAsync.when(
      data: (prefs) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Minimal Journal',
        theme: prefs.theme == AppTheme.light
            ? AppThemeData.light()
            : AppThemeData.dark(),
        navigatorObservers: [AnalyticsService.instance.observer],
        home: const SplashScreen(),
      ),
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemeData.light(),
        navigatorObservers: [AnalyticsService.instance.observer],
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(
        navigatorObservers: [AnalyticsService.instance.observer],
        home: Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}
