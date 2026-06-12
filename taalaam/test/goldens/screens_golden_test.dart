// Golden tests for the four highest-usage screens, light + dark:
//   home, quranic track list, quran word reader, lesson completion.
//
// Determinism notes:
// - All animations run with MediaQuery.disableAnimations=true, which the
//   app's motion code respects (instant final state).
// - The weekly-XP card highlights "today" via package:clock — fixed here
//   with withClock so goldens don't depend on the day of the week.
// - LessonCompleteScreen takes duaaIndex to pin the random du'aa, and its
//   golden is captured on the first frame, before any confetti particle
//   is painted.
// - NOTE: this suite (like the whole repo) only runs from a path without
//   an apostrophe; the canonical checkout path breaks the Dart test
//   runner's URI handling. Run via a clone/copy, e.g. /tmp/taalaam-ci.
import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart'
    show ConnectivityResult;
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthClientOptions, AuthState, SupabaseClient;

import 'package:taalaam/core/theme/app_theme.dart';
import 'package:taalaam/data/local/database.dart';
import 'package:taalaam/features/auth/presentation/auth_provider.dart';
import 'package:taalaam/features/home/presentation/home_page.dart';
import 'package:taalaam/features/home/presentation/home_provider.dart';
import 'package:taalaam/features/home/presentation/track_detail_page.dart';
import 'package:taalaam/features/lesson/presentation/lesson_complete_screen.dart';
import 'package:taalaam/features/track_quran/presentation/quran_word_reader_page.dart';
import 'package:taalaam/shared/services/connectivity_service.dart';
import 'package:taalaam/shared/services/sync_service.dart';

/// No-op sync service so providers never touch Supabase in tests.
class _FakeSyncService extends SyncService {
  // autoRefreshToken: false — otherwise GoTrue starts a periodic timer that
  // trips the pending-timer check at test teardown.
  _FakeSyncService(AppDatabase db)
      : super(
          db,
          SupabaseClient('http://localhost', 'test-anon-key',
              authOptions: const AuthClientOptions(autoRefreshToken: false)),
        );

  @override
  Future<void> syncTracks() async {}
  @override
  Future<void> syncUnits(String trackId) async {}
  @override
  Future<void> syncLessons(String unitId) async {}
  @override
  Future<void> syncVocabulary(String lessonId) async {}
  @override
  Future<void> flushPendingSync() async {}
  @override
  Future<void> restoreUserData(String userId) async {}
}

Future<AppDatabase> _seedDb() async {
  final db = AppDatabase(NativeDatabase.memory());

  // Tracks
  await db.into(db.tracks).insert(TracksCompanion.insert(
        id: 't-conv',
        slug: 'conversational',
        nameAr: 'العربية للمحادثة',
        nameBn: 'কথোপকথনের আরবি',
        nameEn: 'Conversational Arabic',
        sortOrder: const drift.Value(1),
      ));
  await db.into(db.tracks).insert(TracksCompanion.insert(
        id: 't-quran',
        slug: 'quranic',
        nameAr: 'العربية القرآنية',
        nameBn: 'কুরআনিক আরবি',
        nameEn: 'Quranic Arabic',
        sortOrder: const drift.Value(2),
      ));

  // Quranic track: one unit with three lessons
  await db.into(db.units).insert(UnitsCompanion.insert(
        id: 'u1',
        trackId: 't-quran',
        slug: 'salah-vocabulary',
        titleBn: 'সালাতের শব্দভাণ্ডার',
        titleAr: const drift.Value('مفردات الصلاة'),
        sortOrder: 1,
        status: const drift.Value('published'),
      ));
  for (var i = 1; i <= 3; i++) {
    await db.into(db.lessons).insert(LessonsCompanion.insert(
          id: 'l$i',
          unitId: 'u1',
          titleBn: 'পাঠ $i: সালাতের শব্দ',
          titleAr: const drift.Value('كلمات الصلاة'),
          sortOrder: i,
          status: const drift.Value('published'),
        ));
  }

  // Quran reader: surah Al-Fatiha, ayah 1 (basmala) + tafsir
  await db.into(db.quranSurahs).insert(QuranSurahsCompanion.insert(
        number: const drift.Value(1),
        nameAr: 'الفاتحة',
        nameEn: 'Al-Fatiha',
        nameBn: 'আল-ফাতিহা',
        ayahCount: 7,
        revelation: 'Meccan',
      ));
  const words = [
    ('بِسْمِ', 'নামে'),
    ('اللَّهِ', 'আল্লাহর'),
    ('الرَّحْمَٰنِ', 'পরম করুণাময়'),
    ('الرَّحِيمِ', 'অতি দয়ালু'),
  ];
  for (var i = 0; i < words.length; i++) {
    await db.into(db.quranWords).insert(QuranWordsCompanion.insert(
          id: 'w1-1-${i + 1}',
          surah: 1,
          ayah: 1,
          position: i + 1,
          arabic: words[i].$1,
          meaningBn: drift.Value(words[i].$2),
        ));
  }
  await db.into(db.quranTafsir).insert(QuranTafsirCompanion.insert(
        id: 'tf1-1',
        surah: 1,
        ayah: 1,
        tafsirText: 'আল্লাহর নামে শুরু করছি, যিনি পরম করুণাময়, অতি দয়ালু।',
      ));

  return db;
}

