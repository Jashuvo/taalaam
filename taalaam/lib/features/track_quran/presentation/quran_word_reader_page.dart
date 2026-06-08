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
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, ) {
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
            child: _AyahBody(shimmerCtrl: _shimmerCtrl, nav: nav),
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
    final theme = Theme.of(context);

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
              child: GestureDetector(
                onTap: () =>
                    ref.read(quranNavProvider.notifier).goToSurah(s.number),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.forestGreen
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${s.number}. ${s.nameBn}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => Center(
          child: Text(
            'সূরা লোড হচ্ছে...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
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
    if (nav.showTafsir) return _TafsirView(nav: nav);

    final wordsAsync = ref.watch(
        quranAyahWordsProvider((surah: nav.surah, ayah: nav.ayah)));

    return wordsAsync.when(
      data: (words) => words.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _WordView(words: words, nav: nav),
      loading: () => _ShimmerWordView(ctrl: shimmerCtrl),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40),
            const SizedBox(height: 12),
            Text('শব্দ লোড হয়নি', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(quranAyahWordsProvider(
                  (surah: nav.surah, ayah: nav.ayah))),
              child: const Text('আবার চেষ্টা করুন'),
            ),
          ],
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
    final selectedWord =
        words.where((w) => w.position == nav.selectedWord).firstOrNull;

    // Full ayah text joined RTL
    final fullAyah = words.map((w) => w.arabic).join(' ');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Full ayah display ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradientQuranic,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.lgBorder,
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                fullAyah,
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 24,
                  color: Colors.white,
                  height: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tap instruction ────────────────────────────────────────
          Text(
            'শব্দে ট্যাপ করুন',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // ── Word cards (Arabic + Bengali inline) ───────────────────
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              alignment: WrapAlignment.center,
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainer,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.gold
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          word.arabic,
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 22,
                            height: 1.6,
                            color: isSelected
                                ? AppColors.gold
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (word.meaningBn != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            word.meaningBn!,
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.3,
                              color: isSelected
                                  ? AppColors.gold.withValues(alpha: 0.85)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.ltr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Selected word detail ───────────────────────────────────
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
        border:
            Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              word.arabic,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 40,
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
                fontSize: 18,
                height: 1.5,
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
          const SizedBox(height: 6),
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
                  fontSize: 18,
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
                      Icon(Icons.menu_book_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        'এই সূরার তাফসীর এখনও ডাউনলোড হয়নি',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('তাফসীর ডাউনলোড করুন'),
                        onPressed: () async {
                          await ref
                              .read(quranLocalSourceProvider)
                              .syncTafsirFromSupabase(nav.surah);
                          ref.invalidate(quranTafsirProvider(
                              (surah: nav.surah, ayah: nav.ayah)));
                        },
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
                  height: 1.9,
                ),
              ),
          ],
        ),
      ),
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const Center(child: Text('তাফসীর লোড হয়নি')),
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
      child: Column(
        children: [
          // Full ayah placeholder
          AnimatedBuilder(
            animation: ctrl,
            builder: (_, __) => _shimmerBox(
              theme,
              ctrl.value,
              width: double.infinity,
              height: 80,
              radius: 12,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: ctrl,
            builder: (_, __) => Wrap(
              spacing: 8,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(
                8,
                (i) => _shimmerBox(
                  theme,
                  ctrl.value,
                  width: 60.0 + (i % 3) * 18,
                  height: 58,
                  radius: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(ThemeData theme, double v,
      {required double width, required double height, double radius = 8}) {
    final shimmer = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        theme.colorScheme.surfaceContainer,
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.surfaceContainer,
      ],
      stops: [
        (v - 0.3).clamp(0.0, 1.0),
        v.clamp(0.0, 1.0),
        (v + 0.3).clamp(0.0, 1.0),
      ],
    );
    return ShaderMask(
      shaderCallback: (bounds) => shimmer.createShader(bounds),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
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
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'আগের আয়াত',
            onPressed: nav.ayah > 1 ? () => notifier.previousAyah() : null,
          ),
          Expanded(
            child: Text(
              ayahCount > 0
                  ? 'আয়াত ${nav.ayah} / $ayahCount'
                  : 'আয়াত ${nav.ayah}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            iconSize: 28,
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
            top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Text(
            'তিলাওয়াত',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              isPlaying
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outlined,
              size: 38,
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
                  player.playerStateStream.listen((s) {
                    if (s.processingState == ProcessingState.completed) {
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
