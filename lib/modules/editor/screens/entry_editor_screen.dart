import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jrnl/modules/consts/prompt.dart';
import 'package:jrnl/modules/editor/widgets/dynamic_bottom_toolbar.dart';
import 'package:jrnl/modules/home/models/entry_model.dart';
import 'package:jrnl/riverpod/entries_rvpd.dart';
import 'package:jrnl/riverpod/preferences_rvpd.dart';
import 'package:jrnl/theme/app_theme.dart';
import 'package:jrnl/widgets/top_snackbar.dart';

class EntryEditorScreen extends ConsumerStatefulWidget {
  final EntryModel entry;

  const EntryEditorScreen({super.key, required this.entry});

  @override
  ConsumerState<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends ConsumerState<EntryEditorScreen> {
  late TextEditingController _controller;
  Timer? _autoSaveTimer;
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _initialized = false;
  String _lastSavedBody = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _typingTimer?.cancel();
    _saveIfNeeded();
    _controller.dispose();
    super.dispose();
  }

  void _initializeWithEntry(EntryModel entry) {
    if (!_initialized) {
      _controller.text = entry.body;
      _lastSavedBody = entry.body;
      _initialized = true;
    }
  }

  void _onTextChanged() {
    // Mark as typing
    setState(() => _isTyping = true);

    // Reset typing timer (for toolbar visibility)
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isTyping = false);
    });

    // Reset auto-save timer
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _saveIfNeeded);
  }

  void _saveIfNeeded() {
    if (_controller.text == _lastSavedBody) return;

    final entries = ref.read(entriesProvider).value;
    if (entries == null) return;

    final entry = entries.firstWhere(
      (e) => e.id == widget.entry,
      orElse: () => throw Exception('Entry not found'),
    );

    ref
        .read(entriesProvider.notifier)
        .updateEntry(entry.copyWith(body: _controller.text));
    _lastSavedBody = _controller.text;
  }

  void _deleteEntry() {
    showCupertinoDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => CupertinoAlertDialog(
        title: Text("Delete Entry?"),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context);
              ref.read(entriesProvider.notifier).deleteEntry(widget.entry.id);
            },
            isDestructiveAction: true,
            child: const Text("Yes, Delete"),
          ),
        ],
      ),
    );
  }

  void _copyEntry() {
    Clipboard.setData(
      ClipboardData(text: "$masterPrompt\n\n${_controller.text}"),
    );
    SnackbarService().show(context, 'Copied with secret prompt');
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider);
    final prefsAsync = ref.watch(preferencesProvider);
    final theme = Theme.of(context);

    return entriesAsync.when(
      data: (entries) {
        // Safely find entry, return empty scaffold if not found (during deletion)
        final entry = entries.cast<EntryModel?>().firstWhere(
          (e) => e?.id == widget.entry.id,
          orElse: () => null,
        );

        if (entry == null) {
          // Entry was deleted, show empty scaffold while navigating away
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        _initializeWithEntry(entry);

        return prefsAsync.when(
          data: (prefs) {
            final textStyle = AppThemeData.getTextStyle(
              prefs.fontFamily,
              prefs.fontSize,
            ).copyWith(color: theme.colorScheme.onSurface);

            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _saveIfNeeded();
                    Navigator.pop(context);
                  },
                ),
                actions: [
                  IconButton(
                    icon:
                        ref.read(preferencesProvider).value?.theme ==
                            AppTheme.dark
                        ? Icon(Icons.light_mode_outlined)
                        : Icon(Icons.dark_mode_outlined),
                    onPressed: () {
                      final currentTheme = prefs.theme;
                      final isLight = currentTheme == AppTheme.light;

                      ref
                          .read(preferencesProvider.notifier)
                          .setTheme(isLight ? AppTheme.dark : AppTheme.light);
                    },
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      "assets/icons/copy.svg",
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.onSurface,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: _copyEntry,
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      "assets/icons/delete.svg",
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.onSurface,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: _deleteEntry,
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: TextField(
                        enabled: !widget.entry.updatedAt.isBefore(
                          DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                          ),
                        ),
                        controller: _controller,
                        onChanged: (_) => _onTextChanged(),
                        maxLines: null,
                        expands: true,
                        autofocus: true,
                        style: textStyle,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Start writing...',
                        ),
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                  ),
                  DynamicBottomToolbar(isTyping: _isTyping),
                ],
              ),
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
