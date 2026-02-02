import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontFamily { inter, instrumentSans, timesNewRoman }

enum AppTheme { light, dark }

class Preferences {
  final FontFamily fontFamily;
  final int fontSize;
  final AppTheme theme;
  final bool isAutoBackupEnabled;
  final DateTime? lastSyncTime;

  const Preferences({
    this.fontFamily = FontFamily.inter,
    this.fontSize = 16,
    this.theme = AppTheme.light,
    this.isAutoBackupEnabled = false,
    this.lastSyncTime,
  });

  Preferences copyWith({
    FontFamily? fontFamily,
    int? fontSize,
    AppTheme? theme,
    bool? isAutoBackupEnabled,
    DateTime? lastSyncTime,
  }) {
    return Preferences(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      isAutoBackupEnabled: isAutoBackupEnabled ?? this.isAutoBackupEnabled,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

final preferencesProvider =
    AsyncNotifierProvider<PreferencesNotifier, Preferences>(
      () => PreferencesNotifier(),
    );

class PreferencesNotifier extends AsyncNotifier<Preferences> {
  static const _fontFamilyKey = 'fontFamily';
  static const _fontSizeKey = 'fontSize';
  static const _themeKey = 'theme';
  static const _autoBackupKey = 'isAutoBackupEnabled';
  static const _lastSyncTimeKey = 'lastSyncTime';

  @override
  Future<Preferences> build() async {
    final prefs = await SharedPreferences.getInstance();
    return Preferences(
      fontFamily: FontFamily.values[prefs.getInt(_fontFamilyKey) ?? 0],
      fontSize: prefs.getInt(_fontSizeKey) ?? 16,
      theme: AppTheme.values[prefs.getInt(_themeKey) ?? 0],
      isAutoBackupEnabled: prefs.getBool(_autoBackupKey) ?? false,
      lastSyncTime: prefs.containsKey(_lastSyncTimeKey)
          ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt(_lastSyncTimeKey)!)
          : null,
    );
  }

  Future<void> setFontFamily(FontFamily fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontFamilyKey, fontFamily.index);
    state = AsyncValue.data(state.value!.copyWith(fontFamily: fontFamily));
  }

  Future<void> setFontSize(int fontSize) async {
    HapticFeedback.vibrate();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontSizeKey, fontSize);
    state = AsyncValue.data(state.value!.copyWith(fontSize: fontSize));
  }

  Future<void> setTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
    state = AsyncValue.data(state.value!.copyWith(theme: theme));
  }

  Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
    state = AsyncValue.data(
      state.value!.copyWith(isAutoBackupEnabled: enabled),
    );
  }

  Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncTimeKey, time.millisecondsSinceEpoch);
    state = AsyncValue.data(state.value!.copyWith(lastSyncTime: time));
  }
}
