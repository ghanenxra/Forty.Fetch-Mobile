import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBackground = Color(0xFF080A0F);
  static const Color cardSurface = Color(0xFF16181F);
  static const Color inputBoxSurface = Color(0xFF06080D);
  static const Color accent = Color(0xFF00D2FF);
  static const Color accentHover = Color(0xFF00A6CC);
  static const Color textMain = Color(0xFFF5F9FF);
  static const Color textMuted = Color(0xFF8D96A7);
  static const Color errorRed = Color(0xFFFF6B6B);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBackground,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: cardSurface,
        error: errorRed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBoxSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF03131B), // Text color #03131B from PRD
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textMain),
        bodySmall: TextStyle(color: textMuted),
      ),
    );
  }
}
