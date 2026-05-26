#!/bin/bash
# Ta'allam Project Scaffold Script
# Run this ONCE in your desired parent directory
# Usage: chmod +x setup.sh && ./setup.sh

set -e

echo "🕌 Setting up Ta'allam (تعلَّم) project..."

# ─── Flutter Project ───────────────────────────────────────────
flutter create taalaam --org com.taalaam --platforms android,ios,web
cd taalaam

# ─── Copy CLAUDE.md files ─────────────────────────────────────
# (Copy from your downloaded docs to here)
mkdir -p docs
echo "⚠️  Copy CLAUDE.md and docs/ from the provided files"

# ─── Folder Structure ─────────────────────────────────────────
mkdir -p lib/core/router
mkdir -p lib/core/theme
mkdir -p lib/core/constants
mkdir -p lib/core/utils

# Features
for feature in auth home lesson srs track_conv track_quran admin; do
  mkdir -p lib/features/$feature/data
  mkdir -p lib/features/$feature/domain
  mkdir -p lib/features/$feature/presentation/widgets
done

# Data layer
mkdir -p lib/data/local/tables
mkdir -p lib/data/local/daos
mkdir -p lib/data/remote
mkdir -p lib/data/models

# Shared
mkdir -p lib/shared/widgets
mkdir -p lib/shared/services

# Supabase
mkdir -p supabase/functions/process-content
mkdir -p supabase/functions/generate-exercise
mkdir -p supabase/migrations

# Tests
mkdir -p test/unit
mkdir -p test/widget
mkdir -p test/integration

# Assets
mkdir -p assets/audio
mkdir -p assets/fonts
mkdir -p assets/images

# ─── Create main_admin.dart entry point ───────────────────────
cat > lib/main_admin.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initServices();
  runApp(
    const ProviderScope(
      child: TaalamaApp(flavor: AppFlavor.admin),
    ),
  );
}
EOF

# ─── Create app.dart ──────────────────────────────────────────
cat > lib/app.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

enum AppFlavor { learner, admin }

class TaalamaApp extends ConsumerWidget {
  final AppFlavor flavor;
  const TaalamaApp({required this.flavor, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider(flavor));
    return MaterialApp.router(
      title: 'Ta\'allam — تعلَّم',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      // Global Arabic text direction support
      builder: (context, child) => Directionality(
        textDirection: TextDirection.ltr, // outer app is LTR (Bangla UI)
        child: child!,
      ),
    );
  }
}
EOF

# ─── Create theme ──────────────────────────────────────────────
cat > lib/core/theme/app_theme.dart << 'EOF'
import 'package:flutter/material.dart';

/// Islamic color palette — green, gold, warm off-white
class AppTheme {
  static const _primaryGreen = Color(0xFF1B4332);
  static const _gold = Color(0xFFD4A017);
  static const _offWhite = Color(0xFFF5F0E8);
  static const _darkBackground = Color(0xFF0D2218);

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryGreen,
      primary: _primaryGreen,
      secondary: _gold,
      surface: _offWhite,
    ),
    fontFamily: 'HindSiliguri', // Bangla default
    useMaterial3: true,
  );

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryGreen,
      brightness: Brightness.dark,
      primary: Color(0xFF4CAF50),
      secondary: _gold,
      surface: _darkBackground,
    ),
    fontFamily: 'HindSiliguri',
    useMaterial3: true,
  );

  /// Use this for all Arabic text
  static TextStyle arabicText({double fontSize = 22}) => TextStyle(
    fontFamily: 'NotoNaskhArabic',
    fontSize: fontSize,
    height: 1.8,
    color: _primaryGreen,
  );

  /// Bangla body text
  static const TextStyle banglaBody = TextStyle(
    fontFamily: 'HindSiliguri',
    fontSize: 16,
    height: 1.6,
  );
}
EOF

# ─── Create constants ─────────────────────────────────────────
cat > lib/core/constants/app_constants.dart << 'EOF'
class AppConstants {
  // Supabase (loaded from --dart-define at build time)
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Gamification
  static const int heartsPerLesson = 5;
  static const int xpPerExercise = 5;
  static const int xpBonus = 10; // lesson completion bonus

  // SRS
  static const int maxDailyReviews = 50;

  // Tracks
  static const String trackConversational = 'conversational';
  static const String trackQuranic = 'quranic';

