import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart' show PlayerState;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import '../../../data/local/quran_local_source.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../../../features/srs/data/srs_local_source.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/progression_service.dart';
import '../../../shared/utils/bn_digits.dart';
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

const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
String _arabicNum(int n) =>
    n.toString().split('').map((d) => _arabicDigits[int.parse(d)]).join();

// Demo design tokens: `--rl` (ayah card radius) and `--rm` (audio bar radius).
const _rl = 22.0;
const _rm = 16.0;

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
  final _scrollController = ScrollController();

  bool _highlightEnabled = true;
  String? _userId;
  ({int ayah, int position})? _litWord;
  int? _tafsirOpenAyah;
  int _activeAyah = 1;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _userId = ref.read(currentUserProvider)?.id;
    final nav = ref.read(quranNavProvider);
    _activeAyah = nav.ayah;

    if (nav.ayah > 1) {
      // Approximate scroll position — exact card heights vary with ayah
      // length, so this lands the reader close to the requested ayah.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final target = (nav.ayah - 1) * 190.0;
        _scrollController.jumpTo(
            target.clamp(0.0, _scrollController.position.maxScrollExtent));
      });
    }

    final uid = _userId;
    if (uid != null) {
      SharedPreferences.getInstance().then((prefs) {
        if (!mounted) return;
        final on = prefs.getBool('reader_highlight_$uid') ?? true;
        setState(() => _highlightEnabled = on);
      });
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _scrollController.dispose();
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
    final nav = ref.watch(quranNavProvider);
    final surahsAsync = ref.watch(quranSurahsProvider);
    final theme = Theme.of(context);
    final bookmarks = ref.watch(quranBookmarksProvider);

    final currentSurah = surahsAsync.valueOrNull
        ?.where((s) => s.number == nav.surah)
        .firstOrNull;
    final ayahCount = currentSurah?.ayahCount ?? 0;
    final showBism = nav.surah == 1;
    final itemCount = ayahCount + (showBism ? 1 : 0);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          _ReaderHeader(
            surah: currentSurah,
            ayahCount: ayahCount,
            showBackButton: widget.showBackButton,
            highlightEnabled: _highlightEnabled,
            onToggleHighlight: _toggleHighlight,
            onShowSurahList: () =>
                _showSurahPicker(context, surahsAsync.valueOrNull ?? []),
          ),
          Expanded(
            child: Stack(
              children: [
                if (ayahCount == 0)
                  const Center(child: CircularProgressIndicator())
                else
                  ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                        12, 14, 12, navClearance(context) + 96),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (showBism && index == 0) {
                        return const _BismillahHeading();
                      }
                      final ayahNum = index - (showBism ? 1 : 0) + 1;
                      return _AyahCard(
                        key: ValueKey('${nav.surah}_$ayahNum'),
                        shimmerCtrl: _shimmerCtrl,
                        surah: nav.surah,
                        ayah: ayahNum,
                        userId: _userId,
                        highlightEnabled: _highlightEnabled,
                        bookmarked:
                            bookmarks.contains('${nav.surah}_$ayahNum'),
                        onToggleBookmark: () => ref
                            .read(quranBookmarksProvider.notifier)
                            .toggle(nav.surah, ayahNum),
                        litPosition: _litWord?.ayah == ayahNum
                            ? _litWord?.position
                            : null,
                        onToggleLit: (pos) => setState(() {
                          _litWord =
                              (_litWord?.ayah == ayahNum &&
                                      _litWord?.position == pos)
                                  ? null
                                  : (ayah: ayahNum, position: pos);
                        }),
                        tafsirOpen: _tafsirOpenAyah == ayahNum,
                        onToggleTafsir: () => setState(() {
                          _tafsirOpenAyah =
                              _tafsirOpenAyah == ayahNum ? null : ayahNum;
                        }),
                        onTapBody: () =>
                            setState(() => _activeAyah = ayahNum),
                      );
                    },
                  ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: navClearance(context) + 12,
                  child: _AudioBar(surah: nav.surah, ayah: _activeAyah),
                ),
              ],
            ),
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
          setState(() {
            _litWord = null;
            _tafsirOpenAyah = null;
            _activeAyah = 1;
          });
          if (_scrollController.hasClients) _scrollController.jumpTo(0);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Header (.qh) ──────────────────────────────────────────────────────────

