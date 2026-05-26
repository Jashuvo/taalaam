import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/local/database.dart';
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
    final sessionAsync =
        ref.watch(reviewSessionProvider(userId));
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
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (_) {
          final card = notifier.currentCard;
          if (card == null) {
            return _DoneView(onHome: () => context.go('/home'));
          }
          return _CardView(card: card, notifier: notifier);
        },
      ),
    );
  }
}

class _CardView extends StatefulWidget {
  final SrsCard card;
  final ReviewSessionNotifier notifier;
  const _CardView({required this.card, required this.notifier});

  @override
  State<_CardView> createState() => _CardViewState();
}

class _CardViewState extends State<_CardView> {
  bool _flipped = false;

  @override
  void didUpdateWidget(_CardView old) {
    super.didUpdateWidget(old);
    if (old.card.id != widget.card.id) setState(() => _flipped = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flipped = true),
              child: Card(
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
            Text('কতটা মনে ছিল?',
                style: theme.textTheme.titleSmall),
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
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 36,
                    height: 1.6),
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
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }
}

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

class _DoneView extends StatelessWidget {
  final VoidCallback onHome;
  const _DoneView({required this.onHome});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✅', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('আজকের রিভিউ শেষ!',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 8),
            Text('আবার আগামীকাল দেখুন।',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('হোমে ফিরুন'),
              onPressed: onHome,
            ),
          ],
        ),
      ),
    );
  }
}
