import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import '../../../shared/services/progression_service.dart';
import '../../auth/presentation/auth_provider.dart';
import 'srs_provider.dart';

// ── Stability threshold below which word-bank mode is default ─────────────────
const _kWordBankStabilityThreshold = 2.0;
const _kWordBankRepsThreshold = 3;

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
            return _MemorizeDoneView(
              reward: notifier.reward,
              onHome: () => context.go('/home'),
            );
          }
          return _MemorizeCard(
            key: ValueKey(card.id),
            card: card,
            notifier: notifier,
          );
        },
      ),
    );
  }
}

// ── Card widget ───────────────────────────────────────────────────────────────

class _MemorizeCard extends ConsumerStatefulWidget {
  final SrsCard card;
  final MemorizeSessionNotifier notifier;
  const _MemorizeCard(
      {required this.card, required this.notifier, super.key});

  @override
  ConsumerState<_MemorizeCard> createState() => _MemorizeCardState();
}

class _MemorizeCardState extends ConsumerState<_MemorizeCard> {
  final _ctrl = TextEditingController();
  bool _checked = false;
  bool _correct = false;
  String _correctAnswer = '';
  VocabEntry? _entry;

  // Feature 2 — input mode
  bool _useWordBank = false;
  bool _userOverride = false;
  String? _selectedWord;
  List<String> _wordChoices = [];

  @override
  void initState() {
    super.initState();
    _useWordBank = widget.card.stability < _kWordBankStabilityThreshold ||
        widget.card.reps < _kWordBankRepsThreshold;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _inWordBankMode => _userOverride ? !_useWordBank : _useWordBank;

  void _toggleMode() => setState(() => _userOverride = !_userOverride);

  Future<void> _loadEntry() async {
    final db = ref.read(appDatabaseProvider);
    final entry = await (db.select(db.vocabulary)
          ..where((t) => t.id.equals(widget.card.vocabularyId)))
        .getSingleOrNull();
    if (!mounted) return;
    setState(() => _entry = entry);
    if (_inWordBankMode && entry != null) {
      await _buildWordChoices(entry);
    }
  }

  Future<void> _buildWordChoices(VocabEntry entry) async {
    final db = ref.read(appDatabaseProvider);
    final distractorIds =
        widget.notifier.distractorVocabIds(entry.id);
    final distractors = await Future.wait(
      distractorIds.map((id) => (db.select(db.vocabulary)
                ..where((t) => t.id.equals(id)))
            .getSingleOrNull()),
    );
    final choices = [
      entry.arabic,
      ...distractors
          .where((v) => v != null && v.arabic != entry.arabic)
          .take(3)
          .map((v) => v!.arabic),
    ]..shuffle();
    if (mounted) setState(() => _wordChoices = choices);
  }

  void _tapWordChoice(String word) {
    if (_checked) return;
    final entry = _entry;
    if (entry == null) return;
    final stripped = RegExp(r'[ً-ٟ]');
    final isCorrect =
        word.replaceAll(stripped, '') == entry.arabic.replaceAll(stripped, '');
    setState(() {
      _selectedWord = word;
      _checked = true;
      _correct = isCorrect;
      _correctAnswer = entry.arabic;
    });
  }

  Future<void> _checkKeyboard() async {
    final entry = _entry;
    if (entry == null) return;
    final input = _ctrl.text.trim().replaceAll(RegExp(r'[ً-ٟ]'), '');
    final correct = entry.arabic.replaceAll(RegExp(r'[ً-ٟ]'), '');
    final isCorrect = input == correct || entry.arabic.contains(input);
    setState(() {
      _checked = true;
      _correct = isCorrect;
      _correctAnswer = entry.arabic;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_entry == null) {
      _loadEntry();
    }

    final theme = Theme.of(context);
    final entry = _entry;
    final inWordBank = _inWordBankMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Progress row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.notifier.remaining} টি বাকি',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              _StabilityPill(card: widget.card),
            ],
          ),
          const SizedBox(height: 16),

