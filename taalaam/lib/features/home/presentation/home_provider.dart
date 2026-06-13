import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/local/database.dart';
import '../../../shared/services/gamification_service.dart';
import '../../../shared/services/sync_service.dart';
import '../../auth/presentation/auth_provider.dart';
import 'leaderboard_page.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(appDatabaseProvider),
    Supabase.instance.client,
  );
});

final tracksProvider = StreamProvider<List<Track>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  ref.read(syncServiceProvider).syncTracks().ignore();
  return (db.select(db.tracks)
        ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)]))
      .watch();
});

final unitsForTrackProvider =
    StreamProvider.family<List<Unit>, String>((ref, trackId) {
  final db = ref.watch(appDatabaseProvider);
  ref.read(syncServiceProvider).syncUnits(trackId).ignore();
  return (db.select(db.units)
        ..where((t) => t.trackId.equals(trackId))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.sequenceOrder)]))
      .watch();
});

final streakProvider = StreamProvider<Streak?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.streaks)
        ..where((t) => t.userId.equals(user.id)))
      .watchSingleOrNull();
});

/// Due review cards (state > 0, interval expired) — capped at 20 for top-bar badge.
/// Uses the same INNER JOIN as getReviewCards() so the count matches the session.
final dueCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  return (db.select(db.srsCards).join([
        drift.innerJoin(db.vocabulary,
            db.vocabulary.id.equalsExp(db.srsCards.vocabularyId)),
      ])
        ..where(db.srsCards.userId.equals(user.id) &
            db.srsCards.state.isBiggerThanValue(0) &
            db.srsCards.dueDate.isSmallerOrEqualValue(now)))
      .watch()
      .map((rows) => rows.length.clamp(0, 20));
});

/// New cards (state == 0, never reviewed) — capped at 10 for মুখস্থ badge.
/// Uses the same INNER JOIN as getNewCards() so the count matches the session.
final newCardCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  return (db.select(db.srsCards).join([
        drift.innerJoin(db.vocabulary,
            db.vocabulary.id.equalsExp(db.srsCards.vocabularyId)),
      ])
        ..where(db.srsCards.userId.equals(user.id) &
            db.srsCards.state.equals(0) &
            db.srsCards.dueDate.isSmallerOrEqualValue(now)))
      .watch()
      .map((rows) => rows.length.clamp(0, 10));
});

final trackBySlugProvider =
    StreamProvider.family<Track?, String>((ref, slug) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.tracks)..where((t) => t.slug.equals(slug)))
      .watchSingleOrNull();
});

final lessonsForUnitProvider =
    StreamProvider.family<List<Lesson>, String>((ref, unitId) {
  final db = ref.watch(appDatabaseProvider);
  ref.read(syncServiceProvider).syncLessons(unitId).ignore();
  // Level-first sort: beginner → intermediate → advanced, then sort_order.
  // Exam lessons are excluded — shown separately as the exam node.
  const levelTier = {'beginner': 0, 'intermediate': 1, 'advanced': 2};
  return (db.select(db.lessons)
        ..where((t) => t.unitId.equals(unitId) & t.isExam.equals(false))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)]))
      .watch()
      .map((rows) {
    final sorted = [...rows];
    sorted.sort((a, b) {
      final la = levelTier[a.level] ?? 1;
      final lb = levelTier[b.level] ?? 1;
      if (la != lb) return la.compareTo(lb);
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return sorted;
  });
});

/// Returns the exam lesson for a unit (is_exam = true), or null if not created yet.
final examLessonForUnitProvider =
    StreamProvider.family<Lesson?, String>((ref, unitId) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.lessons)
        ..where((t) => t.unitId.equals(unitId) & t.isExam.equals(true))
        ..limit(1))
      .watchSingleOrNull();
});

final completedLessonIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value({});
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.userProgress)
        ..where((t) => t.userId.equals(user.id)))
      .watch()
      .map((rows) => rows.map((r) => r.lessonId).toSet());
});

final bookmarkedLessonIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value({});
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.bookmarks)
        ..where((t) => t.userId.equals(user.id)))
      .watch()
      .map((rows) => rows.map((r) => r.lessonId).toSet());
});

class BookmarkNotifier extends StateNotifier<void> {
  final AppDatabase _db;
  final String _userId;
  BookmarkNotifier(this._db, this._userId) : super(null);

