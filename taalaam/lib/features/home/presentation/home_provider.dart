import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/local/database.dart';
import '../../../shared/services/sync_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../srs/presentation/srs_provider.dart';

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
        ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)]))
      .watch();
});

final streakProvider = FutureProvider<Streak?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.streaks)
        ..where((t) => t.userId.equals(user.id)))
      .getSingleOrNull();
});

final dueCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(srsLocalSourceProvider).countDueCards(user.id);
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
  return (db.select(db.lessons)
        ..where((t) => t.unitId.equals(unitId))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)]))
      .watch();
});

final completedLessonIdsProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  final db = ref.watch(appDatabaseProvider);
  final rows = await (db.select(db.userProgress)
        ..where((t) => t.userId.equals(user.id)))
      .get();
  return rows.map((r) => r.lessonId).toSet();
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
      await (_db.delete(_db.bookmarks)
            ..where((t) => t.id.equals(id)))
          .go();
    } else {
      await _db.into(_db.bookmarks).insertOnConflictUpdate(
            BookmarksCompanion.insert(
              id: id,
              userId: _userId,
              lessonId: lessonId,
            ),
          );
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
