import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/local/database.dart';
import 'fsrs_algorithm.dart';

class SrsLocalSource {
  final AppDatabase _db;
  SrsLocalSource(this._db);

  Future<int> countDueCards(String userId) async {
    final now = DateTime.now();
    final count = await (_db.select(_db.srsCards)
          ..where((t) =>
              t.userId.equals(userId) & t.dueDate.isSmallerOrEqualValue(now)))
        .get();
    return count.length;
  }

  Future<List<SrsCard>> getDueCards(String userId, {int limit = 50}) async {
    final now = DateTime.now();
    return (_db.select(_db.srsCards)
          ..where((t) =>
              t.userId.equals(userId) & t.dueDate.isSmallerOrEqualValue(now))
          ..limit(limit))
        .get();
  }

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
    // Skip Supabase push for synthetic vocab (no matching FK in remote vocabulary).
    // Supabase id column is uuid — omit it, use unique(user_id,vocabulary_id).
    if (vocabularyId.startsWith('syn_')) return;
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