  Future<void> toggle(String lessonId, bool currentlyBookmarked) async {
    final id = '${_userId}_$lessonId';
    if (currentlyBookmarked) {
      await (_db.delete(_db.bookmarks)..where((t) => t.id.equals(id))).go();
      // Remove from Supabase (fire-and-forget)
      Supabase.instance.client
          .from('bookmarks')
          .delete()
          .eq('id', id)
          .then((_) {})
          .catchError((_) {});
    } else {
      await _db.into(_db.bookmarks).insertOnConflictUpdate(
            BookmarksCompanion.insert(
              id: id,
              userId: _userId,
              lessonId: lessonId,
            ),
          );
      // Push to Supabase (fire-and-forget)
      Supabase.instance.client.from('bookmarks').upsert({
        'id': id,
        'user_id': _userId,
        'lesson_id': lessonId,
      }).then((_) {}).catchError((_) {});
    }
  }
}

final bookmarkNotifierProvider =
    StateNotifierProvider.autoDispose<BookmarkNotifier, void>((ref) {
  final user = ref.watch(currentUserProvider);
  final db = ref.watch(appDatabaseProvider);
  return BookmarkNotifier(db, user?.id ?? '');
});

class StreakFreezeNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  final String _userId;
  StreakFreezeNotifier(this._db, this._userId)
      : super(const AsyncValue.data(null));

  Future<void> freeze() async {
    state = const AsyncValue.loading();
    try {
      await _db.customStatement(
        'UPDATE streaks SET freeze_count = freeze_count + 1, last_freezed_at = ? WHERE user_id = ?',
        [DateTime.now().millisecondsSinceEpoch, _userId],
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Spends one freeze to protect a streak that's about to lapse: if the
  /// last activity was 2+ days ago (the streak would reset on next lesson),
  /// backdates `last_activity_date` to yesterday so the streak continues.
  /// Returns true if a freeze was spent, false if not needed or unavailable.
  Future<bool> useFreeze() async {
    final row = await (_db.select(_db.streaks)
          ..where((t) => t.userId.equals(_userId)))
        .getSingleOrNull();
    if (row == null || row.freezeCount <= 0) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = row.lastActivityDate;
    final diff = lastDate == null
        ? 999
        : today.difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;
    if (diff < 2) return false;

    state = const AsyncValue.loading();
    try {
      final yesterday = today.subtract(const Duration(days: 1));
      await (_db.update(_db.streaks)..where((t) => t.userId.equals(_userId)))
          .write(StreaksCompanion(
        freezeCount: drift.Value(row.freezeCount - 1),
        lastActivityDate: drift.Value(yesterday),
        lastFreezedAt: drift.Value(now),
      ));
      Supabase.instance.client.from('streaks').upsert({
        'user_id': _userId,
        'freeze_count': row.freezeCount - 1,
        'last_activity_date':
            yesterday.toIso8601String().substring(0, 10),
      }).then((_) {}).catchError((_) {});
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final streakFreezeProvider = StateNotifierProvider.autoDispose
    .family<StreakFreezeNotifier, AsyncValue<void>, String>(
        (ref, userId) {
  return StreakFreezeNotifier(ref.watch(appDatabaseProvider), userId);
});

// ── Track progress: {total, completed} lesson counts ─────────────────────────

class TrackProgress {
  final int total;
  final int completed;
  const TrackProgress({required this.total, required this.completed});
  double get fraction => total == 0 ? 0 : completed / total;
}

/// Weekly XP earned in the current Mon–Sun window (SharedPreferences-backed).
final weeklyXpProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return GamificationService.getWeeklyXp(user.id);
});

/// Whether today's first-lesson 2x XP bonus is still unclaimed.
final firstLessonBonusAvailableProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return GamificationService.firstLessonBonusAvailable(user.id);
});

/// The current user's 1-based leaderboard rank by total XP, or null if
/// they're not signed in or not present in the (top-50) leaderboard.
final leaderboardRankProvider = FutureProvider<int?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final board = await ref.watch(leaderboardProvider.future);
  final idx = board.indexWhere((e) => e['user_id'] == user.id);
  return idx == -1 ? null : idx + 1;
});

/// Count of SRS cards the user has mastered (state >= 2).
final masteredWordCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.srsCards).join([
        drift.innerJoin(db.vocabulary,
            db.vocabulary.id.equalsExp(db.srsCards.vocabularyId)),
      ])
        ..where(db.srsCards.userId.equals(user.id) &
            db.srsCards.state.isBiggerOrEqualValue(2)))
      .watch()
      .map((rows) => rows.length);
});

