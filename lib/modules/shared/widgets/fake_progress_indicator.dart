import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class FakeProgressIndicator extends StatefulWidget {
  final int maxTimeSeconds;
  final double height;
  final Color? backgroundColor;
  final Color? progressColor;

  const FakeProgressIndicator({
    super.key,
    required this.maxTimeSeconds,
    this.height = 6.0,
    this.backgroundColor,
    this.progressColor,
  });

  @override
  State<FakeProgressIndicator> createState() => _FakeProgressIndicatorState();
}

class _FakeProgressIndicatorState extends State<FakeProgressIndicator>
    with TickerProviderStateMixin {
  double _currentProgress = 0.0;
  final Random _random = Random();
  Timer? _timer;
  late final Duration _totalDuration;
  late final DateTime _startTime;
  DateTime? _stalledUntil;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  final List<_Sparkle> _sparkles = [];
  Timer? _sparkleAnimationTimer;

  @override
  void initState() {
    super.initState();
    _totalDuration = Duration(seconds: widget.maxTimeSeconds);
    _startTime = DateTime.now();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startRealisticProgress();
    _generateSparkles();
    _animateSparkles();
  }

  void _generateSparkles() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentProgress > 0.1 && _currentProgress < 0.99) {
        final sparkleCount = _random.nextDouble() < 0.6 ? 1 : 2;
        for (int i = 0; i < sparkleCount; i++) {
          final sparkleProgress = _random.nextDouble() * _currentProgress;
          _sparkles.add(
            _Sparkle(
              position: sparkleProgress.clamp(0.0, _currentProgress),
              size: 5.0 + _random.nextDouble() * 5.0,
              animation: 0.0,
              delay: _random.nextDouble() * 0.2,
            ),
          );
        }
        setState(() {});
      }
    });
  }

  void _startRealisticProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      final now = DateTime.now();
      final elapsed = now.difference(_startTime);

      if (_currentProgress >= 0.99 || elapsed >= _totalDuration) {
        setState(() {
          _currentProgress = 0.99;
        });
        timer.cancel();
        _timer = null;
        return;
      }

      if (_stalledUntil != null && now.isBefore(_stalledUntil!)) {
        return;
      }
      if (_stalledUntil == null && _random.nextDouble() < 0.08) {
        final stallMs = 400 + _random.nextInt(900);
        _stalledUntil = now.add(Duration(milliseconds: stallMs));
        return;
      }
      if (_stalledUntil != null && now.isAfter(_stalledUntil!)) {
        _stalledUntil = null;
      }

      final timeScale = 15.0 / widget.maxTimeSeconds;
      final r = _random.nextDouble();
      double delta;
      if (r < 0.40) {
        delta = (0.001 + _random.nextDouble() * 0.004) * timeScale;
      } else if (r < 0.75) {
        delta = (0.006 + _random.nextDouble() * 0.012) * timeScale;
      } else if (r < 0.93) {
        delta = (0.015 + _random.nextDouble() * 0.02) * timeScale;
      } else {
        delta = (0.03 + _random.nextDouble() * 0.05) * timeScale;
      }

      final remaining = 0.99 - _currentProgress;
      final remainingTime = _totalDuration - elapsed;
      if (remainingTime.inMilliseconds < 1500 && remaining > 0.02) {
        delta = max(delta, 0.02 * timeScale);
      }

      double next = (_currentProgress + delta).clamp(0.0, 0.99);
      if (next <= _currentProgress) {
        next = (_currentProgress + 0.005 * timeScale).clamp(0.0, 0.99);
      }

      setState(() {
        _currentProgress = next;
      });
    });
  }

  void _animateSparkles() {
    _sparkleAnimationTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      bool needsUpdate = false;
      for (var sparkle in _sparkles) {
        if (sparkle.animation < 1.0) {
          sparkle.animation += 0.02;
          if (sparkle.animation > 1.0) {
            sparkle.animation = 1.0;
          }
          needsUpdate = true;
        }
      }
      if (needsUpdate) {
        setState(() {});
      }
      _sparkles.removeWhere((s) => s.animation >= 1.0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sparkleAnimationTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  String _getEncouragingText(double progress) {
    if (progress < 0.20) return "✨ Getting started...";
    if (progress < 0.40) return "🎨 Creating magic...";
    if (progress < 0.60) return "🌟 Almost there...";
    if (progress < 0.80) return "💫 Final touches...";
    return "🚀 Finishing up...";
  }

  @override
  Widget build(BuildContext context) {
    final percentText =
        '${(_currentProgress * 100).clamp(0, 99).toStringAsFixed(0)}%';
    final progressColor = widget.progressColor ?? const Color(0xFFFF8A80);
    final backgroundColor = widget.backgroundColor ?? Colors.grey[200];

    final gradientColors = [
      progressColor,
      Color.lerp(progressColor, const Color(0xFFFFB74D), 0.3) ?? progressColor,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: widget.height * 1.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height * 0.9),
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        height: widget.height * 1.8,
                        width: constraints.maxWidth * _currentProgress,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            widget.height * 0.9,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              gradientColors[0].withOpacity(0.95),
                              gradientColors[1].withOpacity(
                                0.85 + _glowAnimation.value * 0.15,
                              ),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: progressColor.withOpacity(
                                0.5 * _glowAnimation.value,
                              ),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(widget.height * 0.9),
                    child: SizedBox(
                      height: widget.height * 1.8,
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, widget.height * 1.8),
                        painter: _SparklePainter(
                          sparkles: _sparkles,
                          progress: _currentProgress,
                          barHeight: widget.height * 1.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          _getEncouragingText(_currentProgress),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: progressColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            percentText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: progressColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _Sparkle {
  final double position;
  final double size;
  double animation;
  final double delay;

  _Sparkle({
    required this.position,
    required this.size,
    required this.animation,
    required this.delay,
  });
}

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double progress;
  final double barHeight;
  final Color color;

  _SparklePainter({
    required this.sparkles,
    required this.progress,
    required this.barHeight,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var sparkle in sparkles) {
      if (sparkle.animation < sparkle.delay || sparkle.animation >= 1.0) {
        continue;
      }

      final adjustedAnimation =
          (sparkle.animation - sparkle.delay) / (1.0 - sparkle.delay);
      final opacity = (1.0 - adjustedAnimation) * 0.9;
      final sparklePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withOpacity(opacity);

      final x = size.width * sparkle.position;
      final y = barHeight / 2;

      final currentSize = sparkle.size * (0.5 + adjustedAnimation * 0.5);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(adjustedAnimation * 2 * pi);

      _drawStar(canvas, Offset(0, 0), currentSize, sparklePaint);

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const numPoints = 5;
    final angle = (2 * pi) / numPoints;

    for (int i = 0; i < numPoints * 2; i++) {
      final r = i.isEven ? radius : radius * 0.4;
      final theta = i * angle / 2 - pi / 2;
      final x = center.dx + r * cos(theta);
      final y = center.dy + r * sin(theta);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) {
    return sparkles != oldDelegate.sparkles || progress != oldDelegate.progress;
  }
}