class _ReaderHeader extends StatelessWidget {
  final QuranSurah? surah;
  final int ayahCount;
  final bool showBackButton;
  final bool highlightEnabled;
  final VoidCallback onToggleHighlight;
  final VoidCallback onShowSurahList;

  const _ReaderHeader({
    required this.surah,
    required this.ayahCount,
    required this.showBackButton,
    required this.highlightEnabled,
    required this.onToggleHighlight,
    required this.onShowSurahList,
  });

  @override
  Widget build(BuildContext context) {
    final s = surah;
    final topInset = MediaQuery.paddingOf(context).top;
    const metaStyle = TextStyle(
      fontSize: 10,
      color: Colors.white60,
      letterSpacing: 0.6,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(8, topInset + 2, 8, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.teal, AppColors.tealLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x590D2218),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: -14,
            bottom: -30,
            child: Opacity(
              opacity: 0.12,
              child: Text(
                '﴿',
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 112,
                  color: AppColors.gold,
                  height: 1,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  if (showBackButton)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.go('/home'),
                    )
                  else
                    const SizedBox(width: 48, height: 48),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      highlightEnabled
                          ? Icons.remove_red_eye_rounded
                          : Icons.visibility_off_rounded,
                      color: highlightEnabled
                          ? AppColors.goldLight
                          : Colors.white70,
                    ),
                    tooltip: highlightEnabled ? 'রঙ বন্ধ করুন' : 'রঙ চালু করুন',
                    onPressed: onToggleHighlight,
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted_rounded,
                        color: Colors.white70),
                    tooltip: 'সূরা তালিকা',
                    onPressed: onShowSurahList,
                  ),
                ],
              ),
              if (s == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              else ...[
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    '﴿ ${s.nameAr} ﴾',
                    style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 25,
                      color: AppColors.goldLight,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'সূরা ${s.nameBn} · শব্দে শব্দে',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s.revelation == 'meccan' ? 'মাক্কী' : 'মাদানী',
                        style: metaStyle),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('✦', style: metaStyle),
                    ),
                    Text('${bnDigits(ayahCount)} আয়াত', style: metaStyle),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('✦', style: metaStyle),
                    ),
                    const Text('QPC হাফস · GTAF', style: metaStyle),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Plain Bismillah heading (.bism) ──────────────────────────────────────

class _BismillahHeading extends StatelessWidget {
  const _BismillahHeading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12, top: 2),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 22,
            color: AppColors.midGreen,
            height: 1.8,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Surah picker bottom sheet ────────────────────────────────────────────

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

// ── Ayah card (.ay) ───────────────────────────────────────────────────────

class _AyahCard extends ConsumerWidget {
  final AnimationController shimmerCtrl;
  final int surah;
  final int ayah;
  final String? userId;
  final bool highlightEnabled;
  final bool bookmarked;
  final VoidCallback onToggleBookmark;
  final int? litPosition;
  final void Function(int position) onToggleLit;
  final bool tafsirOpen;
  final VoidCallback onToggleTafsir;
  final VoidCallback onTapBody;

