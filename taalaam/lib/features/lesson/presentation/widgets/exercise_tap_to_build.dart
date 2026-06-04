import 'package:flutter/material.dart';
import '../../../../data/models/vocabulary_model.dart';
import '../../domain/exercise_model.dart';
import 'arabic_word_tooltip.dart';

class ExerciseTapToBuild extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  final Map<String, VocabularyModel> vocabMap;
  const ExerciseTapToBuild(
      {required this.exercise, required this.onAnswered,
       this.vocabMap = const {}, super.key});

  @override
  State<ExerciseTapToBuild> createState() => _ExerciseTapToBuildState();
}

class _ExerciseTapToBuildState extends State<ExerciseTapToBuild> {
  late List<String> _bank;
  final List<String> _built = [];
  bool _answered = false;

  List<String> get _correctWords =>
      List<String>.from(widget.exercise.correctAnswer['words'] as List);
  bool get _orderMatters =>
      widget.exercise.correctAnswer['order_matters'] as bool? ?? true;

  List<String> get _distractorWords {
    final raw = widget.exercise.correctAnswer['distractor_words'];
    if (raw == null) return [];
    return List<String>.from((raw as List).map((e) => e.toString()));
  }

  @override
  void initState() {
    super.initState();
    _bank = [..._correctWords, ..._distractorWords]..shuffle();
  }

  bool _checkAnswer() {
    if (_orderMatters) return _built.join(' ') == _correctWords.join(' ');
    final b = List<String>.from(_built)..sort();
    final c = List<String>.from(_correctWords)..sort();
    return b.join() == c.join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.exercise.promptBn != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(widget.exercise.promptBn!,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
          ),
        // Answer area
        Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _built.map((w) {
                return GestureDetector(
                  onTap: _answered
                      ? null
                      : () => setState(() {
                            _built.remove(w);
                            _bank.add(w);
                          }),
                  child: _WordChip(word: w, active: true,
                      vocabMap: widget.vocabMap),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Word bank
        Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _bank.map((w) {
              return GestureDetector(
                onTap: _answered
                    ? null
                    : () => setState(() {
                          _bank.remove(w);
                          _built.add(w);
                        }),
                child: _WordChip(word: w, active: false,
                    vocabMap: widget.vocabMap),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _answered || _built.isEmpty
              ? null
              : () {
                  setState(() => _answered = true);
                  widget.onAnswered(_checkAnswer());
                },
          child: const Text('যাচাই করুন'),
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  final String word;
  final bool active;
  final Map<String, VocabularyModel> vocabMap;
  const _WordChip({required this.word, required this.active,
      this.vocabMap = const {}});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
      ),
      child: ArabicWordTooltip(
        word: word,
        vocabMap: vocabMap,
        style: TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: 20,
          height: 1.6,
          color: active
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
