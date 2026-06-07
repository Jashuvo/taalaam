import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database.dart';
import '../../../shared/services/progression_service.dart';
import '../data/srs_local_source.dart';

final srsLocalSourceProvider = Provider<SrsLocalSource>((ref) {
  return SrsLocalSource(ref.watch(appDatabaseProvider));
});

// ── Badge counts (capped at daily limits) ────────────────────────────────────

/// New (never-seen) words — drives the মুখস্থ badge. Cap: kDailyNewLimit.
/// StreamProvider so the badge auto-refreshes when Drift data changes.
final newCardCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return ref.read(srsLocalSourceProvider).watchNewCards(userId);
});

/// Seen-but-interval-expired cards — drives the review badge. Cap: kDailyReviewLimit.
/// StreamProvider so the badge auto-refreshes when Drift data changes.
final reviewCardCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return ref.read(srsLocalSourceProvider).watchReviewCards(userId);
});

/// Legacy alias — callers that haven't been updated yet.
final dueCardCountProvider = reviewCardCountProvider;

// ── Review Session (seen cards whose interval expired) ────────────────────────

class ReviewSessionNotifier
    extends StateNotifier<AsyncValue<List<SrsCard>>> {
  final SrsLocalSource _src;
  final AppDatabase _db;
  final String _userId;
  List<SrsCard> _cards = [];
  int _index = 0;
  SrsReward? reward;

  ReviewSessionNotifier(this._src, this._db, this._userId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      _cards = await _src.getReviewCards(_userId);
      _index = 0;
      state = AsyncValue.data(List.unmodifiable(_cards));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  SrsCard? get currentCard =>
      _index < _cards.length ? _cards[_index] : null;

  int get remaining => (_cards.length - _index).clamp(0, _cards.length);
  int get total => _cards.length;

  Future<void> rate(int rating) async {
    final card = currentCard;
    if (card == null) return;
    await _src.reviewCard(card, rating);
    _index++;
    if (_index >= _cards.length && reward == null && _cards.isNotEmpty) {
      reward = await ProgressionService(_db).awardSrsSession(_userId);
    }
    state = AsyncValue.data(List.unmodifiable(_cards));
  }
}

final reviewSessionProvider = StateNotifierProvider.autoDispose
    .family<ReviewSessionNotifier, AsyncValue<List<SrsCard>>, String>(
  (ref, userId) => ReviewSessionNotifier(
    ref.read(srsLocalSourceProvider),
    ref.read(appDatabaseProvider),
    userId,
  ),
);

// ── Memorize Session (new, never-seen cards) ──────────────────────────────────

class MemorizeSessionNotifier
    extends StateNotifier<AsyncValue<List<SrsCard>>> {
  final SrsLocalSource _src;
  final AppDatabase _db;
  final String _userId;
  List<SrsCard> _cards = [];
  int _index = 0;
  SrsReward? reward;

  MemorizeSessionNotifier(this._src, this._db, this._userId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      _cards = await _src.getNewCards(_userId);
      _index = 0;
      state = AsyncValue.data(List.unmodifiable(_cards));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  SrsCard? get currentCard =>
      _index < _cards.length ? _cards[_index] : null;
  int get remaining => (_cards.length - _index).clamp(0, _cards.length);
  int get total => _cards.length;

  /// Vocabulary IDs of other cards in the session — used to build word-bank distractors.
  List<String> distractorVocabIds(String excludeVocabId) {
    final others = _cards
        .where((c) => c.vocabularyId != excludeVocabId)
        .toList()
      ..shuffle();
    return others.take(4).map((c) => c.vocabularyId).toList();
  }

  Future<void> rate(int rating) async {
    final card = currentCard;
    if (card == null) return;
    await _src.reviewCard(card, rating);
    _index++;
    if (_index >= _cards.length && reward == null && _cards.isNotEmpty) {
      reward = await ProgressionService(_db).awardSrsSession(_userId);
    }
    state = AsyncValue.data(List.unmodifiable(_cards));
  }
}

final memorizeSessionProvider = StateNotifierProvider.autoDispose
    .family<MemorizeSessionNotifier, AsyncValue<List<SrsCard>>, String>(
  (ref, userId) => MemorizeSessionNotifier(
    ref.read(srsLocalSourceProvider),
    ref.read(appDatabaseProvider),
    userId,
  ),
);
