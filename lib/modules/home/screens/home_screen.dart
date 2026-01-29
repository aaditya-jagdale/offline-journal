import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jrnl/modules/editor/screens/entry_editor_screen.dart';
import 'package:jrnl/modules/home/widgets/entry_card.dart';
import 'package:jrnl/riverpod/entries_rvpd.dart';
import 'package:jrnl/riverpod/preferences_rvpd.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("JRNL"),
        centerTitle: true,
        actions: [
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
      body: SafeArea(
        child: entriesAsync.when(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewEntry(context, ref),
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