  const _AyahCard({
    super.key,
    required this.shimmerCtrl,
    required this.surah,
    required this.ayah,
    required this.userId,
    required this.highlightEnabled,
    required this.bookmarked,
    required this.onToggleBookmark,
    required this.litPosition,
    required this.onToggleLit,
    required this.tafsirOpen,
    required this.onToggleTafsir,
    required this.onTapBody,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync =
        ref.watch(quranAyahWordsProvider((surah: surah, ayah: ayah)));

    return wordsAsync.when(
      data: (words) => words.isEmpty
          ? const SizedBox.shrink()
          : _buildCard(context, ref, words),
      loading: () => _ShimmerAyahCard(ctrl: shimmerCtrl),
      error: (_, __) => _ErrorAyahCard(surah: surah, ayah: ayah),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, List<QuranWord> words) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Set<String> mastered = {};
    Set<String> learning = {};
    final uid = userId;
    if (uid != null && highlightEnabled) {
      final known = ref.watch(knownWordFormsProvider(uid)).valueOrNull;
      mastered = known?.mastered ?? {};
      learning = known?.learning ?? {};
    }

    final displayWords = words.where((w) => _isRealWord(w.arabic)).toList();
    final translation = displayWords
        .map((w) => w.meaningBn ?? '')
        .where((s) => s.isNotEmpty && !_isAyahMarker(s))
        .join(' ');

    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final lineColor = isDark ? AppColors.darkOutlineVariant : AppColors.line;
    final pillBg = isDark ? AppColors.darkCard : AppColors.cream;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTapBody,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, top: 10),
        padding: const EdgeInsets.fromLTRB(13, 15, 13, 11),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: lineColor),
          borderRadius: BorderRadius.circular(_rl),
          boxShadow: AppShadows.card,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // .aynum — gold ayah-number pill
            Positioned(
              top: -22,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: pillBg,
                  border: Border.all(color: AppColors.gold),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _arabicNum(ayah),
                  style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldDeep,
                  ),
                ),
              ),
            ),
            // .bm — bookmark toggle
            Positioned(
              top: -22,
              left: 0,
              child: GestureDetector(
                onTap: onToggleBookmark,
                child: Container(
                  width: 28,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pillBg,
                    border: Border.all(
                      color: bookmarked ? AppColors.gold : lineColor,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Icon(
                    bookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 14,
                    color: bookmarked
                        ? AppColors.goldDeep
                        : const Color(0xFFB9AF97),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // .ws — word chips
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: displayWords.map((w) {
                      final norm = normalizeArabic(w.arabic);
                      final isMastered =
                          highlightEnabled && mastered.contains(norm);
                      final isLearning =
                          highlightEnabled && learning.contains(norm);
                      return _WordChip(
                        word: w,
                        lit: litPosition == w.position,
                        mastered: isMastered,
                        learning: isLearning,
                        onTap: () => onToggleLit(w.position),
                        onLongPress: uid != null
                            ? () => _showAddToSrs(context, w, uid)
                            : null,
                      );
                    }).toList(),
                  ),
                ),
                // .aybn — Bengali translation
                if (translation.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 9),
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: lineColor)),
                    ),
                    child: Text(
                      translation,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.65,
                        color: isDark ? Colors.white70 : AppColors.ink2,
                      ),
                    ),
                  ),
                // .tafl — inline tafsir toggle
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: onToggleTafsir,
                      child: Text(
                        'তাফসীর ${tafsirOpen ? "▴" : "▾"}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tealLight,
                        ),
                      ),
                    ),
                  ),
                ),
                if (tafsirOpen) _TafsirInline(surah: surah, ayah: ayah),
              ],
            ),
          ],
        ),
      ),
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
        surah: surah,
        ayah: ayah,
      ),
    );
  }
}

// ── Word chip (.w) ────────────────────────────────────────────────────────

class _WordChip extends StatelessWidget {
  final QuranWord word;
  final bool lit;
  final bool mastered;
  final bool learning;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _WordChip({
    required this.word,
    required this.lit,
    required this.mastered,
    required this.learning,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final meaning =
        _isAyahMarker(word.meaningBn) ? '—' : (word.meaningBn ?? '—');
    final root = word.root;

    final arabicColor = lit
        ? AppColors.goldDeep
        : mastered
            ? AppColors.brightGreen
            : (isDark ? Colors.white : AppColors.ink);
    final meaningColor = lit
        ? AppColors.goldDeep
        : mastered
            ? AppColors.brightGreen.withValues(alpha: 0.85)
            : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 4),
        decoration: BoxDecoration(
          color: lit
              ? const Color(0xFFFBF3DE)
              : mastered
                  ? AppColors.brightGreen.withValues(alpha: 0.10)
                  : Colors.transparent,
          border: Border.all(
            color: lit
                ? AppColors.gold
                : mastered
                    ? AppColors.brightGreen
                    : Colors.transparent,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word.arabic,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 22,
                height: 1.55,
                color: arabicColor,
              ),
            ),
            Text(
              meaning,
              style: TextStyle(
                fontSize: 10,
                height: 1.3,
                fontWeight: lit ? FontWeight.w600 : FontWeight.normal,
                color: meaningColor,
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (lit && root != null && root.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  root,
                  style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 10.5,
                    color: AppColors.goldDeep,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            if (learning && !lit)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 18,
                height: 2,
                color: AppColors.gold,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Inline tafsir panel (.tafb) ──────────────────────────────────────────

class _TafsirInline extends ConsumerWidget {
  final int surah;
  final int ayah;
  const _TafsirInline({required this.surah, required this.ayah});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tafsirAsync =
        ref.watch(quranTafsirProvider((surah: surah, ayah: ayah)));

    return Container(
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.teal.withValues(alpha: 0.16)
            : const Color(0xFFF4F8F6),
        border: Border.all(
          color: isDark
              ? AppColors.tealLight.withValues(alpha: 0.35)
              : const Color(0xFFD9E6DF),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: tafsirAsync.when(
        data: (tafsir) => tafsir == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'এই আয়াতের তাফসীর ডাউনলোড হয়নি',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () async {
                      await ref
                          .read(quranLocalSourceProvider)
                          .syncTafsirFromSupabase(surah);
                      ref.invalidate(
                          quranTafsirProvider((surah: surah, ayah: ayah)));
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('ডাউনলোড করুন',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              )
            : Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: tafsir.tafsirText,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.7,
                        color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF33564A),
                        fontFamily: 'HindSiliguri',
                      ),
                    ),
                    TextSpan(
                      text: ' — তাফসীরে যাকারিয়া',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.tealLight.withValues(alpha: 0.9) : const Color(0xFF7A958A),
                        fontFamily: 'HindSiliguri',
                      ),
                    ),
                  ],
                ),
              ),
        loading: () => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) =>
            Text('তাফসীর লোড হয়নি', style: theme.textTheme.bodySmall),
      ),
    );
  }
}

