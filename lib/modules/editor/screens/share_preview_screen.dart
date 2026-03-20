import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jrnl/modules/home/models/entry_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

enum _ShareTheme { light, dark }

enum _ShareRatio { portrait, square }

enum _ShareFontSize {
  small,
  medium,
  large,
  xl;

  double get value {
    switch (this) {
      case _ShareFontSize.small:
        return 11;
      case _ShareFontSize.medium:
        return 14;
      case _ShareFontSize.large:
        return 17;
      case _ShareFontSize.xl:
        return 21;
    }
  }

  String get label {
    switch (this) {
      case _ShareFontSize.small:
        return 'S';
      case _ShareFontSize.medium:
        return 'M';
      case _ShareFontSize.large:
        return 'L';
      case _ShareFontSize.xl:
        return 'XL';
    }
  }
}

class SharePreviewScreen extends StatefulWidget {
  final EntryModel entry;
  final String entryText;

  const SharePreviewScreen({
    super.key,
    required this.entry,
    required this.entryText,
  });

  @override
  State<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<SharePreviewScreen> {
  _ShareTheme _theme = _ShareTheme.light;
  _ShareRatio _ratio = _ShareRatio.portrait;
  _ShareFontSize _fontSize = _ShareFontSize.medium;
  bool _isSharing = false;

  final ScreenshotController _screenshotController = ScreenshotController();

  // ── Derived colours ──────────────────────────────────────────────────────────

  Color get _cardBg => _theme == _ShareTheme.light
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF111111);

  Color get _textColor => _theme == _ShareTheme.light
      ? const Color(0xFF0A0A0A)
      : const Color(0xFFF0F0F0);

  Color get _subtleColor => _theme == _ShareTheme.light
      ? const Color(0xFF888888)
      : const Color(0xFF666666);

  Color get _accentLine => _theme == _ShareTheme.light
      ? const Color(0xFFE0E0E0)
      : const Color(0xFF2A2A2A);

  // ── Card content ─────────────────────────────────────────────────────────────

  String get _formattedDate =>
      DateFormat('MMMM d, yyyy').format(widget.entry.createdAt);

  /// Body trimmed to ~600 chars so the preview card stays readable.
  String get _previewBody {
    final body = widget.entryText.trim();
    return body;
  }

  // ── Share logic ───────────────────────────────────────────────────────────────

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final Uint8List? bytes = await _screenshotController.capture(
        pixelRatio: 3.0,
      );
      if (bytes == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/jrnl_share_${DateTime.now().millisecondsSinceEpoch}.png',
      ).writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path, mimeType: 'image/png'),
      ], text: 'From my journal');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final isDarkApp = appTheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: appTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appTheme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: appTheme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Share',
          style: TextStyle(
            color: appTheme.colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Preview ───────────────────────────────────────────────────────
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildCardPreview(),
                ),
              ),
            ),

            // ── Controls ──────────────────────────────────────────────────────
            _buildControls(isDarkApp),

            // ── Share button ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: _buildShareButton(appTheme),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card preview (also what gets screenshotted) ───────────────────────────────

  Widget _buildCardPreview() {
    final isPortrait = _ratio == _ShareRatio.portrait;

    return AspectRatio(
      aspectRatio: isPortrait ? 3 / 4 : 1 / 1,
      child: Screenshot(controller: _screenshotController, child: _buildCard()),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + bullet
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: _textColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formattedDate,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _subtleColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider
          Container(height: 1, color: _accentLine),

          const SizedBox(height: 20),

          // Body text
          Expanded(
            child: Text(
              _previewBody.isEmpty ? 'No content' : _previewBody,
              style: GoogleFonts.inter(
                fontSize: _fontSize.value,
                height: 1.7,
                color: _textColor,
              ),
              overflow: TextOverflow.fade,
            ),
          ),

          const SizedBox(height: 16),

          // Footer
          Container(height: 1, color: _accentLine),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'jrnl',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _subtleColor,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('HH:mm').format(DateTime.now()),
                style: GoogleFonts.inter(fontSize: 11, color: _subtleColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Controls row ──────────────────────────────────────────────────────────────

  Widget _buildControls(bool isDarkApp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          // Row 1 – theme + ratio
          Row(
            children: [
              Expanded(
                child: _SegmentedControl<_ShareTheme>(
                  isDarkApp: isDarkApp,
                  value: _theme,
                  options: const [
                    (_ShareTheme.light, Icons.light_mode_outlined, 'Light'),
                    (_ShareTheme.dark, Icons.dark_mode_outlined, 'Dark'),
                  ],
                  onChanged: (v) => setState(() => _theme = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SegmentedControl<_ShareRatio>(
                  isDarkApp: isDarkApp,
                  value: _ratio,
                  options: const [
                    (_ShareRatio.portrait, Icons.crop_portrait, '3 : 4'),
                    (_ShareRatio.square, Icons.crop_square, '1 : 1'),
                  ],
                  onChanged: (v) => setState(() => _ratio = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2 – font size
          _FontSizePicker(
            isDarkApp: isDarkApp,
            value: _fontSize,
            onChanged: (v) => setState(() => _fontSize = v),
          ),
        ],
      ),
    );
  }

  // ── Share button ──────────────────────────────────────────────────────────────

  Widget _buildShareButton(ThemeData appTheme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSharing ? null : _share,
        style: ElevatedButton.styleFrom(
          backgroundColor: appTheme.colorScheme.onSurface,
          foregroundColor: appTheme.colorScheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: appTheme.colorScheme.onSurface.withValues(
            alpha: 0.4,
          ),
        ),
        child: _isSharing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: appTheme.colorScheme.surface,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.ios_share, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Share Image',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Reusable segmented control ────────────────────────────────────────────────

class _SegmentedControl<T> extends StatelessWidget {
  final T value;
  final List<(T, IconData, String)> options;
  final ValueChanged<T> onChanged;
  final bool isDarkApp;

  const _SegmentedControl({
    required this.value,
    required this.options,
    required this.onChanged,
    required this.isDarkApp,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDarkApp
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF2F2F7);
    final selectedBg = isDarkApp ? const Color(0xFF3A3A3C) : Colors.white;
    final selectedText = isDarkApp ? Colors.white : const Color(0xFF0A0A0A);
    final unselectedText = isDarkApp
        ? const Color(0xFF8E8E93)
        : const Color(0xFF8E8E93);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: options.map((opt) {
          final (type, icon, label) = opt;
          final isSelected = value == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                height: 44,
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? selectedBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected ? selectedText : unselectedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected ? selectedText : unselectedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Font-size picker ──────────────────────────────────────────────────────────

class _FontSizePicker extends StatelessWidget {
  final _ShareFontSize value;
  final ValueChanged<_ShareFontSize> onChanged;
  final bool isDarkApp;

  const _FontSizePicker({
    required this.value,
    required this.onChanged,
    required this.isDarkApp,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDarkApp
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF2F2F7);
    final selectedBg = isDarkApp ? const Color(0xFF3A3A3C) : Colors.white;
    final selectedText = isDarkApp ? Colors.white : const Color(0xFF0A0A0A);
    final unselectedText = const Color(0xFF8E8E93);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _ShareFontSize.values.map((size) {
          final isSelected = value == size;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(size),
              child: AnimatedContainer(
                height: 44,
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? selectedBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    size.label,
                    style: TextStyle(
                      // render each option at its representative font size,
                      // clamped so they all fit in the 44-pt pill
                      fontSize: (size.value * 0.78).clamp(10.0, 16.0),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected ? selectedText : unselectedText,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
