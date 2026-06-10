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
import '../../../shared/services/audio_service.dart';
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

// Mishary Al-Afasy per-ayah recitation (pattern documented in CLAUDE.md).
String _ayahAudioUrl(int surah, int ayah) {
  final s = surah.toString().padLeft(3, '0');
  final a = ayah.toString().padLeft(3, '0');
  return 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$s$a.mp3';
}

// Tafsir sheet geometry
const _tafsirPeekFraction = 0.09;
const _tafsirMaxFraction  = 0.85;
const _tafsirPeekPadding  = 64.0; // word area bottom inset so peek never covers it

class QuranWordReaderPage extends ConsumerStatefulWidget {
  final bool showBackButton;
  const QuranWordReaderPage({super.key, this.showBackButton = true});

  @override
  ConsumerState<QuranWordReaderPage> createState() =>
      _QuranWordReaderPageState();
}

class _QuranWordReaderPageState extends ConsumerState<QuranWordReaderPage>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final AnimationController _immersiveCtrl;
  late final Animation<double> _headerAnim;
  final _sheetCtrl = DraggableScrollableController();

  bool _highlightEnabled = true;
  bool _immersive = false;
  bool _tafsirOpen = false;
  int _navDir = 1; // +1 forward (next ayah), -1 backward — drives slide direction
  String? _userId;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _immersiveCtrl =
        AnimationController(vsync: this, duration: AppMotion.normal);
    _headerAnim = ReverseAnimation(
        CurvedAnimation(parent: _immersiveCtrl, curve: Curves.easeOutCubic));
    _sheetCtrl.addListener(_onSheetChanged);

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
    _immersiveCtrl.dispose();
    _sheetCtrl.dispose();
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

  void _onSheetChanged() {
    final open = _sheetCtrl.isAttached && _sheetCtrl.size > 0.4;
    if (open != _tafsirOpen) setState(() => _tafsirOpen = open);
  }

  void _toggleImmersive() {
    setState(() => _immersive = !_immersive);
    if (MediaQuery.of(context).disableAnimations) {
      _immersiveCtrl.value = _immersive ? 1.0 : 0.0;
    } else if (_immersive) {
      _immersiveCtrl.forward();
    } else {
      _immersiveCtrl.reverse();
    }
  }

  void _toggleTafsirSheet() {
    if (!_sheetCtrl.isAttached) return;
    if (_immersive) _toggleImmersive();
    final target =
        _sheetCtrl.size > 0.4 ? _tafsirPeekFraction : _tafsirMaxFraction;
    if (MediaQuery.of(context).disableAnimations) {
      _sheetCtrl.jumpTo(target);
    } else {
      _sheetCtrl.animateTo(target,
          duration: AppMotion.normal, curve: Curves.easeOutCubic);
    }
  }

  void _onSwipe(DragEndDetails details, int ayahCount) {
    final v = details.primaryVelocity ?? 0;
    if (v.abs() < 200) return;
    final nav      = ref.read(quranNavProvider);
    final notifier = ref.read(quranNavProvider.notifier);
    if (v < 0) {
      // Swiped left → next ayah
      if (ayahCount > 0 && nav.ayah < ayahCount) {
        _navDir = 1;
        notifier.nextAyah(ayahCount);
      }
    } else {
      if (nav.ayah > 1) {
        _navDir = -1;
        notifier.previousAyah();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav         = ref.watch(quranNavProvider);
    final surahsAsync = ref.watch(quranSurahsProvider);
    final theme       = Theme.of(context);
    final disableAnim = MediaQuery.of(context).disableAnimations;

    final currentSurah = surahsAsync.valueOrNull
        ?.where((s) => s.number == nav.surah)
        .firstOrNull;
    final ayahCount = currentSurah?.ayahCount ?? 0;

    // Mastered words appearing in this ayah (tafsir-sheet strip, max 4).
    final words = ref
            .watch(quranAyahWordsProvider((surah: nav.surah, ayah: nav.ayah)))
            .valueOrNull ??
        const <QuranWord>[];
    var masteredInAyah = const <QuranWord>[];
    final uid = _userId;
    if (uid != null && _highlightEnabled) {
      final mastered =
          ref.watch(knownWordFormsProvider(uid)).valueOrNull?.mastered ?? {};
      masteredInAyah = words
          .where((w) =>
              _isRealWord(w.arabic) &&
              mastered.contains(normalizeArabic(w.arabic)))
          .take(4)
          .toList();
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header — slides/fades away in immersive mode ────────────
            SizeTransition(
              sizeFactor: _headerAnim,
              alignment: Alignment.topCenter,
              child: FadeTransition(
                opacity: _headerAnim,
                child: _ReaderHeader(
                  surah: currentSurah,
                  ayah: nav.ayah,
                  ayahCount: ayahCount,
                  showBackButton: widget.showBackButton,
                  highlightEnabled: _highlightEnabled,
                  tafsirOpen: _tafsirOpen,
                  onToggleHighlight: _toggleHighlight,
                  onToggleTafsir: _toggleTafsirSheet,
                  onShowSurahList: () =>
                      _showSurahPicker(context, surahsAsync.valueOrNull ?? []),
                ),
              ),
            ),

            // ── Ayah area + persistent tafsir sheet ─────────────────────
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedPadding(
                      duration: disableAnim ? Duration.zero : AppMotion.normal,
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.only(
                          bottom: _immersive ? 0 : _tafsirPeekPadding),
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _toggleImmersive,
                        onHorizontalDragEnd: (d) => _onSwipe(d, ayahCount),
                        child: AnimatedSwitcher(
                          duration:
                              disableAnim ? Duration.zero : AppMotion.gentle,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(0.15 * _navDir, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey('${nav.surah}_${nav.ayah}'),
                            child: _AyahBody(
                              shimmerCtrl: _shimmerCtrl,
                              nav: nav,
                              userId: _userId,
                              highlightEnabled: _highlightEnabled,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedSlide(
                      offset: _immersive ? const Offset(0, 1) : Offset.zero,
                      duration: disableAnim ? Duration.zero : AppMotion.normal,
                      curve: Curves.easeOutCubic,
                      child: IgnorePointer(
                        ignoring: _immersive,
                        child: _TafsirSheet(
                          surah: nav.surah,
                          ayah: nav.ayah,
                          masteredInAyah: masteredInAyah,
                          controller: _sheetCtrl,
                          onPeekTap: _toggleTafsirSheet,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          _navDir = 1;
          ref.read(quranNavProvider.notifier).goToSurah(n);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Header (replaces AppBar so it can slide away in immersive mode) ──────────

class _ReaderHeader extends StatelessWidget {
  final QuranSurah? surah;
  final int ayah;
  final int ayahCount;
  final bool showBackButton;
  final bool highlightEnabled;
  final bool tafsirOpen;
  final VoidCallback onToggleHighlight;
  final VoidCallback onToggleTafsir;
  final VoidCallback onShowSurahList;

  const _ReaderHeader({
    required this.surah,
    required this.ayah,
    required this.ayahCount,
    required this.showBackButton,
    required this.highlightEnabled,
    required this.tafsirOpen,
    required this.onToggleHighlight,
    required this.onToggleTafsir,
    required this.onShowSurahList,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = surah;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: s == null
                ? Text('শব্দে শব্দে কুরআন',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          s.nameAr,
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
                          Flexible(
                            child: Text(
                              s.nameBn,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: s.revelation == 'meccan'
                                  ? AppColors.gold.withValues(alpha: 0.15)
                                  : Colors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s.revelation == 'meccan' ? 'মাক্কী' : 'মাদানী',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: s.revelation == 'meccan'
                                    ? AppColors.gold
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Ayah counter pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen
                                  .withValues(alpha: 0.10),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl),
                            ),
                            child: Text(
                              ayahCount > 0
                                  ? 'আয়াত $ayah / $ayahCount'
                                  : 'আয়াত $ayah',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.brightness == Brightness.dark
                                    ? AppColors.brightGreen
                                    : AppColors.forestGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          IconButton(
            icon: Icon(
              highlightEnabled
                  ? Icons.remove_red_eye_rounded
                  : Icons.visibility_off_rounded,
              color: highlightEnabled ? AppColors.brightGreen : null,
            ),
            tooltip: highlightEnabled ? 'রঙ বন্ধ করুন' : 'রঙ চালু করুন',
            onPressed: onToggleHighlight,
          ),
          IconButton(
            icon: Icon(
              Icons.menu_book_rounded,
              color: tafsirOpen ? AppColors.gold : null,
            ),
            tooltip: tafsirOpen ? 'তাফসীর বন্ধ করুন' : 'তাফসীর দেখুন',
            onPressed: onToggleTafsir,
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            tooltip: 'সূরা তালিকা',
            onPressed: onShowSurahList,
          ),
        ],
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
    final wordsAsync = ref.watch(
        quranAyahWordsProvider((surah: nav.surah, ayah: nav.ayah)));

    return wordsAsync.when(
      data: (words) => words.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _WordView(
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

class _WordView extends ConsumerWidget {
  final List<QuranWord> words;
  final QuranNavState nav;
  final String? userId;
  final bool highlightEnabled;
  const _WordView({
    required this.words,
    required this.nav,
    required this.userId,
    required this.highlightEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Fetch known forms only when userId is available and highlight is on.
    Set<String> mastered = {};
    Set<String> learning = {};
    final uid = userId;
    if (uid != null && highlightEnabled) {
      final known = ref.watch(knownWordFormsProvider(uid)).valueOrNull;
      mastered = known?.mastered ?? {};
      learning = known?.learning ?? {};
    }

    final displayWords = words.where((w) => _isRealWord(w.arabic)).toList();
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
    // Line-height floor 1.7 — harakat need vertical room at every size.
    final arabicLineHeight =
        wordCount > 20 ? 1.7 : wordCount > 10 ? 1.8 : 2.1;

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
                // Scrollable so long ayahs never clip harakat.
                Flexible(
                  child: SingleChildScrollView(
                    child: Directionality(
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
                        '${nav.ayah}',
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

        // ── Scrollable word chips ────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Legend row (only when highlight on AND userId present)
                if (highlightEnabled && uid != null)
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
                      final isSelected = word.position == nav.selectedWord;
                      final norm       = normalizeArabic(word.arabic);
                      final isMastered =
                          highlightEnabled && mastered.contains(norm);
                      final isLearning =
                          highlightEnabled && learning.contains(norm);

                      return GestureDetector(
                        onTap: () => _showWordDetail(context, ref, word),
                        onLongPress: uid != null
                            ? () => _showAddToSrs(context, word, uid)
                            : null,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              isSelected ? AppRadius.full : 12),
                          child: Stack(
                            children: [
                              AnimatedContainer(
                                duration: AppMotion.fast,
                                constraints: const BoxConstraints(
                                    minHeight: 44, minWidth: 44),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.gold.withValues(alpha: 0.15)
                                      : isMastered
                                          ? AppColors.brightGreen
                                              .withValues(alpha: 0.10)
                                          : theme.colorScheme.surfaceContainer,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.gold
                                        : isMastered
                                            ? AppColors.brightGreen
                                            : theme.colorScheme.outlineVariant,
                                    width: isSelected
                                        ? 1.5
                                        : isMastered
                                            ? 1.5
                                            : 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      isSelected ? AppRadius.full : 12),
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
                                            ? AppColors.gold
                                                .withValues(alpha: 0.85)
                                            : isMastered
                                                ? AppColors.brightGreen
                                                    .withValues(alpha: 0.85)
                                                : theme
                                                    .colorScheme.onSurfaceVariant,
                                      ),
                                      textDirection: TextDirection.ltr,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isLearning)
                                const Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: SizedBox(
                                    height: 2,
                                    child: ColoredBox(color: AppColors.gold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showWordDetail(BuildContext context, WidgetRef ref, QuranWord word) {
    ref.read(quranNavProvider.notifier).selectWord(word.position);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _WordDetailSheet(
        word: word,
        surah: nav.surah,
        ayah: nav.ayah,
      ),
    ).whenComplete(() {
      if (context.mounted) {
        ref.read(quranNavProvider.notifier).clearWord();
      }
    });
  }

  void _showAddToSrs(BuildContext context, QuranWord word, String userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddToSrsSheet(
        word: word,
        userId: userId,
        surah: nav.surah,
        ayah: nav.ayah,
      ),
    );
  }
}

// ── Word detail bottom sheet ──────────────────────────────────────────────────

class _WordDetailSheet extends ConsumerWidget {
  final QuranWord word;
  final int surah;
  final int ayah;
  const _WordDetailSheet({
    required this.word,
    required this.surah,
    required this.ayah,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasMeaning =
        word.meaningBn != null && !_isAyahMarker(word.meaningBn);
    final root = word.root;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              word.arabic,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 44,
                color: AppColors.gold,
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (hasMeaning)
            Text(
              word.meaningBn!,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
          else
            Text(
              'অর্থ পাওয়া যায়নি',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'শব্দ ${word.position}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (root != null && root.isNotEmpty) ...[
                Text(
                  ' · মূল: ',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    root,
                    style: AppText.arabic(
                        fontSize: 20, color: AppColors.gold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => ref
                .read(audioServiceProvider)
                .playUrl(_ayahAudioUrl(surah, ayah)),
            icon: const Icon(Icons.volume_up_rounded, size: 18),
            label: const Text('আয়াত শুনুন'),
          ),
        ],
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

// ── Persistent tafsir sheet ───────────────────────────────────────────────────

class _TafsirSheet extends ConsumerWidget {
  final int surah;
  final int ayah;
  final List<QuranWord> masteredInAyah;
  final DraggableScrollableController controller;
  final VoidCallback onPeekTap;

  const _TafsirSheet({
    required this.surah,
    required this.ayah,
    required this.masteredInAyah,
    required this.controller,
    required this.onPeekTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tafsirAsync =
        ref.watch(quranTafsirProvider((surah: surah, ayah: ayah)));

    return DraggableScrollableSheet(
      controller: controller,
      minChildSize: _tafsirPeekFraction,
      initialChildSize: _tafsirPeekFraction,
      maxChildSize: _tafsirMaxFraction,
      snap: true,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl)),
          border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.zero,
          children: [
            // ── Peek bar ──────────────────────────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPeekTap,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_rounded,
                            size: 16, color: AppColors.gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'তাফসীর — আবু বকর যাকারিয়া · টেনে তুলুন',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_up_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Expanded content ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                  ],
                  tafsirAsync.when(
                    data: (tafsir) => tafsir == null
                        ? Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                Icon(Icons.menu_book_outlined,
                                    size: 40,
                                    color:
                                        theme.colorScheme.onSurfaceVariant),
                                const SizedBox(height: 10),
                                Text(
                                  'এই আয়াতের তাফসীর ডাউনলোড হয়নি',
                                  style:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  icon: const Icon(Icons.download_rounded,
                                      size: 18),
                                  label: const Text(
                                      'এই সূরার তাফসীর ডাউনলোড'),
                                  onPressed: () async {
                                    await ref
                                        .read(quranLocalSourceProvider)
                                        .syncTafsirFromSupabase(surah);
                                    ref.invalidate(quranTafsirProvider(
                                        (surah: surah, ayah: ayah)));
                                  },
                                ),
                              ],
                            ),
                          )
                        : Text(
                            tafsir.tafsirText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              height: 2.0,
                            ),
                          ),
                    loading: () => const Center(
                        child: Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2)),
                    )),
                    error: (_, __) => Text('তাফসীর লোড হয়নি',
                        style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ],
        ),
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
