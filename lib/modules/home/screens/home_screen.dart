import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:jrnl/modules/editor/screens/entry_editor_screen.dart';
import 'package:jrnl/modules/home/models/entry_model.dart';
import 'package:jrnl/modules/home/widgets/entry_card.dart';
import 'package:jrnl/modules/settings/screens/setting_screen.dart';
import 'package:jrnl/modules/shared/widgets/transitions.dart';
import 'package:jrnl/riverpod/entries_rvpd.dart';
import 'package:jrnl/riverpod/preferences_rvpd.dart';
import 'package:jrnl/riverpod/backup_rvpd.dart';
import 'package:jrnl/services/analytics_service.dart';
import 'package:jrnl/services/revenuecat_service.dart';
import 'package:jrnl/services/sync_service.dart';
import 'package:jrnl/services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

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
    // Auto-backup on app open
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(entriesProvider.notifier).getEntries();

      await _performAutoBackup();

      if (mounted) {
        UpdateService.instance.checkForUpdate(context);
      }
    });
  }

  Future<void> _performAutoBackup() async {
    await SyncService.instance.syncIfNeeded(ref);
    // Invalidate main backup provider to refresh UI timestamp
    ref.invalidate(lastBackupTimeProvider);
  }

  void _createNewEntry(
    BuildContext context,
    WidgetRef ref, {
    required bool isPro,
  }) async {
    try {
      final entry = await ref
          .read(entriesProvider.notifier)
          .createEntry(isPro: isPro);
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EntryEditorScreen(entry: entry)),
        );

        await AnalyticsService.instance.logEvent(name: 'create_entry');
        if (mounted) _performAutoBackup();
      }
    } catch (e) {
      // Entry limit exception caught - should not happen if UI logic is correct
      // but this is a fallback safety net
      debugPrint('Error creating entry: $e');
    }
  }

  void pressedAddEntryButton() async {
    final isPro = await RevenueCatService.instance.isPro();
    final entries = ref.read(entriesProvider).value ?? [];

    // Defense layer 1: UI check before entry creation
    if (!isPro && entries.length >= RevenueCatService.freeEntryLimit) {
      final result = await RevenueCatService.instance.presentPaywall();
      if (result != PaywallResult.purchased) {
        // User dismissed paywall - do NOT create entry
        return;
      }
      // User purchased - now they are pro, proceed with creation
      _createNewEntry(context, ref, isPro: true);
      return;
    }

    // User can create entry (either pro or under limit)
    _createNewEntry(context, ref, isPro: isPro);
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
          IconButton(
            icon: SvgPicture.asset(
              "assets/icons/settings.svg",
              height: 20,
              colorFilter: ColorFilter.mode(
                theme.colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () async {
              await upSlideTransition(context, const SettingScreen());
              if (mounted) _performAutoBackup();
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
                onTap: () => _openEditor(context, ref, entry: entry),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        // onPressed: () => _createNewEntry(context, ref),
        onPressed: () => pressedAddEntryButton(),
        elevation: 2,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openEditor(
    BuildContext context,
    WidgetRef ref, {
    required EntryModel entry,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EntryEditorScreen(entry: entry)),
    );
    if (mounted) _performAutoBackup();
  }
}
