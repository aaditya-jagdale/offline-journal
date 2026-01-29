import 'dart:async';
import 'package:flutter/material.dart';

class TopSnackbar extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  const TopSnackbar({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 3),
    required this.onDismiss,
  });

  @override
  State<TopSnackbar> createState() => _TopSnackbarState();
}

class _TopSnackbarState extends State<TopSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.black : Colors.white;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Material(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              elevation: 4,
              child: InkWell(
                onTap: _dismiss,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SnackbarService {
  static final SnackbarService _instance = SnackbarService._internal();
  factory SnackbarService() => _instance;
  SnackbarService._internal();

  OverlayEntry? _currentEntry;
  final List<_SnackbarRequest> _queue = [];
  bool _isShowing = false;

  void show(BuildContext context, String message, {Duration? duration}) {
    _queue.add(
      _SnackbarRequest(message, duration ?? const Duration(seconds: 3)),
    );
    _processQueue(context);
  }

  void _processQueue(BuildContext context) {
    if (_isShowing || _queue.isEmpty) return;
    _isShowing = true;

    final request = _queue.removeAt(0);
    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: TopSnackbar(
          message: request.message,
          duration: request.duration,
          onDismiss: () {
            _currentEntry?.remove();
            _currentEntry = null;
            _isShowing = false;
            _processQueue(context);
          },
        ),
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }
}

class _SnackbarRequest {
  final String message;
  final Duration duration;
  _SnackbarRequest(this.message, this.duration);
}
