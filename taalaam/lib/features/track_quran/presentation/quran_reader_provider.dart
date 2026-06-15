import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/local/database.dart';
import '../../../data/local/quran_local_source.dart';

const _kLastSurah = 'quran_last_surah';
const _kLastAyah = 'quran_last_ayah';
const _kBookmarks = 'quran_bookmarks';

class QuranNavState {
  final int surah;
  final int ayah;
  const QuranNavState({this.surah = 1, this.ayah = 1});
}

class QuranNavNotifier extends StateNotifier<QuranNavState> {
  QuranNavNotifier() : super(const QuranNavState());

  void restore(int surah, int ayah) {
    state = QuranNavState(surah: surah, ayah: ayah);
  }

  void goToSurah(int s) {
    state = QuranNavState(surah: s, ayah: 1);
    _persist(s, 1);
  }

  void _persist(int surah, int ayah) {
    SharedPreferences.getInstance().then((p) {
      p.setInt(_kLastSurah, surah);
      p.setInt(_kLastAyah, ayah);
    });
  }
}

final quranNavProvider =
    StateNotifierProvider.autoDispose<QuranNavNotifier, QuranNavState>(
        (_) => QuranNavNotifier());

final quranSurahsProvider = FutureProvider<List<QuranSurah>>(
    (ref) => ref.watch(quranLocalSourceProvider).getAllSurahs());

final quranAyahWordsProvider =
    FutureProvider.family<List<QuranWord>, ({int surah, int ayah})>(
        (ref, a) =>
            ref.watch(quranLocalSourceProvider).getAyahWords(a.surah, a.ayah));

final quranTafsirProvider =
    FutureProvider.family<QuranTafsirData?, ({int surah, int ayah})>(
        (ref, a) =>
            ref.watch(quranLocalSourceProvider).getTafsir(a.surah, a.ayah));

// Set by the Quran reader while the bottom-sheet UI is expanded so MainShell
// can hide the floating bottom nav and free up reading space.
final quranNavBarVisibleProvider = StateProvider<bool>((ref) => true);

// ── Bookmarks (persisted as "surah_ayah" strings) ───────────────────────────

class QuranBookmarksNotifier extends StateNotifier<Set<String>> {
  QuranBookmarksNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_kBookmarks) ?? const []).toSet();
  }

  Future<void> toggle(int surah, int ayah) async {
    final id = '${surah}_$ayah';
    final next = Set<String>.from(state);
    if (!next.remove(id)) next.add(id);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kBookmarks, next.toList());
  }
}

final quranBookmarksProvider =
    StateNotifierProvider<QuranBookmarksNotifier, Set<String>>(
        (_) => QuranBookmarksNotifier());