// ── Floating audio bar (.qa) ────────────────────────────────────────────

class _AudioBar extends ConsumerWidget {
  final int surah;
  final int ayah;
  const _AudioBar({required this.surah, required this.ayah});

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return bnDigits('$m:$s');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);
    final url = _ayahAudioUrl(surah, ayah);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.circular(_rm),
        boxShadow: AppShadows.pop,
      ),
      child: StreamBuilder<PlayerState>(
        stream: audio.playerStateStream,
        builder: (context, stateSnap) {
          final isThisAyah = audio.currentUrl == url;
          final playing = isThisAyah && (stateSnap.data?.playing ?? false);

          return StreamBuilder<Duration>(
            stream: audio.positionStream,
            builder: (context, posSnap) {
              final position =
                  isThisAyah ? (posSnap.data ?? Duration.zero) : Duration.zero;
              final duration =
                  isThisAyah ? (audio.duration ?? Duration.zero) : Duration.zero;
              final progress = duration.inMilliseconds > 0
                  ? (position.inMilliseconds / duration.inMilliseconds)
                      .clamp(0.0, 1.0)
                  : 0.0;

              return Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!isThisAyah) {
                        audio.playUrl(url);
                      } else if (playing) {
                        audio.pause();
                      } else {
                        audio.resume();
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'মিশারী আল-আফাসী',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cream,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.goldLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_fmt(position)} / ${_fmt(duration)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.cream.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Add-to-SRS bottom sheet ───────────────────────────────────────────────

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
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref
                .read(audioServiceProvider)
                .playUrl(_ayahAudioUrl(widget.surah, widget.ayah)),
            icon: const Icon(Icons.volume_up_rounded, size: 18),
            label: const Text('আয়াত শুনুন'),
          ),
          const SizedBox(height: 8),
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

// ── Shimmer skeleton ──────────────────────────────────────────────────────

class _ShimmerAyahCard extends StatelessWidget {
  final AnimationController ctrl;
  const _ShimmerAyahCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(_rl),
      ),
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) => Column(
          children: [
            _shimmerBox(theme, ctrl.value,
                width: double.infinity, height: 60, radius: 12),
            const SizedBox(height: 10),
            _shimmerBox(theme, ctrl.value,
                width: double.infinity, height: 30, radius: 8),
          ],
        ),
      ),
    );
  }
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

// ── Error card ────────────────────────────────────────────────────────────

class _ErrorAyahCard extends ConsumerWidget {
  final int surah;
  final int ayah;
  const _ErrorAyahCard({required this.surah, required this.ayah});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(_rl),
      ),
      child: Center(
        child: TextButton(
          onPressed: () => ref
              .invalidate(quranAyahWordsProvider((surah: surah, ayah: ayah))),
          child: const Text('আবার চেষ্টা করুন'),
        ),
      ),
    );
  }
}
