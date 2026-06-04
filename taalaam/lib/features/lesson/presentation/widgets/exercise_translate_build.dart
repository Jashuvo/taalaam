import 'package:flutter/material.dart';
import '../../../../data/models/vocabulary_model.dart';
import '../../domain/exercise_model.dart';
import 'arabic_word_tooltip.dart';

/// "Translate to Bengali" exercise.
/// Shows an Arabic sentence, learner builds Bengali translation by tapping chips.
class ExerciseTranslateBuild extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  final Map<String, VocabularyModel> vocabMap;
  const ExerciseTranslateBuild({
    required this.exercise,
    required this.onAnswered,
    this.vocabMap = const {},
    super.key,
  });

  @override
  State<ExerciseTranslateBuild> createState() => _ExerciseTranslateBuildState();
}

class _ExerciseTranslateBuildState extends State<ExerciseTranslateBuild> {
  late final List<String> _correctWords;
  late final List<String> _bank;
  final List<String> _placed = [];
  late final List<String> _shuffled;

  @override
  void initState() {
    super.initState();
    final ca = widget.exercise.correctAnswer;
    _correctWords = List<String>.from(ca['words'] as List);
    final distractors = List<String>.from(
        (ca['distractor_words'] as List?) ?? []);
    _shuffled = [..._correctWords, ...distractors]..shuffle();
    _bank = [..._shuffled];
  }

  bool get _canCheck => _placed.isNotEmpty;

  bool _isCorrect() {
    if (_placed.length != _correctWords.length) return false;
    return _placed.join(' ') == _correctWords.join(' ');
  }

  void _placeWord(String word) {
    setState(() {
      _bank.remove(word);
      _placed.add(word);
    });
  }

  void _returnWord(int idx) {
    setState(() {
      final w = _placed.removeAt(idx);
      _bank.add(w);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promptAr = widget.exercise.promptAr ?? '';
    final promptBn = widget.exercise.promptBn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Arabic source sentence
        if (promptBn != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(promptBn,
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ),
        if (promptAr.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Center(
              child: ArabicSentenceWithTooltips(
                sentence: promptAr,
                vocabMap: widget.vocabMap,
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 28,
                  height: 1.8,
                ),
              ),
            ),
          ),

        // Answer slots row
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant, width: 2),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (_placed.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'শব্দ বেছে নিন…',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ..._placed.asMap().entries.map((e) => GestureDetector(
                    onTap: () => _returnWord(e.key),
                    child: _Chip(word: e.value, placed: true),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Word bank
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _bank
              .map((w) => GestureDetector(
                    onTap: () => _placeWord(w),
                    child: _Chip(word: w, placed: false),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),

        FilledButton(
          onPressed: _canCheck
              ? () => widget.onAnswered(_isCorrect())
              : null,
          child: const Text('যাচাই করুন'),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String word;
  final bool placed;
  const _Chip({required this.word, required this.placed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: placed
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: placed
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        word,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: placed
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
