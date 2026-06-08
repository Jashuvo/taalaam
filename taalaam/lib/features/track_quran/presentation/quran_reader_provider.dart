import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/local/database.dart';
import '../../../data/local/quran_local_source.dart';

const _kLastSurah = 'quran_last_surah';
const _kLastAyah = 'quran_last_ayah';

class QuranNavState {
  final int surah;
  final int ayah;
  final int? selectedWord;
  final bool showTafsir;
  const QuranNavState({
    this.surah = 1,
    this.ayah = 1,
    this.selectedWord,
    this.showTafsir = false,
  });
  QuranNavState copyWith({
    int? surah,
    int? ayah,
    int? selectedWord,
    bool? showTafsir,
    bool clearWord = false,
  }) =>
      QuranNavState(
        surah: surah ?? this.surah,
        ayah: ayah ?? this.ayah,
        selectedWord: clearWord ? null : (selectedWord ?? this.selectedWord),
        showTafsir: showTafsir ?? this.showTafsir,
      );
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

  void selectWord(int p) => state = state.copyWith(selectedWord: p);
  void clearWord() => state = state.copyWith(clearWord: true);
  void toggleTafsir() =>
      state = state.copyWith(showTafsir: !state.showTafsir);

  void previousAyah() {
    if (state.ayah > 1) {
      final next = state.copyWith(ayah: state.ayah - 1, clearWord: true);
      state = next;
      _persist(next.surah, next.ayah);
    }
  }

  void nextAyah(int ayahCount) {
    if (state.ayah < ayahCount) {
      final next = state.copyWith(ayah: state.ayah + 1, clearWord: true);
      state = next;
      _persist(next.surah, next.ayah);
    }
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