  // Islamic
  static const List<String> completionDuaas = [
    'بَارَكَ اللَّهُ فِيكَ — আল্লাহ আপনার মধ্যে বরকত দিন',
    'جَزَاكَ اللَّهُ خَيْرًا — আল্লাহ আপনাকে উত্তম প্রতিদান দিন',
    'وَفَّقَكَ اللَّهُ — আল্লাহ আপনাকে তাওফিক দিন',
  ];
}
EOF

# ─── Create router skeleton ───────────────────────────────────
cat > lib/core/router/app_router.dart << 'EOF'
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../app.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref, AppFlavor flavor) {
  return GoRouter(
    initialLocation: flavor == AppFlavor.admin ? '/admin' : '/home',
    routes: [
      // LEARNER ROUTES
      GoRoute(path: '/onboarding', builder: (ctx, state) => const Placeholder()),
      GoRoute(path: '/home', builder: (ctx, state) => const Placeholder()),
      GoRoute(path: '/track/:trackId', builder: (ctx, state) => const Placeholder()),
      GoRoute(path: '/lesson/:lessonId', builder: (ctx, state) => const Placeholder()),
      GoRoute(path: '/review', builder: (ctx, state) => const Placeholder()),
      GoRoute(path: '/profile', builder: (ctx, state) => const Placeholder()),

      // ADMIN ROUTES (only accessible with admin auth)
      GoRoute(path: '/admin', builder: (ctx, state) => const Placeholder()),
      GoRoute(path: '/admin/upload', builder: (ctx, state) => const Placeholder()),
      GoRoute(path: '/admin/review', builder: (ctx, state) => const Placeholder()),
      GoRoute(path: '/admin/review/:unitId', builder: (ctx, state) => const Placeholder()),
    ],
  );
}
EOF

# ─── pubspec.yaml with all dependencies ───────────────────────
cat > pubspec.yaml << 'EOF'
name: taalaam
description: Sahih Arabic Learning App for Bangladeshi Salafi Muslims
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.3.5
  hooks_riverpod: ^2.6.1
  flutter_hooks: ^0.20.5

  # Navigation
  go_router: ^14.6.2

  # Local database (offline-first)
  drift: ^2.21.0
  drift_flutter: ^0.2.4
  sqlite3_flutter_libs: ^0.5.25

  # Backend
  supabase_flutter: ^2.8.1

  # Models (immutable, serializable)
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

  # SRS algorithm
  fsrs4dart: ^0.2.0

  # Audio
  just_audio: ^0.9.42
  flutter_cache_manager: ^3.4.1

  # UI utilities
  gap: ^3.0.1
  google_fonts: ^6.2.1

  # PDF (admin panel)
  syncfusion_flutter_pdf: ^26.2.14

  # File handling (admin)
  file_picker: ^8.1.7

  # Connectivity
  connectivity_plus: ^6.1.1

  # Push notifications
  firebase_messaging: ^15.1.6
  firebase_core: ^3.8.1

  # Utils
  shared_preferences: ^2.3.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

  # Code generation
  riverpod_generator: ^2.4.3
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  build_runner: ^2.4.13
  drift_dev: ^2.21.0

flutter:
  uses-material-design: true

  assets:
    - assets/audio/
    - assets/images/

  fonts:
    - family: NotoNaskhArabic
      fonts:
        - asset: assets/fonts/NotoNaskhArabic-Regular.ttf
        - asset: assets/fonts/NotoNaskhArabic-Bold.ttf
          weight: 700
    - family: HindSiliguri
      fonts:
        - asset: assets/fonts/HindSiliguri-Regular.ttf
        - asset: assets/fonts/HindSiliguri-Bold.ttf
          weight: 700
EOF

echo ""
echo "✅ Project scaffold complete!"
echo ""
echo "NEXT STEPS:"
echo "1. cd taalaam"
echo "2. Copy CLAUDE.md and docs/ from provided files"
echo "3. Download fonts: https://fonts.google.com/noto/specimen/Noto+Naskh+Arabic"
echo "   and https://fonts.google.com/specimen/Hind+Siliguri → assets/fonts/"
echo "4. supabase init && supabase start"
echo "5. flutter pub get"
echo "6. dart run build_runner build --delete-conflicting-outputs"
echo "7. flutter run -d chrome -t lib/main_admin.dart   ← test admin panel first"
echo "8. flutter run -d chrome -t lib/main.dart         ← test learner app"
echo ""
echo "📖 Read docs/features.md and start checking off Phase 1 items"
echo "🕌 بَارَكَ اللَّهُ فِيكَ"
