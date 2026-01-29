import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jrnl/riverpod/preferences_rvpd.dart';

class AppThemeData {
  // Light Mode Colors (PRD Section 5.3.1)
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF0A0A0A);
  static const lightAccent = Color(0xFF333333);
  static const lightBorder = Color(0xFFE0E0E0);
  static const lightToolbarBg = Color(0xFFF5F5F5);

  // Dark Mode Colors (PRD Section 5.3.2)
  static const darkBackground = Color(0xFF000000);
  static const darkText = Color(0xFFF5F5F5);
  static const darkAccent = Color(0xFFCCCCCC);
  static const darkBorder = Color(0xFF2A2A2A);
  static const darkToolbarBg = Color(0xFF1A1A1A);

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        surface: lightBackground,
        onSurface: lightText,
        primary: lightText,
        onPrimary: lightBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightText,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightText,
        foregroundColor: lightBackground,
      ),
      dividerColor: lightBorder,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: darkBackground,
        onSurface: darkText,
        primary: darkText,
        onPrimary: darkBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkText,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkText,
        foregroundColor: darkBackground,
      ),
      dividerColor: darkBorder,
    );
  }

  static TextStyle getTextStyle(FontFamily fontFamily, int fontSize) {
    switch (fontFamily) {
      case FontFamily.inter:
        return GoogleFonts.inter(fontSize: fontSize.toDouble(), height: 1.6);
      case FontFamily.instrumentSans:
        return GoogleFonts.instrumentSans(
          fontSize: fontSize.toDouble(),
          height: 1.6,
        );
      case FontFamily.timesNewRoman:
        return GoogleFonts.crimsonText(
          fontSize: fontSize.toDouble(),
          height: 1.6,
        );
    }
  }
}
