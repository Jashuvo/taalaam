import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS — change here, flows through the whole app
// ════════════════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ── Brand primitives ────────────────────────────────────────────────────
  static const forestGreen  = Color(0xFF1B4332);
  static const deepGreen    = Color(0xFF0D2218);
  static const midGreen     = Color(0xFF2D6A4F);
  static const teal         = Color(0xFF0D4A4A);
  static const tealLight    = Color(0xFF1A7070);
  static const brightGreen  = Color(0xFF4CAF82);
  static const gold         = Color(0xFFD4A017);
  static const cream        = Color(0xFFF5F0E8);
  static const offWhite     = Color(0xFFFAF8F3);

  // ── Light semantic ────────────────────────────────────────────────────────
  static const lightBackground          = cream;
  static const lightSurface            = offWhite;
  static const lightCard               = Color(0xFFFFFFFF);
  static const lightSurfaceContainer   = Color(0xFFEFEADE);
  static const lightSurfaceHigh        = Color(0xFFE8E2D6);
  static const lightSurfaceHighest     = Color(0xFFE0DACE);
  static const lightPrimary            = forestGreen;
  static const lightOnPrimary          = Colors.white;
  static const lightPrimaryContainer   = Color(0xFFB7DFC8);
  static const lightOnPrimaryContainer = forestGreen;
  static const lightOnSurface          = Color(0xFF1A2E22);
  static const lightOnSurfaceVariant   = Color(0xFF4A6355);
  static const lightOutline            = Color(0xFF8AAD97);
  static const lightOutlineVariant     = Color(0xFFBDD8C8);

  // ── Dark semantic ─────────────────────────────────────────────────────────
  static const darkBackground          = deepGreen;
  static const darkSurface             = Color(0xFF152E1E);
  static const darkCard                = Color(0xFF1C3A26);
  static const darkSurfaceContainer    = Color(0xFF1C3A26);
  static const darkSurfaceHigh         = Color(0xFF243F2D);
  static const darkSurfaceHighest      = Color(0xFF2B4534);
  static const darkPrimary             = brightGreen;
  static const darkOnPrimary           = deepGreen;
  static const darkPrimaryContainer    = Color(0xFF1B4332);
  static const darkOnPrimaryContainer  = brightGreen;
  static const darkOnSurface           = Color(0xFFCCE8D8);
  static const darkOnSurfaceVariant    = Color(0xFF8ABFA0);
  static const darkOutline             = Color(0xFF4A7A5C);
  static const darkOutlineVariant      = Color(0xFF2D5240);

  // ── Gradients (used by multiple screens) ─────────────────────────────────
  static const gradientStreak         = [teal, tealLight];
  static const gradientConversational = [teal, Color(0xFF1A8080)];
  static const gradientQuranic        = [forestGreen, Color(0xFF2E7D52)];
  static const gradientHeader         = [teal, tealLight];

  // ── Feedback (correct / wrong — same across themes) ──────────────────────
  static const correctBg   = Color(0xFF2E7D32); // green.shade800
  static const correctText = Colors.white;
  static const wrongBg     = Color(0xFFC62828); // red.shade800
  static const wrongText   = Colors.white;
  static const correctTile = Color(0xFF4CAF50); // green.shade600
  static const wrongTile   = Color(0xFFEF5350); // red.shade400
}

// ════════════════════════════════════════════════════════════════════════════
// SPACING + RADIUS
// ════════════════════════════════════════════════════════════════════════════

class AppSpacing {
  AppSpacing._();

  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;

  static const screenH = EdgeInsets.symmetric(horizontal: 20);
  static const screenPad = EdgeInsets.all(20);
  static const cardPad = EdgeInsets.all(16);
  static const tilePad = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
}

class AppRadius {
  AppRadius._();

  static const sm  = 8.0;
  static const md  = 12.0;
  static const lg  = 16.0;
  static const xl  = 20.0;
  static const xxl = 28.0;
  static const full = 999.0;

  static final smBorder  = BorderRadius.circular(sm);
  static final mdBorder  = BorderRadius.circular(md);
  static final lgBorder  = BorderRadius.circular(lg);
  static final xlBorder  = BorderRadius.circular(xl);
  static final xxlBorder = BorderRadius.circular(xxl);
}

// ════════════════════════════════════════════════════════════════════════════
// TYPOGRAPHY
// ════════════════════════════════════════════════════════════════════════════

class AppText {
  AppText._();

  static TextStyle arabic({
    double fontSize = 22,
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) =>
      TextStyle(
        fontFamily: 'NotoNaskhArabic',
        fontSize: fontSize,
        height: 1.8,
        fontWeight: weight,
        color: color,
      );

  static const bangla = TextStyle(
    fontFamily: 'HindSiliguri',
    fontSize: 16,
    height: 1.6,
  );
}

// ════════════════════════════════════════════════════════════════════════════
// THEME
// ════════════════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ── Light ─────────────────────────────────────────────────────────────────
  static ThemeData get light {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary:              AppColors.lightPrimary,
      onPrimary:            AppColors.lightOnPrimary,
      primaryContainer:     AppColors.lightPrimaryContainer,
      onPrimaryContainer:   AppColors.lightOnPrimaryContainer,
      secondary:            AppColors.gold,
      onSecondary:          Colors.white,
      secondaryContainer:   Color(0xFFFFECB3),
      onSecondaryContainer: Color(0xFF6B4400),
      tertiary:             AppColors.teal,
      onTertiary:           Colors.white,
      tertiaryContainer:    Color(0xFFB2DFDB),
      onTertiaryContainer:  AppColors.teal,
      error:                Color(0xFFBA1A1A),
      onError:              Colors.white,
      errorContainer:       Color(0xFFFFDAD6),
      onErrorContainer:     Color(0xFF410002),
      surface:              AppColors.lightSurface,
      onSurface:            AppColors.lightOnSurface,
      onSurfaceVariant:     AppColors.lightOnSurfaceVariant,
      outline:              AppColors.lightOutline,
      outlineVariant:       AppColors.lightOutlineVariant,
      shadow:               Colors.black,
      scrim:                Colors.black,
      inverseSurface:       AppColors.forestGreen,
      onInverseSurface:     Colors.white,
      inversePrimary:       AppColors.brightGreen,
      surfaceContainerHighest: AppColors.lightSurfaceHighest,
      surfaceContainerHigh:    AppColors.lightSurfaceHigh,
      surfaceContainer:        AppColors.lightSurfaceContainer,
      surfaceContainerLow:     AppColors.lightSurface,
      surfaceContainerLowest:  AppColors.offWhite,
    );