Widget _harness(Widget screen, AppDatabase db, {required Brightness mode}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => screen),
  ]);
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      currentUserProvider.overrideWith((ref) => null),
      authStateProvider.overrideWith((ref) => const Stream<AuthState>.empty()),
      syncServiceProvider.overrideWith((ref) => _FakeSyncService(db)),
      connectivityProvider
          .overrideWith((ref) => Stream.value([ConnectivityResult.wifi])),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'quran_data_version': 3,
    });
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen,
    AppDatabase db,
    Brightness mode, {
    int settleFrames = 4,
  }) async {
    // 480 wide: phone-like, but with margin for the flutter_test font
    // rendering Bengali/Arabic ~2x wider than the production fonts.
    tester.view.physicalSize = const Size(480, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_harness(screen, db, mode: mode));
    for (var i = 0; i < settleFrames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // Unmount the tree and close the db inside the test body. Doing this in
  // addTearDown deadlocks: drift's close/markAsClosed completes via fake-zone
  // timers that only fire while the test can still pump frames.
  // Timed pumps: drift schedules zero-duration markAsClosed timers that only
  // fire when fake time actually elapses (a plain pump() doesn't advance it).
  Future<void> cleanupScreen(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    db.close().ignore();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  }

  for (final mode in [Brightness.light, Brightness.dark]) {
    final suffix = mode == Brightness.dark ? 'dark' : 'light';

    testWidgets('home page golden ($suffix)', (tester) async {
      // Fixed Monday so the weekly-XP "today" column is stable.
      await withClock(Clock.fixed(DateTime(2026, 6, 8, 10)), () async {
        final db = await _seedDb();
        await pumpScreen(tester, const LearnTab(), db, mode);
        await expectLater(
          find.byType(LearnTab),
          matchesGoldenFile('home_$suffix.png'),
        );
        await cleanupScreen(tester, db);
      });
    });

    testWidgets('quranic track list golden ($suffix)', (tester) async {
      final db = await _seedDb();
      await pumpScreen(
          tester, const TrackDetailPage(slug: 'quranic'), db, mode);
      await expectLater(
        find.byType(TrackDetailPage),
        matchesGoldenFile('track_quranic_$suffix.png'),
      );
      await cleanupScreen(tester, db);
    });

    testWidgets('quran word reader golden ($suffix)', (tester) async {
      final db = await _seedDb();
      await pumpScreen(tester, const QuranWordReaderPage(), db, mode);
      await expectLater(
        find.byType(QuranWordReaderPage),
        matchesGoldenFile('quran_reader_$suffix.png'),
      );
      await cleanupScreen(tester, db);
    });

    testWidgets('lesson completion golden ($suffix)', (tester) async {
      final db = await _seedDb();
      // First frame only: count-up/ring render final values instantly
      // (disableAnimations) and no confetti particle has been painted yet.
      await pumpScreen(
        tester,
        const LessonCompleteScreen(
          lessonId: 'l1',
          unitId: 'u1',
          correctCount: 10,
          totalCount: 10,
          xpEarned: 50,
          perfectBonus: 10,
          gemReward: 2,
          totalXpAfter: 350,
          duaaIndex: 0,
        ),
        db,
        mode,
        settleFrames: 0,
      );
      await expectLater(
        find.byType(LessonCompleteScreen),
        matchesGoldenFile('lesson_complete_$suffix.png'),
      );
      await cleanupScreen(tester, db);
    });
  }
}
