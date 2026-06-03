import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import '../../../shared/services/progression_service.dart';
import '../../../shared/widgets/arabic_audio_button.dart';
import '../../auth/presentation/auth_provider.dart';
import 'srs_provider.dart';

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
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
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
                    child: Card(
                      elevation: 2,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: _flipped
                              ? _FlippedFace(vocabId: widget.card.vocabularyId)
                              : _FrontFace(vocabId: widget.card.vocabularyId),
                        ),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'ট্যাপ করুন উত্তর দেখতে',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (_flipped) ...[
            const SizedBox(height: 8),
            Text('কতটা মনে ছিল?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                _RatingBtn(
                    label: 'ভুলে\nগেছি',
                    rating: 1,
                    color: Colors.red.shade700,
                    notifier: widget.notifier),
                _RatingBtn(
                    label: 'কঠিন',
                    rating: 2,
                    color: Colors.orange.shade700,
                    notifier: widget.notifier),
                _RatingBtn(
                    label: 'ভালো',
                    rating: 3,
                    color: Colors.green.shade600,
                    notifier: widget.notifier),
                _RatingBtn(
                    label: 'সহজ',
                    rating: 4,
                    color: Colors.blue.shade600,
                    notifier: widget.notifier),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ],
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
    final db = ref.watch(appDatabaseProvider);
    return FutureBuilder(
      future: (db.select(db.vocabulary)
            ..where((t) => t.id.equals(vocabId)))
          .getSingleOrNull(),
      builder: (ctx, snap) {
        final entry = snap.data;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            entry?.arabic ?? '...',
            style: const TextStyle(
                fontFamily: 'NotoNaskhArabic', fontSize: 48, height: 1.6),
            textAlign: TextAlign.center,
          ),
        );
      },
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
    final db = ref.watch(appDatabaseProvider);
    return FutureBuilder(
      future: (db.select(db.vocabulary)
            ..where((t) => t.id.equals(vocabId)))
          .getSingleOrNull(),
      builder: (ctx, snap) {
        final entry = snap.data;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                entry?.arabic ?? '',
                style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic', fontSize: 36, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
            ArabicAudioButton(audioUrl: entry?.audioUrl),
            const SizedBox(height: 8),
            if (entry?.transliteration != null)
              Text(entry!.transliteration!,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Text(
              entry?.meaningBn ?? '',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (entry?.meaningEn != null) ...[
              const SizedBox(height: 4),
              Text(entry!.meaningEn!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (entry?.rootLetters != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_tree_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('মূল: ',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      entry!.rootLetters!,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 16,
                        height: 1.6,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (entry?.frequencyRank != null) ...[
              const SizedBox(height: 4),
              Text(
                'কুরআনে ${entry!.frequencyRank}তম সর্বাধিক ব্যবহৃত',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.tertiary),
                textAlign: TextAlign.center,
              ),
            ],
            if (entry?.grammarNoteBn != null) ...[
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
                        entry!.grammarNoteBn!,
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
      },
    );
  }
}

// ── Context snippet loader (Feature 3) ───────────────────────────────────────

class _ContextSnippetLoader extends ConsumerWidget {
  final String vocabId;
  const _ContextSnippetLoader({required this.vocabId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    return FutureBuilder(
      future: (db.select(db.vocabulary)
            ..where((t) => t.id.equals(vocabId)))
          .getSingleOrNull(),
      builder: (ctx, snap) {
        final entry = snap.data;
        if (entry == null) return const SizedBox.shrink();
        if (entry.contextSnippetAr == null && entry.contextSnippetBn == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _ContextSnippetBlock(entry: entry),
        );
      },
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
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.3), width: 1),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.auto_stories_rounded,
                  size: 14, color: AppColors.gold),
              const SizedBox(width: 6),
              Text('প্রসঙ্গ',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.gold)),
            ]),
            if (entry.contextSnippetAr != null) ...[
              const SizedBox(height: 10),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  entry.contextSnippetAr!,
                  style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 18,
                    height: 2.0,
                    color: AppColors.gold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
            if (entry.contextSnippetBn != null) ...[
              const SizedBox(height: 6),
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
  final int rating;
  final Color color;
  final ReviewSessionNotifier notifier;
  const _RatingBtn(
      {required this.label,
      required this.rating,
      required this.color,
      required this.notifier});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => notifier.rate(rating),
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
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
    final theme = Theme.of(context);
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
                const Text('✅', style: TextStyle(fontSize: 64),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text('আজকের রিভিউ শেষ!',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: theme.colorScheme.primary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('আবার আগামীকাল দেখুন।',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (reward != null) ...[
                  _ReviewRewardCard(reward: reward),
                  const SizedBox(height: 24),
                ],
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

class _ReviewRewardCard extends StatelessWidget {
  final SrsReward reward;
  const _ReviewRewardCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _Row(
            icon: '⭐',
            label: 'অর্জিত XP',
            value: '+${reward.xp} XP',
            color: AppColors.gold,
          ),
          const Divider(height: 20),
          _Row(
            icon: '🔥',
            label: 'ধারাবাহিকতা',
            value: '${reward.streakDays} দিন',
            color: Colors.orangeAccent,
          ),
          if (reward.heartGained) ...[
            const Divider(height: 20),
            _Row(
              icon: '❤️',
              label: 'হার্ট পুনরুদ্ধার',
              value:
                  '+১ (${reward.newHearts}/${AppConstants.heartsPerLesson})',
              color: Colors.redAccent,
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  const _Row(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant))),
        Text(value,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
