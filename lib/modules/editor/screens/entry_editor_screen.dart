import 'dart:async';
import 'dart:ui';
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
  final String entryId;

  const EntryEditorScreen({super.key, required this.entryId});

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
      (e) => e.id == widget.entryId,
      orElse: () => throw Exception('Entry not found'),
    );

    ref
        .read(entriesProvider.notifier)
        .updateEntry(entry.copyWith(body: _controller.text));
    _lastSavedBody = _controller.text;
  }

  void _deleteEntry() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with background
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      'Delete Entry?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      'This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.6),
                        height: 1.4,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        // Cancel button
                        Expanded(
                          child: _buildDialogButton(
                            label: 'Cancel',
                            isPrimary: false,
                            isDark: isDark,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Delete button
                        Expanded(
                          child: _buildDialogButton(
                            label: 'Delete',
                            isPrimary: true,
                            isDark: isDark,
                            isDestructive: true,
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(
                                this.context,
                              ); // Go back to home first
                              // Delete after navigation to prevent rebuild issues
                              ref
                                  .read(entriesProvider.notifier)
                                  .deleteEntry(widget.entryId);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required bool isPrimary,
    required bool isDark,
    bool isDestructive = false,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isPrimary
                ? (isDestructive
                      ? Colors.red
                      : (isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.08)))
                : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary
                  ? (isDestructive
                        ? Colors.red.withOpacity(0.5)
                        : (isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1)))
                  : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.06)),
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
              color: isDestructive
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black),
              letterSpacing: -0.2,
            ),
          ),
        ),
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
          (e) => e?.id == widget.entryId,
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
