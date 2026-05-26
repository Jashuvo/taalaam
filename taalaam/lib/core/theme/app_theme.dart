import 'package:flutter/material.dart';

/// Islamic color palette — deep green, gold, warm off-white
class AppTheme {
  AppTheme._();

  static const _primaryGreen = Color(0xFF1B4332);
  static const _gold = Color(0xFFD4A017);
  static const _offWhite = Color(0xFFF5F0E8);
  static const _darkBg = Color(0xFF0D2218);

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryGreen,
          primary: _primaryGreen,
          secondary: _gold,
          surface: _offWhite,
        ),
        fontFamily: 'HindSiliguri',
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryGreen,
          brightness: Brightness.dark,
          primary: const Color(0xFF4CAF82),
          secondary: _gold,
          surface: _darkBg,
        ),
        fontFamily: 'HindSiliguri',
        useMaterial3: true,
      );

  /// Wrap Arabic text in Directionality(rtl) + use this style
  static TextStyle arabicText({double fontSize = 22, Color? color}) => TextStyle(
        fontFamily: 'NotoNaskhArabic',
        fontSize: fontSize,
        height: 1.8,
        color: color,
      );

  static const TextStyle banglaBody = TextStyle(
    fontFamily: 'HindSiliguri',
    fontSize: 16,
    height: 1.6,
  );
}
