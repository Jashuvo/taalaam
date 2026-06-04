import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/vocabulary_model.dart';
import '../../domain/exercise_model.dart';
import 'arabic_word_tooltip.dart';

class ExerciseMultipleChoice extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  final Map<String, VocabularyModel> vocabMap;
  const ExerciseMultipleChoice(
      {required this.exercise, required this.onAnswered,
       this.vocabMap = const {}, super.key});

  @override
  State<ExerciseMultipleChoice> createState() =>
      _ExerciseMultipleChoiceState();
}

class _ExerciseMultipleChoiceState extends State<ExerciseMultipleChoice> {
  int? _selected;
  late final List<String> _options;
  late final int _correctIdx;

  @override
  void initState() {
    super.initState();
    final raw = List<String>.from(
        widget.exercise.correctAnswer['options'] as List);
    final correctAnswer =
        raw[widget.exercise.correctAnswer['correct_index'] as int];
    raw.shuffle();
    _options = raw;
    _correctIdx = raw.indexOf(correctAnswer);
  }

  bool get _canCheck => _selected != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.exercise.promptBn != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              widget.exercise.promptBn!,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        if (widget.exercise.promptAr != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Center(
              child: ArabicSentenceWithTooltips(
                sentence: widget.exercise.promptAr!,
                vocabMap: widget.vocabMap,
                style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic', fontSize: 26, height: 1.8),
              ),
            ),
          ),
        ...List.generate(_options.length, (i) {
          final selected = _selected == i;
          final correct = i == _correctIdx;
          Color? tileColor;
          Color? textColor;
          if (_selected != null) {
            if (correct) {
              tileColor = AppColors.correctTile.withValues(alpha: 0.15);
              textColor = AppColors.correctBg;
            } else if (selected) {
              tileColor = AppColors.wrongTile.withValues(alpha: 0.15);
              textColor = AppColors.wrongBg;
            }
          }
          return TweenAnimationBuilder<double>(
            key: ValueKey(i),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 180 + i * 60),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - value)),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: tileColor ?? theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _selected != null
                      ? null
                      : () => setState(() => _selected = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: ArabicWordTooltip(
                      word: _options[i],
                      vocabMap: widget.vocabMap,
                      style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 20,
                          height: 1.8,
                          color: textColor ?? theme.colorScheme.onSurface),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _canCheck
              ? () => widget.onAnswered(_selected == _correctIdx)
              : null,
          child: const Text('যাচাই করুন'),
        ),
      ],
    );
  }
}
