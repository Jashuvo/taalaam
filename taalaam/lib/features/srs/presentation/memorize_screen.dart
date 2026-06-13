import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import '../../../shared/services/progression_service.dart';
import '../../../shared/widgets/misbaha/ornament_stamp.dart';
import '../../../shared/widgets/misbaha/stat_pill.dart';
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
    _loadEntry();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entry = _entry;
    final inWordBank = _inWordBankMode;

    // Entry not yet loaded
    if (entry == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              border: Border.all(
                  color:
                      isDark ? AppColors.darkOutlineVariant : AppColors.line),
              borderRadius: AppRadius.xlBorder,
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                Text(
                  'আরবিতে লিখুন:',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                Text(
                  entry.meaningBn,
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkOnSurface : AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (entry.transliteration != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.transliteration!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ],
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
            if (entry.grammarNoteBn != null)
              _GrammarNote(note: entry.grammarNoteBn!),
            if (entry.rootLetters != null) ...[
              const SizedBox(height: 8),
              _RootLettersBanner(rootLetters: entry.rootLetters!),
            ],
            if (entry.contextSnippetAr != null ||
                entry.contextSnippetBn != null) ...[
              const SizedBox(height: 8),
              _ContextSnippet(entry: entry),
            ],
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
    final isDark = theme.brightness == Brightness.dark;
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
        Color border;
        if (!checked) {
          bg = isDark ? AppColors.darkCard : Colors.white;
          fg = isDark ? AppColors.darkOnSurface : AppColors.ink;
          border = isDark ? AppColors.darkOutlineVariant : AppColors.line;
        } else if (word == correctAnswer) {
          bg = AppColors.okBg;
          fg = AppColors.okGreen;
          border = AppColors.okGreen;
        } else if (word == selectedWord) {
          bg = AppColors.wrongBgSoft;
          fg = AppColors.wrongRed;
          border = AppColors.wrongRed;
        } else {
          bg = isDark ? AppColors.darkCard : Colors.white;
          fg = (isDark ? AppColors.darkOnSurface : AppColors.ink)
              .withValues(alpha: 0.4);
          border = isDark ? AppColors.darkOutlineVariant : AppColors.line;
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
                color: border,
                width: checked && word == correctAnswer ? 2 : 1.5,
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
            border: OutlineInputBorder(borderRadius: AppRadius.mdBorder),
            filled: checked,
            fillColor: checked
                ? (correct ? AppColors.okBg : AppColors.wrongBgSoft)
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
    final color = correct ? AppColors.okGreen : AppColors.wrongRed;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: correct ? AppColors.okBg : AppColors.wrongBgSoft,
        borderRadius: AppRadius.mdBorder,
      ),
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: color,
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

// ── Grammar note block ────────────────────────────────────────────────────────

class _GrammarNote extends StatelessWidget {
  final String note;
  const _GrammarNote({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 14, color: theme.colorScheme.secondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              note,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Root letters banner ───────────────────────────────────────────────────────

class _RootLettersBanner extends StatelessWidget {
  final String rootLetters;
  const _RootLettersBanner({required this.rootLetters});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_tree_outlined,
              size: 14, color: theme.colorScheme.tertiary),
          const SizedBox(width: 6),
          Text(
            'মূল ধাতু (جذر): ',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
          ),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              rootLetters,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 20,
                height: 1.8,
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.bold,
              ),
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
                  'নতুন শব্দ শেখা শেষ!',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkOnSurface : AppColors.ink,
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
