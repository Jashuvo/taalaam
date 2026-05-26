import 'package:drift/drift.dart';
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
    await _db.into(_db.srsCards).insertOnConflictUpdate(SrsCardsCompanion(
          id: Value('${userId}_$vocabularyId'),
          userId: Value(userId),
          vocabularyId: Value(vocabularyId),
          dueDate: Value(DateTime.now()),
          state: const Value(0),
        ));
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
    await (_db.update(_db.srsCards)..where((t) => t.id.equals(card.id)))
        .write(SrsCardsCompanion(
      stability: Value(newStability),
      difficulty: Value(newDifficulty),
      scheduledDays: Value(interval),
      elapsedDays: Value(card.lastReview != null
          ? DateTime.now().difference(card.lastReview!).inDays
          : 0),
      reps: Value(card.reps + 1),
      lapses: Value(rating == 1 ? card.lapses + 1 : card.lapses),
      state: Value(newState),
      lastReview: Value(DateTime.now()),
      dueDate: Value(DateTime.now().add(Duration(days: interval))),
    ));
  }
}
