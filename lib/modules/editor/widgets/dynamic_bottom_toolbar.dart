import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jrnl/riverpod/preferences_rvpd.dart';
import 'package:jrnl/riverpod/timer_rvpd.dart';
import 'package:jrnl/widgets/top_snackbar.dart';

class DynamicBottomToolbar extends ConsumerStatefulWidget {
  final bool isTyping;

  const DynamicBottomToolbar({super.key, required this.isTyping});

  @override
  ConsumerState<DynamicBottomToolbar> createState() =>
      _DynamicBottomToolbarState();
}

class _DynamicBottomToolbarState extends ConsumerState<DynamicBottomToolbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  int? _prevRemainingSeconds;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1))
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOutCubicEmphasized,
          ),
        );
    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(DynamicBottomToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTyping && !oldWidget.isTyping) {
      _controller.forward();
    } else if (!widget.isTyping && oldWidget.isTyping) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final prefs = ref.watch(preferencesProvider).value;
    final timerState = ref.watch(timerProvider);

    // Check for timer completion
    if (_prevRemainingSeconds != null &&
        _prevRemainingSeconds! > 0 &&
        timerState.remainingSeconds == 0 &&
        !timerState.isRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SnackbarService().show(context, 'Timer complete');
        }
      });
    }
    _prevRemainingSeconds = timerState.remainingSeconds;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.6)
                : Colors.white.withOpacity(0.7),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: SafeArea(
                top: false,
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildTimerSection(timerState, isDark),
                      const SizedBox(width: 20),
                      _buildFontSizeSection(prefs, isDark),
                      const SizedBox(width: 20),
                      _buildFontFamilySection(prefs, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerSection(TimerState timerState, bool isDark) {
    if (timerState.isRunning) {
      return _buildSection(
        isDark: isDark,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timerState.displayTime,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.stop_rounded,
              isDark: isDark,
              onTap: () => ref.read(timerProvider.notifier).stop(),
            ),
          ],
        ),
      );
    }

    final durations = [10, 20, 30];
    final selectedIndex = durations.indexOf(timerState.selectedDuration);

    return _buildSection(
      isDark: isDark,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSlidingSelector(
            items: durations.map((d) => '$d').toList(),
            selectedIndex: selectedIndex,
            isDark: isDark,
            onTap: (index) => ref
                .read(timerProvider.notifier)
                .selectDuration(durations[index]),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.play_arrow_rounded,
            isDark: isDark,
            onTap: () => ref.read(timerProvider.notifier).start(),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSection(Preferences? prefs, bool isDark) {
    final sizes = [16, 18, 20];
    final currentSize = prefs?.fontSize ?? 16;
    final selectedIndex = sizes.indexOf(currentSize);

    return _buildSection(
      isDark: isDark,
      child: _buildSlidingSelector(
        items: sizes.map((s) => '$s').toList(),
        selectedIndex: selectedIndex,
        isDark: isDark,
        onTap: (index) =>
            ref.read(preferencesProvider.notifier).setFontSize(sizes[index]),
      ),
    );
  }

  Widget _buildFontFamilySection(Preferences? prefs, bool isDark) {
    final currentFont = prefs?.fontFamily ?? FontFamily.inter;
    final fonts = [
      FontFamily.inter,
      FontFamily.instrumentSans,
      FontFamily.timesNewRoman,
    ];
    final labels = ['Inter', 'Instrument Sans', 'Times New Roman'];
    final selectedIndex = fonts.indexOf(currentFont);

    return _buildSection(
      isDark: isDark,
      child: _buildSlidingSelector(
        items: labels,
        selectedIndex: selectedIndex,
        isDark: isDark,
        onTap: (index) =>
            ref.read(preferencesProvider.notifier).setFontFamily(fonts[index]),
      ),
    );
  }

  Widget _buildSection({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }

  Widget _buildSlidingSelector({
    required List<String> items,
    required int selectedIndex,
    required bool isDark,
    required Function(int) onTap,
  }) {
    return _SlidingSelector(
      items: items,
      selectedIndex: selectedIndex,
      isDark: isDark,
      onTap: onTap,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black,
          size: 20,
        ),
      ),
    );
  }
}

class _SlidingSelector extends StatefulWidget {
  final List<String> items;
  final int selectedIndex;
  final bool isDark;
  final Function(int) onTap;

  const _SlidingSelector({
    required this.items,
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SlidingSelector> createState() => _SlidingSelectorState();
}

class _SlidingSelectorState extends State<_SlidingSelector> {
  final List<GlobalKey> _keys = [];
  double _indicatorLeft = 0;
  double _indicatorWidth = 48;

  @override
  void initState() {
    super.initState();
    _keys.addAll(List.generate(widget.items.length, (_) => GlobalKey()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator());
  }

  @override
  void didUpdateWidget(_SlidingSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.items.length != widget.items.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator());
    }
  }

  void _updateIndicator() {
    if (!mounted ||
        widget.selectedIndex < 0 ||
        widget.selectedIndex >= _keys.length) {
      return;
    }

    final key = _keys[widget.selectedIndex];
    final box = key.currentContext?.findRenderObject() as RenderBox?;

    if (box != null && mounted) {
      setState(() {
        _indicatorWidth = box.size.width;
        _indicatorLeft =
            box.localToGlobal(Offset.zero).dx -
            (context.findRenderObject() as RenderBox)
                .localToGlobal(Offset.zero)
                .dx;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const buttonPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    const spacing = 8.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated selection indicator
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          left: _indicatorLeft,
          child: Container(
            width: _indicatorWidth,
            height: 30,
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isDark ? Colors.white : Colors.black)
                      .withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        // Buttons row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.items.length; i++) ...[
              GestureDetector(
                key: _keys[i],
                onTap: () => widget.onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: buttonPadding,
                  child: Text(
                    widget.items[i],
                    style: TextStyle(
                      color: i == widget.selectedIndex
                          ? (widget.isDark ? Colors.white : Colors.black)
                          : (widget.isDark ? Colors.white : Colors.black)
                                .withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: i == widget.selectedIndex
                          ? FontWeight.w600
                          : FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              if (i != widget.items.length - 1) const SizedBox(width: spacing),
            ],
          ],
        ),
      ],
    );
  }
}
