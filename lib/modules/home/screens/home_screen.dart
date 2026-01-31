import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jrnl/modules/editor/screens/entry_editor_screen.dart';
import 'package:jrnl/modules/home/widgets/entry_card.dart';
import 'package:jrnl/riverpod/entries_rvpd.dart';
import 'package:jrnl/riverpod/preferences_rvpd.dart';
import 'package:jrnl/services/analytics_service.dart';
import 'package:jrnl/services/revenuecat_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String version = "";

  void setVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    setState(() {
      this.version = "$version ($buildNumber)";
    });
  }

  @override
  void initState() {
    super.initState();
    setVersion();
  }

  void pressedWorkoutButton() {
    RevenueCatService.instance.presentPaywall();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text("JRNL", style: TextStyle(fontWeight: FontWeight.w600)),
            Text(
              "by @aaditya_fr",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // if (kDebugMode)
          //   IconButton(
          //     icon: const Icon(Icons.bug_report_outlined),
          //     onPressed: () async {
          //       await AnalyticsService.instance.logEvent(name: 'test');
          //     },
          //   ),
          IconButton(
            icon: ref.read(preferencesProvider).value?.theme == AppTheme.dark
                ? Icon(Icons.light_mode_outlined)
                : Icon(Icons.dark_mode_outlined),
            onPressed: () {
              final currentTheme = ref.read(preferencesProvider).value?.theme;
              final isLight = currentTheme == AppTheme.light;

              ref
                  .read(preferencesProvider.notifier)
                  .setTheme(isLight ? AppTheme.dark : AppTheme.light);
            },
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No entries yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to start writing',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return EntryCard(
                entry: entry,
                onTap: () => _openEditor(context, ref, entryId: entry.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        // onPressed: () => _createNewEntry(context, ref),
        onPressed: () => pressedWorkoutButton(),
        elevation: 2,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createNewEntry(BuildContext context, WidgetRef ref) async {
    final entry = await ref.read(entriesProvider.notifier).createEntry();
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EntryEditorScreen(entryId: entry.id)),
      );

      await AnalyticsService.instance.logEvent(name: 'create_entry');
    }
  }

  void _openEditor(
    BuildContext context,
    WidgetRef ref, {
    required String entryId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EntryEditorScreen(entryId: entryId)),
    );
  }
}
