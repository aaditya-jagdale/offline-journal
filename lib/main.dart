import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jrnl/modules/home/screens/home_screen.dart';
import 'package:jrnl/riverpod/preferences_rvpd.dart';
import 'package:jrnl/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        home: const HomeScreen(),
      ),
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemeData.light(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(
        home: Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}
