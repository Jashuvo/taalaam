import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/local/database.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/srs_local_source.dart';
import 'srs_provider.dart';

class MemorizeScreen extends ConsumerWidget {
  const MemorizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('মুখস্থ করুন')),
        body: const Center(child: Text('লগইন করুন।')),
      );
    }
    return _MemorizeBody(userId: user.id);
  }
}

class _MemorizeBody extends ConsumerWidget {
  final String userId;
  const _MemorizeBody({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(memorizeSessionProvider(userId));
    final notifier = ref.read(memorizeSessionProvider(userId).notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/home')),
        title: const Text('মুখস্থ করুন'),
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (_) {
          final card = notifier.currentCard;
          if (card == null) {
            return _DoneView(onHome: () => context.go('/home'));
          }
          return _MemorizeCard(card: card, notifier: notifier);
        },
      ),
    );
  }
}

class _MemorizeCard extends ConsumerStatefulWidget {
  final SrsCard card;
  final MemorizeSessionNotifier notifier;
  const _MemorizeCard({required this.card, required this.notifier});

  @override
  ConsumerState<_MemorizeCard> createState() => _MemorizeCardState();
}

class _MemorizeCardState extends ConsumerState<_MemorizeCard> {
  final _ctrl = TextEditingController();
  bool _checked = false;
  bool _correct = false;
  String _correctAnswer = '';

  @override
  void didUpdateWidget(_MemorizeCard old) {
    super.didUpdateWidget(old);
    if (old.card.id != widget.card.id) {
      _ctrl.clear();
      setState(() {
        _checked = false;
        _correct = false;
        _correctAnswer = '';
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final db = ref.read(appDatabaseProvider);
    final entry = await (db.select(db.vocabulary)
          ..where((t) => t.id.equals(widget.card.vocabularyId)))
        .getSingleOrNull();
    if (entry == null) return;

    final input = _ctrl.text.trim().replaceAll(RegExp(r'[ً-ٟ]'), '');
    final correct = (entry.arabic).replaceAll(RegExp(r'[ً-ٟ]'), '');
    final isCorrect = input == correct || entry.arabic.contains(input);

    setState(() {
      _checked = true;
      _correct = isCorrect;
      _correctAnswer = entry.arabic;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = ref.watch(appDatabaseProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder(
        future: (db.select(db.vocabulary)
              ..where((t) => t.id.equals(widget.card.vocabularyId)))
            .getSingleOrNull(),
        builder: (ctx, snap) {
          final entry = snap.data;
          return Column(
            children: [
              // Progress
              Text(
                '${widget.notifier.remaining} টি বাকি',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              // Meaning card (the prompt)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        'আরবিতে লিখুন:',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        entry?.meaningBn ?? '…',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      if (entry?.transliteration != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          entry!.transliteration!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Input
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextField(
                  controller: _ctrl,
                  enabled: !_checked,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'আরবি অক্ষরে লিখুন…',
                    hintTextDirection: TextDirection.ltr,
                    border: const OutlineInputBorder(),
                    filled: _checked,
                    fillColor: _checked
                        ? (_correct
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1))
                        : null,
                  ),
                  style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 24,
                      height: 1.6),
                  onSubmitted: _checked ? null : (_) => _check(),
                ),
              ),
              if (_checked) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _correct
                        ? Colors.green.withValues(alpha: 0.1)
                        : theme.colorScheme.errorContainer
                            .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _correct ? Icons.check_circle : Icons.info_outline,
                        color:
                            _correct ? Colors.green : theme.colorScheme.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _correct ? 'সঠিক!' : 'সঠিক উত্তর:',
                              style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                            if (!_correct)
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  _correctAnswer,
                                  style: const TextStyle(
                                      fontFamily: 'NotoNaskhArabic',
                                      fontSize: 20,
                                      height: 1.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            widget.notifier.rate(_correct ? 3 : 1),
                        child: const Text('পরবর্তী'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _check,
                  child: const Text('যাচাই করুন'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
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
            Text('মুখস্থ সেশন শেষ!',
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

// ── Provider ──────────────────────────────────────────────────────────────────

class MemorizeSessionNotifier
    extends StateNotifier<AsyncValue<List<SrsCard>>> {
  final SrsLocalSource _src;
  final String _userId;
  List<SrsCard> _cards = [];
  int _index = 0;

  MemorizeSessionNotifier(this._src, this._userId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      // Get all cards (not just due) for memorization practice
      final all = await _src.getDueCards(_userId, limit: 30);
      _cards = all;
      _index = 0;
      state = AsyncValue.data(List.unmodifiable(_cards));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  SrsCard? get currentCard =>
      _index < _cards.length ? _cards[_index] : null;
  int get remaining => (_cards.length - _index).clamp(0, _cards.length);

  Future<void> rate(int rating) async {
    final card = currentCard;
    if (card == null) return;
    await _src.reviewCard(card, rating);
    _index++;
    state = AsyncValue.data(List.unmodifiable(_cards));
  }
}

final memorizeSessionProvider = StateNotifierProvider.autoDispose
    .family<MemorizeSessionNotifier, AsyncValue<List<SrsCard>>, String>(
  (ref, userId) => MemorizeSessionNotifier(
    ref.read(srsLocalSourceProvider),
    userId,
  ),
);
