import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/database.dart';

class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;

  SyncService(this._db, this._supabase);

  Future<void> syncTracks() async {
    final rows = await _supabase
        .from('tracks')
        .select()
        .order('sort_order');
    for (final r in (rows as List)) {
      await _db.into(_db.tracks).insertOnConflictUpdate(TracksCompanion(
            id: Value(r['id'] as String),
            slug: Value(r['slug'] as String),
            nameAr: Value(r['name_ar'] as String),
            nameBn: Value(r['name_bn'] as String),
            nameEn: Value(r['name_en'] as String),
            descriptionBn: Value(r['description_bn'] as String?),
            sortOrder: Value((r['sort_order'] as int?) ?? 0),
          ));
    }
  }

  // Sync published units for a track, deleting any stale local rows.
  Future<void> syncUnits(String trackId) async {
    final rows = await _supabase
        .from('units')
        .select()
        .eq('track_id', trackId)
        .eq('status', 'published')
        .order('sort_order');

    final remoteIds = (rows as List).map((r) => r['id'] as String).toSet();

    // Delete exercises + lessons belonging to units removed from Supabase
    final localUnits = await (_db.select(_db.units)
          ..where((t) => t.trackId.equals(trackId)))
        .get();
    for (final unit in localUnits) {
      if (!remoteIds.contains(unit.id)) {
        await _deleteUnitLocally(unit.id);
      }
    }

    // Upsert fresh rows
    for (final r in rows) {
      await _db.into(_db.units).insertOnConflictUpdate(UnitsCompanion(
            id: Value(r['id'] as String),
            trackId: Value(r['track_id'] as String),
            slug: Value(r['slug'] as String),
            titleAr: Value(r['title_ar'] as String?),
            titleBn: Value(r['title_bn'] as String),
            titleEn: Value(r['title_en'] as String?),
            descriptionBn: Value(r['description_bn'] as String?),
            sortOrder: Value(r['sort_order'] as int),
            tierLevel: Value((r['tier_level'] as int?) ?? 1),
            sequenceOrder: Value((r['sequence_order'] as int?) ?? r['sort_order'] as int),
            status: Value((r['status'] as String?) ?? 'draft'),
          ));
    }
  }

  // Sync lessons for a unit, deleting stale local rows.
  Future<void> syncLessons(String unitId) async {
    final rows = await _supabase
        .from('lessons')
        .select()
        .eq('unit_id', unitId)
        .order('sort_order');

    final remoteIds = (rows as List).map((r) => r['id'] as String).toSet();

    // Delete exercises belonging to lessons removed from Supabase
    final localLessons = await (_db.select(_db.lessons)
          ..where((t) => t.unitId.equals(unitId)))
        .get();
    for (final lesson in localLessons) {
      if (!remoteIds.contains(lesson.id)) {
        await _deleteLessonLocally(lesson.id);
      }
    }

    // Upsert fresh rows + their vocabulary
    for (final r in rows) {
      final lessonId = r['id'] as String;
      await _db.into(_db.lessons).insertOnConflictUpdate(LessonsCompanion(
            id: Value(lessonId),
            unitId: Value(r['unit_id'] as String),
            titleBn: Value(r['title_bn'] as String),
            titleAr: Value(r['title_ar'] as String?),
            sortOrder: Value(r['sort_order'] as int),
            xpReward: Value((r['xp_reward'] as int?) ?? 10),
            gemReward: Value((r['gem_reward'] as int?) ?? 0),
            isExam: Value((r['is_exam'] as bool?) ?? false),
            status: Value((r['status'] as String?) ?? 'draft'),
            level: Value((r['level'] as String?) ?? 'beginner'),
          ));
      await syncVocabulary(lessonId);
    }
  }

  Future<void> syncVocabulary(String lessonId) async {
    try {
      final rows = await _supabase
          .from('vocabulary')
          .select()
          .eq('lesson_id', lessonId);
      for (final r in (rows as List)) {
        await _db.into(_db.vocabulary).insertOnConflictUpdate(VocabularyCompanion(
              id: Value(r['id'] as String),
              arabic: Value(r['arabic'] as String),
              transliteration: Value(r['transliteration'] as String?),
              meaningBn: Value(r['meaning_bn'] as String),
              meaningEn: Value(r['meaning_en'] as String?),
              rootLetters: Value(r['root_letters'] as String?),
              wordType: Value(r['word_type'] as String?),
              gender: Value(r['gender'] as String?),
              audioUrl: Value(r['audio_url'] as String?),
              lessonId: Value(lessonId),
              frequencyRank: Value(r['frequency_rank'] as int?),
              grammarNoteBn: Value(r['grammar_note_bn'] as String?),
              contextSnippetAr: Value(r['context_snippet_ar'] as String?),
              contextSnippetBn: Value(r['context_snippet_bn'] as String?),
            ));
      }
    } catch (_) {
      // Vocabulary sync failure is non-fatal
    }
  }

  Future<void> _deleteUnitLocally(String unitId) async {
    final lessons = await (_db.select(_db.lessons)
          ..where((t) => t.unitId.equals(unitId)))
        .get();
    for (final l in lessons) {
      await _deleteLessonLocally(l.id);
    }
    await (_db.delete(_db.units)..where((t) => t.id.equals(unitId))).go();
  }

  Future<void> _deleteLessonLocally(String lessonId) async {
    await (_db.delete(_db.exercises)
          ..where((t) => t.lessonId.equals(lessonId)))
        .go();
    await (_db.delete(_db.vocabulary)
          ..where((t) => t.lessonId.equals(lessonId)))
        .go();
    await (_db.delete(_db.lessons)..where((t) => t.id.equals(lessonId))).go();
  }

  Future<void> flushPendingSync() async {
    final pending = await _db.select(_db.pendingSync).get();
    for (final item in pending) {
      try {
        await _db.delete(_db.pendingSync).delete(item);
      } catch (_) {}
    }
  }

  /// Pulls user-specific data from Supabase and writes to local Drift.
  /// Call once after login or on app start when authenticated.
  Future<void> restoreUserData(String userId) async {
    await Future.wait([
      _restoreUserProgress(userId),
      _restoreStreaks(userId),
      _restoreBookmarks(userId),
      _restoreSrsCards(userId),
    ]);
  }

  Future<void> _restoreUserProgress(String userId) async {
    try {
      final rows = await _supabase
          .from('user_progress')
          .select()
          .eq('user_id', userId);
      for (final r in (rows as List)) {
        await _db.into(_db.userProgress).insertOnConflictUpdate(
          UserProgressCompanion(
            id: Value(r['id'] as String),
            userId: Value(userId),
            lessonId: Value(r['lesson_id'] as String),
            completedAt: Value(r['completed_at'] != null
                ? DateTime.parse(r['completed_at'] as String)
                : DateTime.now()),
            xpEarned: Value((r['xp_earned'] as int?) ?? 0),
            accuracyPct: Value((r['accuracy_pct'] as int?) ?? 0),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _restoreStreaks(String userId) async {
    try {
      final row = await _supabase
          .from('streaks')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return;
      await _db.into(_db.streaks).insertOnConflictUpdate(
        StreaksCompanion(
          userId: Value(userId),
          currentStreak: Value((row['current_streak'] as int?) ?? 0),
          longestStreak: Value((row['longest_streak'] as int?) ?? 0),
          totalXp: Value((row['total_xp'] as int?) ?? 0),
          lastActivityDate: Value(row['last_activity_date'] != null
              ? DateTime.parse(row['last_activity_date'] as String)
              : null),
        ),
      );
    } catch (_) {}
  }

  Future<void> _restoreBookmarks(String userId) async {
    try {
      final rows = await _supabase
          .from('bookmarks')
          .select()
          .eq('user_id', userId);
      for (final r in (rows as List)) {
        await _db.into(_db.bookmarks).insertOnConflictUpdate(
          BookmarksCompanion(
            id: Value(r['id'] as String),
            userId: Value(userId),
            lessonId: Value(r['lesson_id'] as String),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _restoreSrsCards(String userId) async {
    try {
      final rows = await _supabase
          .from('srs_cards')
          .select()
          .eq('user_id', userId);
      for (final r in (rows as List)) {
        await _db.into(_db.srsCards).insertOnConflictUpdate(
          SrsCardsCompanion(
            id: Value(r['id'] as String),
            userId: Value(userId),
            vocabularyId: Value(r['vocabulary_id'] as String),
            dueDate: Value(r['due_date'] != null
                ? DateTime.parse(r['due_date'] as String)
                : DateTime.now()),
            stability: Value((r['stability'] as num?)?.toDouble() ?? 0.0),
            difficulty: Value((r['difficulty'] as num?)?.toDouble() ?? 5.0),
            elapsedDays: Value((r['elapsed_days'] as int?) ?? 0),
            scheduledDays: Value((r['scheduled_days'] as int?) ?? 0),
            reps: Value((r['reps'] as int?) ?? 0),
            lapses: Value((r['lapses'] as int?) ?? 0),
            state: Value((r['state'] as int?) ?? 0),
            lastReview: Value(r['last_review'] != null
                ? DateTime.parse(r['last_review'] as String)
                : null),
          ),
        );
      }
    } catch (_) {}
  }
}