/// Count of SRS cards currently being learned (state 1 = learning, 3 = relearning).
final learningWordCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.srsCards).join([
        drift.innerJoin(db.vocabulary,
            db.vocabulary.id.equalsExp(db.srsCards.vocabularyId)),
      ])
        ..where(db.srsCards.userId.equals(user.id) &
            (db.srsCards.state.equals(1) | db.srsCards.state.equals(3))))
      .watch()
      .map((rows) => rows.length);
});

/// Maps lessonId → accuracy percentage (0–100) from the user's progress rows.
final lessonAccuracyMapProvider = StreamProvider<Map<String, int>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value({});
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.userProgress)
        ..where((t) => t.userId.equals(user.id)))
      .watch()
      .map((rows) => {for (final r in rows) r.lessonId: r.accuracyPct});
});

// ── Continue learning: the user's current (next-incomplete) lesson ───────────

class CurrentLesson {
  final Track track;
  final Unit unit;
  final Lesson lesson;
  final int unitCompleted;
  final int unitTotal;
  const CurrentLesson({
    required this.track,
    required this.unit,
    required this.lesson,
    required this.unitCompleted,
    required this.unitTotal,
  });
}

/// The next incomplete lesson for the user, in the most recently active track.
/// "Most recently active" = the track containing the lesson from the user's
/// latest completed-lesson timestamp; falls back to the first track.
final currentLessonProvider = FutureProvider<CurrentLesson?>((ref) async {
  final tracks = await ref.watch(tracksProvider.future);
  if (tracks.isEmpty) return null;
  final completedIds = await ref.watch(completedLessonIdsProvider.future);

  String? recentTrackId;
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    final db = ref.watch(appDatabaseProvider);
    final recent = await (db.select(db.userProgress)
          ..where((t) => t.userId.equals(user.id))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.completedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (recent != null) {
      final lesson = await (db.select(db.lessons)
            ..where((t) => t.id.equals(recent.lessonId)))
          .getSingleOrNull();
      if (lesson != null) {
        final unit = await (db.select(db.units)
              ..where((t) => t.id.equals(lesson.unitId)))
            .getSingleOrNull();
        recentTrackId = unit?.trackId;
      }
    }
  }

  final orderedTracks = [...tracks];
  if (recentTrackId != null) {
    final idx = orderedTracks.indexWhere((t) => t.id == recentTrackId);
    if (idx > 0) {
      final track = orderedTracks.removeAt(idx);
      orderedTracks.insert(0, track);
    }
  }

  for (final track in orderedTracks) {
    final units = await ref.watch(unitsForTrackProvider(track.id).future);
    final sortedUnits = [...units]
      ..sort((a, b) {
        if (a.tierLevel != b.tierLevel) {
          return a.tierLevel.compareTo(b.tierLevel);
        }
        return a.sequenceOrder.compareTo(b.sequenceOrder);
      });
    for (final unit in sortedUnits) {
      final lessons = await ref.watch(lessonsForUnitProvider(unit.id).future);
      if (lessons.isEmpty) continue;
      final completedInUnit =
          lessons.where((l) => completedIds.contains(l.id)).length;
      final next = lessons.firstWhere(
        (l) => !completedIds.contains(l.id),
        orElse: () => lessons.first,
      );
      if (completedInUnit < lessons.length) {
        return CurrentLesson(
          track: track,
          unit: unit,
          lesson: next,
          unitCompleted: completedInUnit,
          unitTotal: lessons.length,
        );
      }
    }
  }
  return null;
});

final trackProgressProvider =
    FutureProvider.family<TrackProgress, String>((ref, trackId) async {
  final db = ref.watch(appDatabaseProvider);
  // Watch completedLessonIdsProvider so this rebuilds whenever progress changes
  final completedIds =
      ref.watch(completedLessonIdsProvider).valueOrNull ?? {};

  final units = await (db.select(db.units)
        ..where((t) => t.trackId.equals(trackId)))
      .get();

  final allLessonIds = <String>{};
  for (final u in units) {
    final lessons = await (db.select(db.lessons)
          ..where((t) => t.unitId.equals(u.id)))
        .get();
    allLessonIds.addAll(lessons.map((l) => l.id));
  }

  final total = allLessonIds.length;
  final completed =
      completedIds.where((id) => allLessonIds.contains(id)).length;

  return TrackProgress(total: total, completed: completed);
});
