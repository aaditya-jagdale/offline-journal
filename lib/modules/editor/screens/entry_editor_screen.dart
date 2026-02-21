import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jrnl/modules/consts/prompt.dart';
import 'package:jrnl/modules/editor/widgets/dynamic_bottom_toolbar.dart';
import 'package:jrnl/modules/home/models/entry_model.dart';
import 'package:jrnl/riverpod/entries_rvpd.dart';
import 'package:jrnl/riverpod/preferences_rvpd.dart';
import 'package:jrnl/riverpod/subscription_rvpd.dart';
import 'package:jrnl/services/cover_image_service.dart';
import 'package:jrnl/services/revenuecat_service.dart';
import 'package:jrnl/theme/app_theme.dart';
import 'package:jrnl/widgets/top_snackbar.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class EntryEditorScreen extends ConsumerStatefulWidget {
  final EntryModel entry;

  const EntryEditorScreen({super.key, required this.entry});

  @override
  ConsumerState<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends ConsumerState<EntryEditorScreen> {
  late TextEditingController _controller;
  Timer? _autoSaveTimer;
  bool _isTyping = false;
  bool _initialized = false;
  String _lastSavedBody = '';
  File? _coverImageFile;
  bool isPro = false;
  final _rc = RevenueCatService.instance;
  bool _isToolbarClosed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadCoverImage();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      isPro = await _rc.isPro();
    });
  }

  Future<void> _loadCoverImage() async {
    final file = await CoverImageService.getCoverImageFile(widget.entry.id);
    if (mounted && file != null) {
      setState(() => _coverImageFile = file);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
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

    // Reset auto-save timer
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 1), _saveIfNeeded);
  }

  void _saveIfNeeded() {
    if (_controller.text == _lastSavedBody) return;

    final entries = ref.read(entriesProvider).value;
    if (entries == null) return;

    final entry = entries.firstWhere(
      (e) => e.id == widget.entry.id,
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
    Clipboard.setData(ClipboardData(text: _controller.text));
    SnackbarService().show(context, 'Text Copied');
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    final sourceFile = File(pickedFile.path);
    await CoverImageService.saveCoverImage(widget.entry.id, sourceFile);
    await ref.read(entriesProvider.notifier).setHasImage(widget.entry.id, true);

    final savedFile = await CoverImageService.getCoverImageFile(
      widget.entry.id,
    );
    if (mounted && savedFile != null) {
      setState(() => _coverImageFile = savedFile);
    }
  }

  Future<void> _deleteCoverImage() async {
    await CoverImageService.deleteCoverImage(widget.entry.id);
    await ref
        .read(entriesProvider.notifier)
        .setHasImage(widget.entry.id, false);
    if (mounted) {
      setState(() => _coverImageFile = null);
    }
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

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                _saveIfNeeded();
                Navigator.pop(context);
              },
              child: Scaffold(
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
                      onPressed: () async {
                        // Premium feature
                        final isPro = await RevenueCatService.instance.isPro();
                        if (!isPro) {
                          try {
                            final result = await RevenueCatService.instance
                                .presentPaywall();
                            if (result != PaywallResult.purchased) {
                              // User dismissed paywall - do NOT create entry
                              return;
                            }
                          } catch (e) {
                            print("Error presenting paywall: $e");
                          }
                          _pickCoverImage();
                          return;
                        }
                        _pickCoverImage();
                        return;
                      },
                      icon: SvgPicture.asset(
                        "assets/icons/image_add.svg",
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          theme.colorScheme.onSurface,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),

                    IconButton(
                      icon:
                          ref.read(preferencesProvider).value?.theme ==
                              AppTheme.dark
                          ? const Icon(Icons.light_mode_outlined)
                          : const Icon(Icons.dark_mode_outlined),
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
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Cover Image Section
                            if (_coverImageFile != null)
                              _buildCoverImageSection(theme),
                            // Text Editor
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                              child: GestureDetector(
                                onTap:
                                    isPro ||
                                        ((ref.read(isProProvider).value !=
                                                    null &&
                                                ref
                                                    .read(isProProvider)
                                                    .value!) ||
                                            !widget.entry.createdAt.isBefore(
                                              DateTime(
                                                DateTime.now().year,
                                                DateTime.now().month,
                                                DateTime.now().day,
                                              ),
                                            ))
                                    ? null
                                    : () {
                                        debugPrint(
                                          "==========Presenting paywall==========",
                                        );
                                        _rc.presentPaywallIfNeeded();
                                      },
                                child: TextField(
                                  enabled:
                                      isPro ||
                                      ((ref.read(isProProvider).value != null &&
                                              ref.read(isProProvider).value!) ||
                                          !widget.entry.createdAt.isBefore(
                                            DateTime(
                                              DateTime.now().year,
                                              DateTime.now().month,
                                              DateTime.now().day,
                                            ),
                                          )),
                                  controller: _controller,
                                  onChanged: (_) => _onTextChanged(),
                                  maxLines: null,
                                  autofocus: _coverImageFile == null,
                                  style: textStyle,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Start writing...',
                                  ),
                                  textAlignVertical: TextAlignVertical.top,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DynamicBottomToolbar(
                      isTyping: _isTyping || _isToolbarClosed,
                      onToggle: () {
                        setState(() {
                          _isToolbarClosed = !_isToolbarClosed;
                        });
                      },
                    ),
                  ],
                ),
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

  Widget _buildCoverImageSection(ThemeData theme) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(_coverImageFile!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 24,
          right: 24,
          child: GestureDetector(
            onTap: _deleteCoverImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
