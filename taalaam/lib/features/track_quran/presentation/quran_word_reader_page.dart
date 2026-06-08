import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import '../../../data/local/quran_local_source.dart';
import 'quran_reader_provider.dart';

class QuranWordReaderPage extends ConsumerStatefulWidget {
  const QuranWordReaderPage({super.key});

  @override
  ConsumerState<QuranWordReaderPage> createState() =>
      _QuranWordReaderPageState();
}

class _QuranWordReaderPageState extends ConsumerState<QuranWordReaderPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Auto-sync if local DB is empty
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final src = ref.read(quranLocalSourceProvider);
      final count = await src.wordCount();
      if (count == 0) {
        await src.syncSurahsFromSupabase();
        await src.syncWordsFromSupabase();
        ref.invalidate(quranSurahsProvider);
        final nav = ref.read(quranNavProvider);
        ref.invalidate(quranAyahWordsProvider(
            (surah: nav.surah, ayah: nav.ayah)));
      }
    });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(quranNavProvider);
    final surahsAsync = ref.watch(quranSurahsProvider);
    final theme = Theme.of(context);

    final currentSurah = surahsAsync.valueOrNull
        ?.where((s) => s.number == nav.surah)
        .firstOrNull;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: currentSurah == null
            ? const Text('শব্দে শব্দে কুরআন')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      currentSurah.nameAr,
                      style: const TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 18,
                        color: AppColors.gold,
                        height: 1.4,
                      ),
                    ),
                  ),
                  Text(
                    '${currentSurah.nameBn} • আয়াত ${nav.ayah}/${currentSurah.ayahCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.menu_book_rounded,
              color: nav.showTafsir ? AppColors.gold : null,
            ),
            tooltip: nav.showTafsir ? 'শব্দ দেখুন' : 'তাফসীর দেখুন',
            onPressed: () =>
                ref.read(quranNavProvider.notifier).toggleTafsir(),
          ),
        ],
      ),
      body: Column(
        children: [
          _SurahSelector(surahsAsync: surahsAsync),
          const Divider(height: 1),
          Expanded(
            child: _AyahBody(
              shimmerCtrl: _shimmerCtrl,
              nav: nav,
            ),
          ),
          _AyahNavBar(
            nav: nav,
            ayahCount: currentSurah?.ayahCount ?? 0,
          ),
          _AudioBar(nav: nav),
        ],
      ),
    );
  }
}

// ── Surah selector ────────────────────────────────────────────────────────────

class _SurahSelector extends ConsumerWidget {
  final AsyncValue<List<QuranSurah>> surahsAsync;
  const _SurahSelector({required this.surahsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(quranNavProvider);
    return SizedBox(
      height: 44,
      child: surahsAsync.when(
        data: (surahs) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          itemCount: surahs.length,
          itemBuilder: (_, i) {
            final s = surahs[i];
            final selected = s.number == nav.surah;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(
                  '${s.number}. ${s.nameBn}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                    color: selected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                selected: selected,
                selectedColor: AppColors.forestGreen,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainer,
                onSelected: (_) =>
                    ref.read(quranNavProvider.notifier).goToSurah(s.number),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            );
          },
        ),
        loading: () => const Center(child: LinearProgressIndicator()),
        error: (_, __) => const Center(child: Text('সূরা লোড হয়নি')),
      ),
    );
  }
}

// ── Ayah body ─────────────────────────────────────────────────────────────────

class _AyahBody extends ConsumerWidget {
  final AnimationController shimmerCtrl;
  final QuranNavState nav;
  const _AyahBody({required this.shimmerCtrl, required this.nav});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(
        quranAyahWordsProvider((surah: nav.surah, ayah: nav.ayah)));

    if (nav.showTafsir) {
      return _TafsirView(nav: nav);
    }

