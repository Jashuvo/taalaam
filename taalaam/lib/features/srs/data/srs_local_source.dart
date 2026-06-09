import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/local/database.dart';
import 'fsrs_algorithm.dart';

/// Daily session caps — keeps badges from becoming a demoralising debt spiral.
const int kDailyNewLimit    = 10;
const int kDailyReviewLimit = 20;

class SrsLocalSource {
  final AppDatabase _db;
  SrsLocalSource(this._db);

  // ── Counts (capped so the badge never shows an overwhelming number) ───────────

  /// New (never reviewed) cards due today — capped at [kDailyNewLimit].
  Future<int> countNewCards(String userId) async {
    final q = _db.select(_db.srsCards).join([
      innerJoin(_db.vocabulary,
          _db.vocabulary.id.equalsExp(_db.srsCards.vocabularyId)),
    ])
      ..where(_db.srsCards.userId.equals(userId) &
          _db.srsCards.state.equals(0) &
          _db.srsCards.dueDate.isSmallerOrEqualValue(DateTime.now()));
    return (await q.get()).length.clamp(0, kDailyNewLimit);
  }

  /// Previously-seen cards whose interval expired — capped at [kDailyReviewLimit].
  Future<int> countReviewCards(String userId) async {
    final q = _db.select(_db.srsCards).join([
      innerJoin(_db.vocabulary,
          _db.vocabulary.id.equalsExp(_db.srsCards.vocabularyId)),
    ])
      ..where(_db.srsCards.userId.equals(userId) &
          _db.srsCards.state.isBiggerThanValue(0) &
          _db.srsCards.dueDate.isSmallerOrEqualValue(DateTime.now()));
    return (await q.get()).length.clamp(0, kDailyReviewLimit);
  }

  // ── Live-count streams (for auto-refreshing badges) ──────────────────────────

  /// Live count of new (never-reviewed) cards — emits on every Drift write.
  Stream<int> watchNewCards(String userId) {
    return (_db.select(_db.srsCards).join([
          innerJoin(_db.vocabulary,
              _db.vocabulary.id.equalsExp(_db.srsCards.vocabularyId)),
        ])
          ..where(_db.srsCards.userId.equals(userId) &
              _db.srsCards.state.equals(0) &
              _db.srsCards.dueDate.isSmallerOrEqualValue(DateTime.now())))
        .watch()
        .map((rows) => rows.length.clamp(0, kDailyNewLimit));
  }

  /// Live count of due review cards — emits on every Drift write.
  Stream<int> watchReviewCards(String userId) {
    return (_db.select(_db.srsCards).join([
          innerJoin(_db.vocabulary,
              _db.vocabulary.id.equalsExp(_db.srsCards.vocabularyId)),
        ])
          ..where(_db.srsCards.userId.equals(userId) &
              _db.srsCards.state.isBiggerThanValue(0) &
              _db.srsCards.dueDate.isSmallerOrEqualValue(DateTime.now())))
        .watch()
        .map((rows) => rows.length.clamp(0, kDailyReviewLimit));
  }

  // ── Card queues ───────────────────────────────────────────────────────────────

  /// New (never reviewed) words — for the Memorize screen.
  Future<List<SrsCard>> getNewCards(String userId,
      {int limit = kDailyNewLimit}) async {
    final q = _db.select(_db.srsCards).join([
      innerJoin(_db.vocabulary,
          _db.vocabulary.id.equalsExp(_db.srsCards.vocabularyId)),
    ])
      ..where(_db.srsCards.userId.equals(userId) &
          _db.srsCards.state.equals(0) &
          _db.srsCards.dueDate.isSmallerOrEqualValue(DateTime.now()))
      ..limit(limit);
    return (await q.get()).map((r) => r.readTable(_db.srsCards)).toList();
  }