    return _buildTheme(cs);
  }

  // ── Dark ──────────────────────────────────────────────────────────────────
  static ThemeData get dark {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary:              AppColors.darkPrimary,
      onPrimary:            AppColors.darkOnPrimary,
      primaryContainer:     AppColors.darkPrimaryContainer,
      onPrimaryContainer:   AppColors.darkOnPrimaryContainer,
      secondary:            AppColors.gold,
      onSecondary:          AppColors.deepGreen,
      secondaryContainer:   Color(0xFF5C3D00),
      onSecondaryContainer: Color(0xFFFFDFA0),
      tertiary:             AppColors.tealLight,
      onTertiary:           AppColors.deepGreen,
      tertiaryContainer:    AppColors.teal,
      onTertiaryContainer:  AppColors.darkOnSurface,
      error:                Color(0xFFFFB4AB),
      onError:              Color(0xFF690005),
      errorContainer:       Color(0xFF93000A),
      onErrorContainer:     Color(0xFFFFDAD6),
      surface:              AppColors.darkSurface,
      onSurface:            AppColors.darkOnSurface,
      onSurfaceVariant:     AppColors.darkOnSurfaceVariant,
      outline:              AppColors.darkOutline,
      outlineVariant:       AppColors.darkOutlineVariant,
      shadow:               Colors.black,
      scrim:                Colors.black,
      inverseSurface:       AppColors.darkOnSurface,
      onInverseSurface:     AppColors.deepGreen,
      inversePrimary:       AppColors.forestGreen,
      surfaceContainerHighest: AppColors.darkSurfaceHighest,
      surfaceContainerHigh:    AppColors.darkSurfaceHigh,
      surfaceContainer:        AppColors.darkSurfaceContainer,
      surfaceContainerLow:     AppColors.darkCard,
      surfaceContainerLowest:  AppColors.darkSurface,
    );

    return _buildTheme(cs);
  }

  // ── Shared builder ────────────────────────────────────────────────────────
  static ThemeData _buildTheme(ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      fontFamily: 'HindSiliguri',

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: cs.shadow.withValues(alpha: 0.1),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: 'HindSiliguri',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorder,
          side: isDark
              ? const BorderSide(
                  color: AppColors.darkOutlineVariant,
                  width: 1,
                )
              : BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Filled button ────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
          textStyle: const TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Outlined button ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: cs.outline),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
          textStyle: const TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text button ──────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: const TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input ────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.lightSurfaceContainer,
        border: OutlineInputBorder(
          borderRadius: AppRadius.lgBorder,
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgBorder,
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgBorder,
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: TextStyle(
          fontFamily: 'HindSiliguri',
          color: cs.onSurfaceVariant,
        ),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.lightSurfaceContainer,
        selectedColor: cs.primaryContainer,
        labelStyle: TextStyle(
          fontFamily: 'HindSiliguri',
          fontSize: 12,
          color: cs.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
        side: BorderSide(color: cs.outlineVariant),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:
            isDark ? AppColors.darkCard : AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
        titleTextStyle: TextStyle(
          fontFamily: 'HindSiliguri',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'HindSiliguri',
          fontSize: 14,
          color: cs.onSurfaceVariant,
        ),
      ),

      // ── Snackbar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurfaceHigh : AppColors.forestGreen,
        contentTextStyle: const TextStyle(
          fontFamily: 'HindSiliguri',
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Progress indicator ────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceContainerHighest,
        circularTrackColor: cs.surfaceContainerHighest,
      ),

      // ── Icon ─────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 22),
      primaryIconTheme: IconThemeData(color: cs.primary, size: 22),

      // ── Typography ───────────────────────────────────────────────────────
      textTheme: _textTheme(cs),
    );
  }

  static TextTheme _textTheme(ColorScheme cs) => TextTheme(
        displayLarge: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 57,
            fontWeight: FontWeight.w400,
            color: cs.onSurface),
        displayMedium: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 45,
            fontWeight: FontWeight.w400,
            color: cs.onSurface),
        displaySmall: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 36,
            fontWeight: FontWeight.w400,
            color: cs.onSurface),
        headlineLarge: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: cs.onSurface),
        headlineMedium: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: cs.onSurface),
        headlineSmall: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: cs.onSurface),
        titleLarge: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: cs.onSurface),
        titleMedium: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: cs.onSurface),
        titleSmall: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface),
        bodyLarge: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: cs.onSurface),
        bodyMedium: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: cs.onSurface),
        bodySmall: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: cs.onSurfaceVariant),
        labelLarge: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface),
        labelMedium: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant),
        labelSmall: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant),
      );

  // ── Convenience helpers ───────────────────────────────────────────────────

  /// Arabic text style — always use with Directionality(rtl)
  static TextStyle arabicText({
    double fontSize = 22,
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) =>
      AppText.arabic(fontSize: fontSize, color: color, weight: weight);

  static const TextStyle banglaBody = AppText.bangla;
}