    return wordsAsync.when(
      data: (words) => _WordView(words: words, nav: nav),
      loading: () => _ShimmerWordView(ctrl: shimmerCtrl),
      error: (e, _) => Center(
        child: Text(
          'শব্দ লোড হয়নি: $e',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

// ── Word view ─────────────────────────────────────────────────────────────────

class _WordView extends ConsumerWidget {
  final List<QuranWord> words;
  final QuranNavState nav;
  const _WordView({required this.words, required this.nav});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedWord = words
        .where((w) => w.position == nav.selectedWord)
        .firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: words.map((word) {
                final isSelected = word.position == nav.selectedWord;
                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      ref.read(quranNavProvider.notifier).clearWord();
                    } else {
                      ref
                          .read(quranNavProvider.notifier)
                          .selectWord(word.position);
                    }
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold.withValues(alpha: 0.12)
                            : theme.colorScheme.surfaceContainer,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.gold
                              : theme.colorScheme.outlineVariant,
                          width: isSelected ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        word.arabic,
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 22,
                          height: 1.8,
                          color: isSelected
                              ? AppColors.gold
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (selectedWord != null) ...[
            const SizedBox(height: 20),
            _WordDetailCard(word: selectedWord),
          ],
        ],
      ),
    );
  }
}

// ── Word detail card ──────────────────────────────────────────────────────────

class _WordDetailCard extends StatelessWidget {
  final QuranWord word;
  const _WordDetailCard({required this.word});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgBorder,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              word.arabic,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 36,
                color: AppColors.gold,
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (word.meaningBn != null)
            Text(
              word.meaningBn!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 17,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            )
          else
            Text(
              'শব্দের অর্থ পাওয়া যায়নি',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'শব্দ ${word.position} • আয়াত ${word.ayah} • সূরা ${word.surah}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tafsir view ───────────────────────────────────────────────────────────────

class _TafsirView extends ConsumerWidget {
  final QuranNavState nav;
  const _TafsirView({required this.nav});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tafsirAsync = ref.watch(
        quranTafsirProvider((surah: nav.surah, ayah: nav.ayah)));
    final theme = Theme.of(context);

    // Also sync tafsir for this surah if first time viewing
    ref.listen(
        quranTafsirProvider((surah: nav.surah, ayah: nav.ayah)),
        (_, next) {});

    return tafsirAsync.when(
      data: (tafsir) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'تفسير أبو بكر زكريا',
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 16,
                  color: AppColors.gold,
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              'তাফসীর — আবু বকর যাকারিয়া',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 24),
            if (tafsir == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'এই আয়াতের তাফসীর ডেটা নেই',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(quranLocalSourceProvider)
                              .syncTafsirFromSupabase(nav.surah);
                          ref.invalidate(quranTafsirProvider(
                              (surah: nav.surah, ayah: nav.ayah)));
                        },
                        child: const Text('সূরার তাফসীর ডাউনলোড করুন'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Text(
                tafsir.tafsirText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  height: 1.8,
                ),
              ),
          ],
        ),
      ),
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text('তাফসীর লোড হয়নি'),
      ),
    );
  }
}

// ── Shimmer skeleton ──────────────────────────────────────────────────────────

class _ShimmerWordView extends StatelessWidget {
  final AnimationController ctrl;
  const _ShimmerWordView({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) {
          final shimmer = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              theme.colorScheme.surfaceContainer,
              theme.colorScheme.surfaceContainerHighest,
              theme.colorScheme.surfaceContainer,
            ],
            stops: [
              (ctrl.value - 0.3).clamp(0.0, 1.0),
              ctrl.value.clamp(0.0, 1.0),
              (ctrl.value + 0.3).clamp(0.0, 1.0),
            ],
          );
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              7,
              (i) => ShaderMask(
                shaderCallback: (bounds) =>
                    shimmer.createShader(bounds),
                child: Container(
                  width: 60.0 + (i % 3) * 20,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Ayah nav bar ──────────────────────────────────────────────────────────────

class _AyahNavBar extends ConsumerWidget {
  final QuranNavState nav;
  final int ayahCount;
  const _AyahNavBar({required this.nav, required this.ayahCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(quranNavProvider.notifier);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'আগের আয়াত',
            onPressed:
                nav.ayah > 1 ? () => notifier.previousAyah() : null,
          ),
          Expanded(
            child: Text(
              ayahCount > 0
                  ? 'আয়াত ${nav.ayah} / $ayahCount'
                  : 'আয়াত ${nav.ayah}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'পরের আয়াত',
            onPressed: nav.ayah < ayahCount
                ? () => notifier.nextAyah(ayahCount)
                : null,
          ),
        ],
      ),
    );
  }
}

// ── Audio bar ─────────────────────────────────────────────────────────────────

class _AudioBar extends ConsumerWidget {
  final QuranNavState nav;
  const _AudioBar({required this.nav});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPlaying = ref.watch(quranIsPlayingProvider);
    final player = ref.watch(quranAudioPlayerProvider);

    // Stop audio when ayah changes
    ref.listen(quranNavProvider, (prev, next) {
      if (prev?.ayah != next.ayah || prev?.surah != next.surah) {
        player.stop();
        ref.read(quranIsPlayingProvider.notifier).state = false;
      }
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  'مشاري راشد العفاسي',
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.gold,
                  ),
                ),
              ),
              Text(
                'মিশারী আল-আফাসী',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outlined,
              size: 36,
              color: AppColors.gold,
            ),
            onPressed: () async {
              if (isPlaying) {
                await player.stop();
                ref.read(quranIsPlayingProvider.notifier).state = false;
              } else {
                try {
                  final url = afasyAudioUrl(nav.surah, nav.ayah);
                  await player.setUrl(url);
                  ref.read(quranIsPlayingProvider.notifier).state = true;
                  await player.play();
                  // Reset when done
                  player.playerStateStream.listen((state) {
                    if (state.processingState == ProcessingState.completed) {
                      ref.read(quranIsPlayingProvider.notifier).state = false;
                    }
                  });
                } catch (_) {
                  ref.read(quranIsPlayingProvider.notifier).state = false;
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