  /// Previously-seen cards whose interval expired — for the Review screen.
  /// Ordered oldest-due-first so most overdue cards surface first.
  Future<List<SrsCard>> getReviewCards(String userId,
      {int limit = kDailyReviewLimit}) async {
    final q = _db.select(_db.srsCards).join([
      innerJoin(_db.vocabulary,
          _db.vocabulary.id.equalsExp(_db.srsCards.vocabularyId)),
    ])
      ..where(_db.srsCards.userId.equals(userId) &
          _db.srsCards.state.isBiggerThanValue(0) &
          _db.srsCards.dueDate.isSmallerOrEqualValue(DateTime.now()))
      ..orderBy([OrderingTerm.asc(_db.srsCards.dueDate)])
      ..limit(limit);
    return (await q.get()).map((r) => r.readTable(_db.srsCards)).toList();
  }

  // ── Legacy aliases ────────────────────────────────────────────────────────────
  Future<int> countDueCards(String userId) => countReviewCards(userId);
  Future<List<SrsCard>> getDueCards(String userId,
          {int limit = kDailyReviewLimit}) =>
      getReviewCards(userId, limit: limit);

  Future<void> createCard(String userId, String vocabularyId) async {
    final id = '${userId}_$vocabularyId';
    final now = DateTime.now();
    await _db.into(_db.srsCards).insertOnConflictUpdate(SrsCardsCompanion(
          id: Value(id),
          userId: Value(userId),
          vocabularyId: Value(vocabularyId),
          dueDate: Value(now),
          state: const Value(0),
        ));
    // Skip Supabase push for synthetic vocab and reader-added words
    // (no matching FK in remote vocabulary table for either prefix).
    if (vocabularyId.startsWith('syn_') || vocabularyId.startsWith('reader_')) return;
    Supabase.instance.client.from('srs_cards').upsert({
      'user_id': userId,
      'vocabulary_id': vocabularyId,
      'due_date': now.toIso8601String(),
      'state': 0,
    }, onConflict: 'user_id,vocabulary_id').then((_) {}).catchError((_) {});
  }

  Future<void> reviewCard(SrsCard card, int rating) async {
    late double newStability;
    late double newDifficulty;
    late int interval;

    if (card.reps == 0) {
      final result = FsrsAlgorithm.initCard(rating);
      newStability = result.stability;
      newDifficulty = result.difficulty;
      interval = result.interval;
    } else {
      final elapsed = card.lastReview != null
          ? DateTime.now().difference(card.lastReview!).inDays
          : 1;
      final result = FsrsAlgorithm.review(
        stability: card.stability,
        difficulty: card.difficulty,
        elapsedDays: elapsed,
        rating: rating,
        state: card.state,
      );
      newStability = result.stability;
      newDifficulty = result.difficulty;
      interval = result.interval;
    }

    final newState = rating >= 3 ? 2 : (card.reps == 0 ? 1 : 3);
    final now = DateTime.now();
    final newElapsed = card.lastReview != null
        ? now.difference(card.lastReview!).inDays
        : 0;
    final newDue = now.add(Duration(days: interval));
    final newReps = card.reps + 1;
    final newLapses = rating == 1 ? card.lapses + 1 : card.lapses;

    await (_db.update(_db.srsCards)..where((t) => t.id.equals(card.id)))
        .write(SrsCardsCompanion(
      stability: Value(newStability),
      difficulty: Value(newDifficulty),
      scheduledDays: Value(interval),
      elapsedDays: Value(newElapsed),
      reps: Value(newReps),
      lapses: Value(newLapses),
      state: Value(newState),
      lastReview: Value(now),
      dueDate: Value(newDue),
    ));

    // Skip Supabase push for synthetic vocab.
    if (card.vocabularyId.startsWith('syn_')) return;
    Supabase.instance.client.from('srs_cards').upsert({
      'user_id': card.userId,
      'vocabulary_id': card.vocabularyId,
      'due_date': newDue.toIso8601String(),
      'stability': newStability,
      'difficulty': newDifficulty,
      'elapsed_days': newElapsed,
      'scheduled_days': interval,
      'reps': newReps,
      'lapses': newLapses,
      'state': newState,
      'last_review': now.toIso8601String(),
    }, onConflict: 'user_id,vocabulary_id').then((_) {}).catchError((_) {});
  }
}