          // ── Prompt card (Bangla meaning → write Arabic)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Text(
                    'আরবিতে লিখুন:',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    entry?.meaningBn ?? '…',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (entry?.transliteration != null) ...[
                    const SizedBox(height: 6),
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
          const SizedBox(height: 20),

          // ── Mode toggle row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                inWordBank ? 'শব্দ নির্বাচন' : 'কীবোর্ড',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _checked ? null : _toggleMode,
                child: Icon(
                  inWordBank ? Icons.grid_view_rounded : Icons.keyboard_rounded,
                  size: 20,
                  color: _checked
                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Input area (STATE A or B)
          if (inWordBank)
            _WordBankInput(
              choices: _wordChoices,
              selectedWord: _selectedWord,
              correct: _correct,
              checked: _checked,
              correctAnswer: _correctAnswer,
              onTap: _tapWordChoice,
            )
          else
            _KeyboardInput(
              ctrl: _ctrl,
              checked: _checked,
              correct: _correct,
              correctAnswer: _correctAnswer,
              onSubmit: _checkKeyboard,
            ),

          // ── Feedback / action row
          const SizedBox(height: 20),
          if (_checked) ...[
            _FeedbackBanner(correct: _correct, correctAnswer: _correctAnswer),
            const SizedBox(height: 14),
            // Feature 3: context snippet revealed on answer
            if (entry?.contextSnippetAr != null ||
                entry?.contextSnippetBn != null)
              _ContextSnippet(entry: entry!),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => widget.notifier.rate(_correct ? 3 : 1),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('পরবর্তী'),
            ),
          ] else ...[
            if (!inWordBank)
              FilledButton(
                onPressed: _checkKeyboard,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('যাচাই করুন'),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Word-bank input (STATE A) ─────────────────────────────────────────────────

class _WordBankInput extends StatelessWidget {
  final List<String> choices;
  final String? selectedWord;
  final bool correct;
  final bool checked;
  final String correctAnswer;
  final ValueChanged<String> onTap;

  const _WordBankInput({
    required this.choices,
    required this.selectedWord,
    required this.correct,
    required this.checked,
    required this.correctAnswer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (choices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: choices.map((word) {
        Color bg;
        Color fg;
        if (!checked) {
          bg = theme.colorScheme.surfaceContainerHighest;
          fg = theme.colorScheme.onSurface;
        } else if (word == correctAnswer) {
          bg = AppColors.brightGreen.withValues(alpha: 0.15);
          fg = AppColors.brightGreen;
        } else if (word == selectedWord) {
          bg = theme.colorScheme.errorContainer;
          fg = theme.colorScheme.onErrorContainer;
        } else {
          bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
          fg = theme.colorScheme.onSurface.withValues(alpha: 0.4);
        }

        return GestureDetector(
          onTap: checked ? null : () => onTap(word),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: checked && word == correctAnswer
                    ? AppColors.brightGreen
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: checked && word == correctAnswer ? 2 : 1,
              ),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                word,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 22,
                  height: 1.6,
                  color: fg,
                  fontWeight: checked && word == correctAnswer
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Keyboard input (STATE B) ──────────────────────────────────────────────────

class _KeyboardInput extends StatelessWidget {
  final TextEditingController ctrl;
  final bool checked;
  final bool correct;
  final String correctAnswer;
  final VoidCallback onSubmit;

  const _KeyboardInput({
    required this.ctrl,
    required this.checked,
    required this.correct,
    required this.correctAnswer,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: TextField(
          controller: ctrl,
          enabled: !checked,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'আরবি অক্ষরে লিখুন…',
            hintTextDirection: TextDirection.ltr,
            border: const OutlineInputBorder(),
            filled: checked,
            fillColor: checked
                ? (correct
                    ? AppColors.brightGreen.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1))
                : null,
          ),
          style: const TextStyle(
              fontFamily: 'NotoNaskhArabic', fontSize: 24, height: 1.6),
          onSubmitted: checked ? null : (_) => onSubmit(),
        ),
      );
}

// ── Feedback banner ───────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final bool correct;
  final String correctAnswer;
  const _FeedbackBanner(
      {required this.correct, required this.correctAnswer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: correct
            ? AppColors.brightGreen.withValues(alpha: 0.1)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: correct ? AppColors.brightGreen : theme.colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? 'সঠিক!' : 'সঠিক উত্তর:',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (!correct)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      correctAnswer,
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
    );
  }
}

// ── Context snippet block (Feature 3) ────────────────────────────────────────

class _ContextSnippet extends StatelessWidget {
  final VocabEntry entry;
  const _ContextSnippet({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }
}

// ── Stability chip ────────────────────────────────────────────────────────────

class _StabilityPill extends StatelessWidget {
  final SrsCard card;
  const _StabilityPill({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew = card.reps == 0;
    final isLearning = card.stability < _kWordBankStabilityThreshold;
    final label = isNew
        ? 'নতুন'
        : isLearning
            ? 'শেখা হচ্ছে'
            : 'স্মরণে আছে';
    final color = isNew
        ? theme.colorScheme.primary
        : isLearning
            ? Colors.orange.shade700
            : AppColors.brightGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: theme.textTheme.labelSmall?.copyWith(color: color)),
    );
  }
}

// ── Done / reward screen (Feature 1) ─────────────────────────────────────────

class _MemorizeDoneView extends StatefulWidget {
  final SrsReward? reward;
  final VoidCallback onHome;
  const _MemorizeDoneView({required this.reward, required this.onHome});

  @override
  State<_MemorizeDoneView> createState() => _MemorizeDoneViewState();
}

class _MemorizeDoneViewState extends State<_MemorizeDoneView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
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
                const Text('🌙', style: TextStyle(fontSize: 64),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text('মুখস্থ সেশন শেষ!',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: theme.colorScheme.primary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (reward != null) ...[
                  _RewardCard(reward: reward),
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

// ── Shared reward card ────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final SrsReward reward;
  const _RewardCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _RewardRow(
            icon: '⭐',
            label: 'অর্জিত XP',
            value: '+${reward.xp} XP',
            color: AppColors.gold,
          ),
          const Divider(height: 20),
          _RewardRow(
            icon: '🔥',
            label: 'ধারাবাহিকতা',
            value: '${reward.streakDays} দিন',
            color: Colors.orangeAccent,
          ),
          if (reward.heartGained) ...[
            const Divider(height: 20),
            _RewardRow(
              icon: '❤️',
              label: 'হার্ট পুনরুদ্ধার',
              value: '+১ (${reward.newHearts}/${AppConstants.heartsPerLesson})',
              color: Colors.redAccent,
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  const _RewardRow(
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
