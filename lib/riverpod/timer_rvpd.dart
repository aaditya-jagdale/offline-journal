import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimerState {
  final int selectedDuration; // 10, 20, or 30 minutes
  final int remainingSeconds;
  final bool isRunning;

  const TimerState({
    this.selectedDuration = 10,
    this.remainingSeconds = 0,
    this.isRunning = false,
  });

  TimerState copyWith({
    int? selectedDuration,
    int? remainingSeconds,
    bool? isRunning,
  }) {
    return TimerState(
      selectedDuration: selectedDuration ?? this.selectedDuration,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  String get displayTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(
  () => TimerNotifier(),
);

class TimerNotifier extends Notifier<TimerState> {
  Timer? _timer;

  @override
  TimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return const TimerState();
  }

  void selectDuration(int minutes) {
    if (state.isRunning) return;
    HapticFeedback.vibrate();
    state = state.copyWith(selectedDuration: minutes);
  }

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(
      remainingSeconds: state.selectedDuration * 60,
      isRunning: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 1) {
        stop();
        // Timer completed - snackbar will be shown by the widget
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(remainingSeconds: 0, isRunning: false);
  }
}
