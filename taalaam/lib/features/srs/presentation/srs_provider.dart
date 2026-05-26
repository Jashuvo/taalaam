import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database.dart';
import '../data/srs_local_source.dart';

final srsLocalSourceProvider = Provider<SrsLocalSource>((ref) {
  return SrsLocalSource(ref.watch(appDatabaseProvider));
});

final dueCardCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  return ref.read(srsLocalSourceProvider).countDueCards(userId);
});

final dueCardsProvider =
    FutureProvider.family<List<SrsCard>, String>((ref, userId) async {
  return ref.read(srsLocalSourceProvider).getDueCards(userId);
});

class ReviewSessionNotifier
    extends StateNotifier<AsyncValue<List<SrsCard>>> {
  final SrsLocalSource _src;
  final String _userId;
  List<SrsCard> _cards = [];
  int _index = 0;

  ReviewSessionNotifier(this._src, this._userId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      _cards = await _src.getDueCards(_userId);
      _index = 0;
      state = AsyncValue.data(List.unmodifiable(_cards));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  SrsCard? get currentCard =>
      _index < _cards.length ? _cards[_index] : null;

  int get remaining => (_cards.length - _index).clamp(0, _cards.length);

  Future<void> rate(int rating) async {
    final card = currentCard;
    if (card == null) return;
    await _src.reviewCard(card, rating);
    _index++;
    state = AsyncValue.data(List.unmodifiable(_cards));
  }
}

final reviewSessionProvider = StateNotifierProvider.autoDispose
    .family<ReviewSessionNotifier, AsyncValue<List<SrsCard>>, String>(
  (ref, userId) => ReviewSessionNotifier(
    ref.read(srsLocalSourceProvider),
    userId,
  ),
);
