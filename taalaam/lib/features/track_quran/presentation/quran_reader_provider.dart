import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../data/local/database.dart';
import '../../../data/local/quran_local_source.dart';

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

  void goToSurah(int s) => state = QuranNavState(surah: s, ayah: 1);
  void goToAyah(int a) => state = state.copyWith(ayah: a, clearWord: true);
  void selectWord(int p) => state = state.copyWith(selectedWord: p);
  void clearWord() => state = state.copyWith(clearWord: true);
  void toggleTafsir() =>
      state = state.copyWith(showTafsir: !state.showTafsir);
  void previousAyah() {
    if (state.ayah > 1) {
      state = state.copyWith(ayah: state.ayah - 1, clearWord: true);
    }
  }

  void nextAyah(int ayahCount) {
    if (state.ayah < ayahCount) {
      state = state.copyWith(ayah: state.ayah + 1, clearWord: true);
    }
  }
}

final quranNavProvider =
    StateNotifierProvider<QuranNavNotifier, QuranNavState>(
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

final quranAudioPlayerProvider = Provider<AudioPlayer>((ref) {
  final p = AudioPlayer();
  ref.onDispose(p.dispose);
  return p;
});

final quranIsPlayingProvider = StateProvider<bool>((_) => false);

String afasyAudioUrl(int surah, int ayah) {
  final s = surah.toString().padLeft(3, '0');
  final a = ayah.toString().padLeft(3, '0');
  return 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$s$a.mp3';
}
