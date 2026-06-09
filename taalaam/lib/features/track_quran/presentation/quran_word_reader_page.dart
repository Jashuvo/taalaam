import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import '../../../data/local/quran_local_source.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../../../features/srs/data/srs_local_source.dart';
import '../../../shared/services/progression_service.dart';
import '../data/quran_coverage_service.dart';
import 'quran_reader_provider.dart';

// Uthmani script has pause/sajdah marks (U+06D6–U+06DC, U+06DF–U+06E4, U+06E7+)
// that the alquran.cloud API emits as standalone space-separated tokens.
// These are not real words — filter them from word chips.
bool _isRealWord(String s) =>
    s.runes.any((r) => r >= 0x0600 && r <= 0x06D5);

// GTAF sometimes stores ayah-number markers like "(২)" as Bengali meanings.
bool _isAyahMarker(String? s) {
  if (s == null || s.isEmpty) return false;
  return RegExp(r'^\s*\([০-৯\d\s]+\)\s*$').hasMatch(s);
}

// Stable 31-bit hash of a string — used to derive reader_ vocab IDs.
int _stableHash(String s) {
  var h = 0;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7FFFFFFF;
  }
  return h;
}

String _readerVocabId(String normalizedArabic) =>
    'reader_${_stableHash(normalizedArabic)}';

String _todayKey() {
  final n = DateTime.now();
  return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
}

class QuranWordReaderPage extends ConsumerStatefulWidget {
  final bool showBackButton;
  const QuranWordReaderPage({super.key, this.showBackButton = true});

  @override
  ConsumerState<QuranWordReaderPage> createState() =>
      _QuranWordReaderPageState();
}

class _QuranWordReaderPageState extends ConsumerState<QuranWordReaderPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  bool _highlightEnabled = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _userId = ref.read(currentUserProvider)?.id;

    // Restore last reading position and highlight preference.
    SharedPreferences.getInstance().then((prefs) {
      final surah = prefs.getInt('quran_last_surah') ?? 1;
      final ayah  = prefs.getInt('quran_last_ayah')  ?? 1;
      if (mounted && (surah != 1 || ayah != 1)) {
        ref.read(quranNavProvider.notifier).restore(surah, ayah);
      }
      final uid = _userId;
      if (uid != null && mounted) {
        final on = prefs.getBool('reader_highlight_$uid') ?? true;
        setState(() => _highlightEnabled = on);
      }
    });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleHighlight() async {
    final next = !_highlightEnabled;
    setState(() => _highlightEnabled = next);
    final uid = _userId;
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('reader_highlight_$uid', next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav        = ref.watch(quranNavProvider);
    final surahsAsync = ref.watch(quranSurahsProvider);
    final theme      = Theme.of(context);

    final currentSurah = surahsAsync.valueOrNull
        ?.where((s) => s.number == nav.surah)
        .firstOrNull;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/home'),
              )
            : null,
        title: currentSurah == null
            ? const Text('শব্দে শব্দে কুরআন')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      currentSurah.nameAr,
                      style: const TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 17,
                        color: AppColors.gold,
                        height: 1.5,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        currentSurah.nameBn,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: currentSurah.revelation == 'meccan'
                              ? AppColors.gold.withValues(alpha: 0.15)
                              : Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          currentSurah.revelation == 'meccan'
                              ? 'মাক্কী'
                              : 'মাদানী',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: currentSurah.revelation == 'meccan'
                                ? AppColors.gold
                                : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          // Highlight toggle
          IconButton(
            icon: Icon(
              _highlightEnabled
                  ? Icons.remove_red_eye_rounded
                  : Icons.visibility_off_rounded,
              color: _highlightEnabled ? AppColors.brightGreen : null,
            ),
            tooltip: _highlightEnabled ? 'রঙ বন্ধ করুন' : 'রঙ চালু করুন',
            onPressed: _toggleHighlight,
          ),
          IconButton(
            icon: Icon(
              Icons.menu_book_rounded,
              color: nav.showTafsir ? AppColors.gold : null,
            ),
            tooltip: nav.showTafsir ? 'শব্দ দেখুন' : 'তাফসীর দেখুন',
            onPressed: () =>
                ref.read(quranNavProvider.notifier).toggleTafsir(),
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            tooltip: 'সূরা তালিকা',
            onPressed: () =>
                _showSurahPicker(context, surahsAsync.valueOrNull ?? []),
          ),
        ],
      ),
      body: Column(
        children: [
          _SurahSelector(surahsAsync: surahsAsync),
          Expanded(
            child: _AyahBody(
              shimmerCtrl: _shimmerCtrl,
              nav: nav,
              userId: _userId,
              highlightEnabled: _highlightEnabled,
            ),
          ),
          _AyahNavBar(
            nav: nav,
            ayahCount: currentSurah?.ayahCount ?? 0,
          ),
        ],
      ),
    );
  }

  void _showSurahPicker(BuildContext context, List<QuranSurah> surahs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SurahPickerSheet(
        surahs: surahs,
        currentSurah: ref.read(quranNavProvider).surah,
        onSelect: (n) {
          ref.read(quranNavProvider.notifier).goToSurah(n);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Surah picker bottom sheet ─────────────────────────────────────────────────

class _SurahPickerSheet extends StatefulWidget {
  final List<QuranSurah> surahs;
  final int currentSurah;
  final void Function(int) onSelect;
  const _SurahPickerSheet({
    required this.surahs,
    required this.currentSurah,
    required this.onSelect,
  });

  @override
  State<_SurahPickerSheet> createState() => _SurahPickerSheetState();
}

class _SurahPickerSheetState extends State<_SurahPickerSheet> {
  late List<QuranSurah> _filtered;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.surahs;
    _search.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.surahs
          : widget.surahs.where((s) {
              return s.nameBn.contains(q) ||
                  s.nameEn.toLowerCase().contains(q) ||
                  s.number.toString() == q;
            }).toList();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Text('সূরা তালিকা',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${widget.surahs.length} টি সূরা',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'সূরা খুঁজুন...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainer,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final s        = _filtered[i];
                final isSelected = s.number == widget.currentSurah;
                return InkWell(
                  onTap: () => widget.onSelect(s.number),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.forestGreen.withValues(alpha: 0.08)
                          : null,
                      border: Border(
                          bottom: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.4))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.forestGreen
                                : theme.colorScheme.surfaceContainer,
                          ),
                          alignment: Alignment.center,
                          child: Text('${s.number}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.nameBn,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.forestGreen
                                        : theme.colorScheme.onSurface,
                                  )),
                              Text('${s.nameEn} • ${s.ayahCount} আয়াত',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  )),
                            ],
                          ),
                        ),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(s.nameAr,
                              style: TextStyle(
                                fontFamily: 'NotoNaskhArabic',
                                fontSize: 18,
                                height: 1.8,
                                color: isSelected
                                    ? AppColors.gold
                                    : theme.colorScheme.onSurfaceVariant,
                              )),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Surah horizontal selector ─────────────────────────────────────────────────

