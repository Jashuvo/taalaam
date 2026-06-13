import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import '../../../shared/services/progression_service.dart';
import '../../../shared/utils/bn_digits.dart';
import '../../../shared/widgets/arabic_audio_button.dart';
import '../../../shared/widgets/misbaha/ornament_stamp.dart';
import '../../../shared/widgets/misbaha/stat_pill.dart';
import '../../../shared/widgets/shimmer_skeleton.dart';
import '../../auth/presentation/auth_provider.dart';
import 'srs_provider.dart';

// Cached vocab lookup — prevents FutureBuilder recreating the Future on every rebuild.
final _vocabEntryProvider = FutureProvider.autoDispose
    .family<VocabEntry?, String>((ref, vocabId) async {
  final db = ref.read(appDatabaseProvider);
  return (db.select(db.vocabulary)..where((t) => t.id.equals(vocabId)))
      .getSingleOrNull();
});

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('রিভিউ')),
        body: const Center(child: Text('লগইন করুন।')),
      );
    }
    return _ReviewBody(userId: user.id);
  }
}

class _ReviewBody extends ConsumerWidget {
  final String userId;
  const _ReviewBody({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(reviewSessionProvider(userId));
    final notifier = ref.read(reviewSessionProvider(userId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('দৈনিক রিভিউ'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          if (notifier.currentCard != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'বাকি ${bnDigits(notifier.remaining)}/${bnDigits(notifier.total)}',
                  style: const TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const ReviewSkeleton(),
        error: (e, _) => Center(child: Text('$e')),
        data: (_) {
          final card = notifier.currentCard;
          if (card == null) {
            return _ReviewDoneView(
              reward: notifier.reward,
              onHome: () => context.go('/home'),
            );
          }
          return _CardView(
            key: ValueKey(card.id),
            card: card,
            notifier: notifier,
          );
        },
      ),
    );
  }
}

// ── Card view ─────────────────────────────────────────────────────────────────

class _CardView extends StatefulWidget {
  final SrsCard card;
  final ReviewSessionNotifier notifier;
  const _CardView({required this.card, required this.notifier, super.key});

  @override
  State<_CardView> createState() => _CardViewState();
}

class _CardViewState extends State<_CardView> {
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _flipped
                        ? null
                        : () => setState(() => _flipped = true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 38, 18, 22),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkOutlineVariant
                                : AppColors.line),
                        borderRadius: AppRadius.xlBorder,
                        boxShadow: AppShadows.card,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -26,
                            left: -6,
                            child: _SrsStatePill(card: widget.card),
                          ),
                          Center(
                            child: SingleChildScrollView(
                              child: _flipped
                                  ? _FlippedFace(
                                      vocabId: widget.card.vocabularyId)
                                  : _FrontFace(
                                      vocabId: widget.card.vocabularyId),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Feature 3: context snippet below card when flipped
                if (_flipped)
                  _ContextSnippetLoader(vocabId: widget.card.vocabularyId),
              ],
            ),
          ),
          if (!_flipped)
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Text(
                'অর্থ দেখতে কার্ডে চাপ দিন',
                style: TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: 11.5,
                  color: Color(0xFFB9AF97),
                ),
              ),
            ),
          if (_flipped) ...[
            const SizedBox(height: 13),
            Row(
              children: [
                _RatingBtn(
                    label: 'আবার',
                    sub: '< ১ মিনিট',
                    rating: 1,
                    color: const Color(0xFFC0392B),
                    notifier: widget.notifier),
                _RatingBtn(
                    label: 'কঠিন',
                    sub: '১০ মিনিট',
                    rating: 2,
                    color: const Color(0xFFE67E22),
                    notifier: widget.notifier),
                _RatingBtn(
                    label: 'ভালো',
                    sub: '১ দিন',
                    rating: 3,
                    color: AppColors.okGreen,
                    notifier: widget.notifier),
                _RatingBtn(
                    label: 'সহজ',
                    sub: '৪ দিন',
                    rating: 4,
                    color: const Color(0xFF2471A3),
                    notifier: widget.notifier),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── SRS state pill (`.spill` in the demo) ───────────────────────────────────

class _SrsStatePill extends StatelessWidget {
  final SrsCard card;
  const _SrsStatePill({required this.card});

  @override
  Widget build(BuildContext context) {
    final isNew = card.reps == 0;
    final isLearning = card.stability < 2.0;
    final (label, fg, bg, border) = isNew
        ? ('নতুন', const Color(0xFF1565C0), const Color(0xFFEAF2FB),
            const Color(0xFF9FC4E8))
        : isLearning
            ? ('শেখা হচ্ছে', const Color(0xFFB45309), const Color(0xFFFBF1DF),
                const Color(0xFFEAC089))
            : ('স্মরণে আছে', AppColors.okGreen, AppColors.okBg,
                const Color(0xFFA8D4AB));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'HindSiliguri',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ── Front (Arabic) ────────────────────────────────────────────────────────────

class _FrontFace extends ConsumerWidget {
  final String vocabId;
  const _FrontFace({required this.vocabId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entryAsync = ref.watch(_vocabEntryProvider(vocabId));
    return entryAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Icon(Icons.error_outline),
      data: (entry) => entry == null
          ? const SizedBox.shrink()
          : Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                entry.arabic,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 52,
                  height: 1.4,
                  color: isDark ? AppColors.darkOnSurface : AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}

// ── Flipped (meaning + metadata) ──────────────────────────────────────────────

class _FlippedFace extends ConsumerWidget {
  final String vocabId;
  const _FlippedFace({required this.vocabId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entry = ref.watch(_vocabEntryProvider(vocabId)).valueOrNull;
    if (entry == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            entry.arabic,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 52,
              height: 1.4,
              color: isDark ? AppColors.darkOnSurface : AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        ArabicAudioButton(audioUrl: entry.audioUrl),
        if (entry.transliteration != null) ...[
          const SizedBox(height: 4),
          Text(entry.transliteration!,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
        const SizedBox(height: 10),
        Text(
          entry.meaningBn,
          style: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkPrimary : AppColors.forestGreen,
          ),
          textAlign: TextAlign.center,
        ),
        if (entry.meaningEn != null) ...[
          const SizedBox(height: 4),
          Text(entry.meaningEn!,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
        if (entry.rootLetters != null || entry.frequencyRank != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.center,
            children: [
              if (entry.rootLetters != null)
                _RvChip(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'ধাতু ${entry.rootLetters!}',
                      style: const TextStyle(
                          fontFamily: 'NotoNaskhArabic', fontSize: 12.5),
                    ),
                  ),
                ),
              if (entry.frequencyRank != null)
                _RvChip(
                  gold: true,
                  child: Text('কুরআনে #${entry.frequencyRank}'),
                ),
            ],
          ),
        ],
        if (entry.grammarNoteBn != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 13, color: theme.colorScheme.secondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    entry.grammarNoteBn!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Small rounded chip (`.rvchip` / `.rvchip.g` in the demo) ────────────────

class _RvChip extends StatelessWidget {
  final Widget child;
  final bool gold;
  const _RvChip({required this.child, this.gold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: gold ? const Color(0xFFFBF3DE) : const Color(0xFFF2EDE1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontFamily: 'HindSiliguri',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: gold ? AppColors.goldDeep : AppColors.ink2,
        ),
        child: child,
      ),
    );
  }
}

// ── Context snippet loader (Feature 3) ───────────────────────────────────────

class _ContextSnippetLoader extends ConsumerWidget {
  final String vocabId;
  const _ContextSnippetLoader({required this.vocabId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(_vocabEntryProvider(vocabId)).valueOrNull;
    if (entry == null) return const SizedBox.shrink();
    if (entry.contextSnippetAr == null && entry.contextSnippetBn == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _ContextSnippetBlock(entry: entry),
    );
  }
}

class _ContextSnippetBlock extends StatelessWidget {
  final VocabEntry entry;
  const _ContextSnippetBlock({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF6),
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: const Color(0xFFEAD9A8)),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'প্রসঙ্গ',
              style: TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppColors.goldDeep,
              ),
            ),
            if (entry.contextSnippetAr != null) ...[
              const SizedBox(height: 5),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  entry.contextSnippetAr!,
                  style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 19,
                    height: 1.9,
                    color: AppColors.goldDeep,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
            if (entry.contextSnippetBn != null) ...[
              const SizedBox(height: 3),
              Text(
                entry.contextSnippetBn!,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Rating button ─────────────────────────────────────────────────────────────

class _RatingBtn extends StatelessWidget {
  final String label;
  final String sub;
  final int rating;
  final Color color;
  final ReviewSessionNotifier notifier;
  const _RatingBtn(
      {required this.label,
      required this.sub,
      required this.rating,
      required this.color,
      required this.notifier});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.5),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
              elevation: 0,
            ),
            onPressed: () => notifier.rate(rating),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 9.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ── Done / reward screen (Feature 1) ─────────────────────────────────────────

class _ReviewDoneView extends StatefulWidget {
  final SrsReward? reward;
  final VoidCallback onHome;
  const _ReviewDoneView({required this.reward, required this.onHome});

  @override
  State<_ReviewDoneView> createState() => _ReviewDoneViewState();
}

class _ReviewDoneViewState extends State<_ReviewDoneView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reward = widget.reward;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: OrnamentStamp(size: 58)),
                const SizedBox(height: 12),
                Text(
                  'আজকের রিভিউ শেষ!',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkOnSurface : AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                const Text(
                  'FSRS অনুযায়ী পরবর্তী রিভিউ নির্ধারিত হয়েছে',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 12.5,
                    color: AppColors.ink2,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (reward != null) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      StatPill(
                        value: Text('+${reward.xp} XP'),
                        label: 'সেশন XP',
                        gold: true,
                      ),
                      StatPill(
                        value: Text('${reward.streakDays}'),
                        label: 'ধারাবাহিকতা',
                      ),
                      if (reward.heartGained)
                        StatPill(
                          value: Text(
                              '${reward.newHearts}/${AppConstants.heartsPerLesson}'),
                          label: 'হার্ট পুনরুদ্ধার',
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('হোমে ফিরুন'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: widget.onHome,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
