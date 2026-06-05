import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/local/database.dart';
import '../../../shared/services/sync_service.dart';
import '../../auth/presentation/auth_provider.dart';

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
final dueCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  return (db.select(db.srsCards)
        ..where((t) =>
            t.userId.equals(user.id) &
            t.state.isBiggerThanValue(0) &
            t.dueDate.isSmallerOrEqualValue(now)))
      .watch()
      .map((cards) => cards.length.clamp(0, 20));
});

/// New cards (state == 0, never reviewed) — capped at 10 for মুখস্থ badge.
final newCardCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  return (db.select(db.srsCards)
        ..where((t) =>
            t.userId.equals(user.id) &
            t.state.equals(0) &
            t.dueDate.isSmallerOrEqualValue(now)))
      .watch()
      .map((cards) => cards.length.clamp(0, 10));
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