class _SurahSelector extends ConsumerWidget {
  final AsyncValue<List<QuranSurah>> surahsAsync;
  const _SurahSelector({required this.surahsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav   = ref.watch(quranNavProvider);
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: surahsAsync.when(
        data: (surahs) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          itemCount: surahs.length,
          itemBuilder: (_, i) {
            final s        = surahs[i];
            final selected = s.number == nav.surah;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () =>
                    ref.read(quranNavProvider.notifier).goToSurah(s.number),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.forestGreen
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: selected
                        ? null
                        : Border.all(
                            color: theme.colorScheme.outlineVariant,
                            width: 0.5),
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
          child: Text('সূরা লোড হচ্ছে...',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

// ── Ayah body ─────────────────────────────────────────────────────────────────

class _AyahBody extends ConsumerWidget {
  final AnimationController shimmerCtrl;
  final QuranNavState nav;
  final String? userId;
  final bool highlightEnabled;
  const _AyahBody({
    required this.shimmerCtrl,
    required this.nav,
    required this.userId,
    required this.highlightEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (nav.showTafsir) return _TafsirView(nav: nav);

    final wordsAsync = ref.watch(
        quranAyahWordsProvider((surah: nav.surah, ayah: nav.ayah)));

    return wordsAsync.when(
      data: (words) => words.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _WordView(
              key: ValueKey('${nav.surah}_${nav.ayah}'),
              words: words,
              nav: nav,
              userId: userId,
              highlightEnabled: highlightEnabled,
            ),
      loading: () => _ShimmerWordView(ctrl: shimmerCtrl),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('শব্দ লোড হয়নি'),
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

class _WordView extends ConsumerStatefulWidget {
  final List<QuranWord> words;
  final QuranNavState nav;
  final String? userId;
  final bool highlightEnabled;
  const _WordView({
    required this.words,
    required this.nav,
    required this.userId,
    required this.highlightEnabled,
    super.key,
  });

  @override
  ConsumerState<_WordView> createState() => _WordViewState();
}

class _WordViewState extends ConsumerState<_WordView> {
  bool _tafsirExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = widget.userId;

    // Fetch known forms only when userId is available and highlight is on.
    Set<String> mastered = {};
    Set<String> learning = {};
    if (userId != null && widget.highlightEnabled) {
      final known = ref.watch(knownWordFormsProvider(userId)).valueOrNull;
      mastered = known?.mastered ?? {};
      learning = known?.learning ?? {};
    }

    final displayWords =
        widget.words.where((w) => _isRealWord(w.arabic)).toList();
    final selectedWord = displayWords
        .where((w) => w.position == widget.nav.selectedWord)
        .firstOrNull;
    final fullAyah = displayWords.map((w) => w.arabic).join(' ');
    final fullMeaning = displayWords
        .map((w) => w.meaningBn ?? '')
        .where((s) => s.isNotEmpty && !_isAyahMarker(s))
        .join(' ');

    final wordCount       = displayWords.length;
    final arabicFontSize  = wordCount > 30 ? 14.0
        : wordCount > 20 ? 16.0
        : wordCount > 12 ? 18.0
        : wordCount > 6  ? 20.0
        : 24.0;
    final arabicLineHeight =
        wordCount > 20 ? 1.5 : wordCount > 10 ? 1.7 : 2.1;

    // Mastered words that appear in this ayah (for inline tafsir header, max 4).
    final masteredInAyah = displayWords
        .where((w) => mastered.contains(normalizeArabic(w.arabic)))
        .take(4)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Full ayah header ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradientQuranic,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.lgBorder,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    fullAyah,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: arabicFontSize,
                      color: Colors.white,
                      height: arabicLineHeight,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white38, width: 1),
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.nav.ayah}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (fullMeaning.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fullMeaning,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                            height: 1.35,
                          ),
                          textDirection: TextDirection.ltr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Scrollable chips + detail ────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Legend row (only when highlight on AND userId present)
                if (widget.highlightEnabled && userId != null)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendChip(
                            color: AppColors.brightGreen, label: 'আয়ত্ত'),
                        SizedBox(width: 8),
                        _LegendChip(color: AppColors.gold, label: 'শিখছি'),
                      ],
                    ),
                  ),

                Text(
                  'শব্দে ট্যাপ করুন · দীর্ঘ চাপে SRS-এ যোগ করুন',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Word chips
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: displayWords.map((word) {
                      final isSelected =
                          word.position == widget.nav.selectedWord;
                      final norm       = normalizeArabic(word.arabic);
                      final isMastered =
                          widget.highlightEnabled && mastered.contains(norm);
                      final isLearning =
                          widget.highlightEnabled && learning.contains(norm);

                      return GestureDetector(
                        onTap: () {
                          if (isSelected) {
                            ref
                                .read(quranNavProvider.notifier)
                                .clearWord();
                          } else {
                            ref
                                .read(quranNavProvider.notifier)
                                .selectWord(word.position);
                          }
                        },
                        onLongPress: userId != null
                            ? () => _showAddToSrs(context, word, userId)
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.gold.withValues(alpha: 0.12)
                                : isMastered
                                    ? AppColors.brightGreen
                                        .withValues(alpha: 0.10)
                                    : theme.colorScheme.surfaceContainer,
                            border: Border(
                              left: BorderSide.none,
                              right: BorderSide.none,
                              top: isLearning
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: isSelected
                                          ? AppColors.gold
                                          : isMastered
                                              ? AppColors.brightGreen
                                              : theme.colorScheme.outlineVariant,
                                      width: isSelected || isMastered ? 1.5 : 0.8,
                                    ),
                              bottom: isLearning
                                  ? const BorderSide(
                                      color: AppColors.gold, width: 2)
                                  : BorderSide(
                                      color: isSelected
                                          ? AppColors.gold
                                          : isMastered
                                              ? AppColors.brightGreen
                                              : theme.colorScheme.outlineVariant,
                                      width: isSelected || isMastered ? 1.5 : 0.8,
                                    ),
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
                                  fontSize: 24,
                                  height: 1.7,
                                  color: isSelected
                                      ? AppColors.gold
                                      : isMastered
                                          ? AppColors.brightGreen
                                          : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _isAyahMarker(word.meaningBn)
                                    ? '—'
                                    : (word.meaningBn ?? '—'),
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.3,
                                  color: isSelected
                                      ? AppColors.gold.withValues(alpha: 0.85)
                                      : isMastered
                                          ? AppColors.brightGreen
                                              .withValues(alpha: 0.85)
                                          : theme.colorScheme.onSurfaceVariant,
                                ),
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Selected word detail
                if (selectedWord != null) ...[
                  const SizedBox(height: 20),
                  _WordDetailCard(word: selectedWord),
                ],

                // Inline tafsir toggle
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _tafsirExpanded = !_tafsirExpanded),
                    icon: Icon(
                      _tafsirExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.menu_book_outlined,
                      size: 16,
                      color: _tafsirExpanded
                          ? AppColors.gold
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    label: Text(
                      _tafsirExpanded ? 'তাফসীর বন্ধ করুন' : 'তাফসীর দেখুন',
                      style: TextStyle(
                        fontSize: 12,
                        color: _tafsirExpanded
                            ? AppColors.gold
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

                if (_tafsirExpanded) ...[
                  const SizedBox(height: 4),
                  _InlineTafsir(
                    surah: widget.nav.surah,
                    ayah: widget.nav.ayah,
                    masteredInAyah: masteredInAyah,
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddToSrs(BuildContext context, QuranWord word, String userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddToSrsSheet(
        word: word,
        userId: userId,
        surah: widget.nav.surah,
        ayah: widget.nav.ayah,
      ),
    );
  }
}

// ── Legend chip ───────────────────────────────────────────────────────────────

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
      ],
    );
  }
}

// ── Add-to-SRS bottom sheet ───────────────────────────────────────────────────

class _AddToSrsSheet extends ConsumerStatefulWidget {
  final QuranWord word;
  final String userId;
  final int surah;
  final int ayah;
  const _AddToSrsSheet({
    required this.word,
    required this.userId,
    required this.surah,
    required this.ayah,
  });

  @override
  ConsumerState<_AddToSrsSheet> createState() => _AddToSrsSheetState();
}

class _AddToSrsSheetState extends ConsumerState<_AddToSrsSheet> {
  bool _loading = true;
  SrsCard? _existingCard;
  bool _added = false;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final db = ref.read(appDatabaseProvider);
    final vocabId = _readerVocabId(normalizeArabic(widget.word.arabic));
    final card = await (db.select(db.srsCards)
          ..where((t) =>
              t.userId.equals(widget.userId) &
              t.vocabularyId.equals(vocabId)))
        .getSingleOrNull();
    if (mounted) setState(() { _existingCard = card; _loading = false; });
  }

  Future<void> _addToSrs() async {
    if (_added) return;
    setState(() => _loading = true);

    final db = ref.read(appDatabaseProvider);
    final srs = SrsLocalSource(db);
    final norm    = normalizeArabic(widget.word.arabic);
    final vocabId = _readerVocabId(norm);

    // Upsert vocabulary row (local-only, lesson_id null).
    await db.into(db.vocabulary).insertOnConflictUpdate(
      VocabularyCompanion(
        id: drift.Value(vocabId),
        arabic: drift.Value(widget.word.arabic),
        meaningBn: drift.Value(
            (_isAyahMarker(widget.word.meaningBn) || widget.word.meaningBn == null)
                ? ''
                : widget.word.meaningBn!),
        lessonId: const drift.Value(null),
      ),
    );

    // Create SRS card (local-only — createCard skips Supabase for reader_ prefix).
    await srs.createCard(widget.userId, vocabId);

    // Award XP (capped 20 words/day).
    final canEarn = await _canAwardXp(widget.userId);
    if (canEarn) {
      await ProgressionService(db).awardBonusXp(widget.userId, 5);
    }

    if (mounted) {
      setState(() { _added = true; _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('যোগ হয়েছে — আগামীকাল রিভিউতে আসবে'),
        backgroundColor: AppColors.forestGreen,
      ));
      Navigator.pop(context);
    }
  }

  static Future<bool> _canAwardXp(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key   = 'reader_add_count_${userId}_${_todayKey()}';
    final count = prefs.getInt(key) ?? 0;
    if (count >= 20) return false;
    await prefs.setInt(key, count + 1);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Arabic word large
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              widget.word.arabic,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 48,
                color: AppColors.gold,
                height: 1.8,
              ),
            ),
          ),
          if (widget.word.meaningBn != null &&
              !_isAyahMarker(widget.word.meaningBn)) ...[
            const SizedBox(height: 8),
            Text(widget.word.meaningBn!,
                style: theme.textTheme.titleLarge),
          ],
          const SizedBox(height: 4),
          Text(
            'সূরা ${widget.surah}, আয়াত ${widget.ayah}, শব্দ ${widget.word.position}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const CircularProgressIndicator()
          else if (_existingCard != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brightGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.brightGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.brightGreen, size: 18),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('আপনি এই শব্দ শিখছেন',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.brightGreen)),
                      Text(
                        'পরবর্তী রিভিউ: ${_formatDate(_existingCard!.dueDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.brightGreen
                                .withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: _addToSrs,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('শব্দভাণ্ডারে যোগ করুন (+৫ XP)'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final today    = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      return 'আজ';
    }
    if (d.year == tomorrow.year &&
        d.month == tomorrow.month &&
        d.day == tomorrow.day) {
      return 'আগামীকাল';
    }
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ── Inline tafsir ─────────────────────────────────────────────────────────────

class _InlineTafsir extends ConsumerWidget {
  final int surah;
  final int ayah;
  final List<QuranWord> masteredInAyah;
  const _InlineTafsir({
    required this.surah,
    required this.ayah,
    required this.masteredInAyah,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tafsirAsync =
        ref.watch(quranTafsirProvider((surah: surah, ayah: ayah)));
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mastered words header
          if (masteredInAyah.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: AppColors.brightGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'এই আয়াতে আপনার শেখা শব্দ: '
                    '${masteredInAyah.map((w) => w.arabic).join('، ')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.brightGreen,
                      fontFamily: 'NotoNaskhArabic',
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  'تفسير أبو بكر زكريا',
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 13,
                    color: AppColors.gold,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('— আবু বকর যাকারিয়া',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          tafsirAsync.when(
            data: (tafsir) => tafsir == null
                ? Text('তাফসীর ডাউনলোড হয়নি',
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant))
                : Text(
                    tafsir.tafsirText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14, height: 2.0),
                  ),
            loading: () => const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => Text('তাফসীর লোড হয়নি',
                style: theme.textTheme.bodySmall),
          ),
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
    final theme     = Theme.of(context);
    final hasMeaning = word.meaningBn != null;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 20, vertical: hasMeaning ? 20 : 14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              word.arabic,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: hasMeaning ? 46 : 32,
                color: AppColors.gold,
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasMeaning)
                  Text(
                    word.meaningBn!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    'অর্থ পাওয়া যায়নি',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'শব্দ ${word.position}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Full-page tafsir view ─────────────────────────────────────────────────────

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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: AppRadius.lgBorder,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '— আবু বকর যাকারিয়া',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                        'এই আয়াতের তাফসীর ডাউনলোড হয়নি',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('এই সূরার তাফসীর ডাউনলোড'),
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
                  height: 2.0,
                ),
              ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: ctrl,
            builder: (_, __) => _shimmerBox(
              theme, ctrl.value,
              width: double.infinity, height: 100, radius: 12,
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
                  theme, ctrl.value,
                  width: 65.0 + (i % 3) * 18, height: 62, radius: 12,
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
    final theme    = Theme.of(context);
    final notifier = ref.read(quranNavProvider.notifier);
    final canPrev  = nav.ayah > 1;
    final canNext  = ayahCount > 0 && nav.ayah < ayahCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ayahCount > 0)
          LinearProgressIndicator(
            value: nav.ayah / ayahCount,
            minHeight: 2,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation(
                AppColors.forestGreen),
          ),
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: canPrev ? notifier.previousAyah : null,
                  style: TextButton.styleFrom(
                    foregroundColor: canPrev
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outlineVariant,
                    shape: const RoundedRectangleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chevron_left_rounded, size: 20),
                      SizedBox(width: 4),
                      Text('আগে', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Text(
                ayahCount > 0
                    ? '${nav.ayah} / $ayahCount'
                    : '${nav.ayah}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: canNext
                      ? () => notifier.nextAyah(ayahCount)
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: canNext
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outlineVariant,
                    shape: const RoundedRectangleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('পরে', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
