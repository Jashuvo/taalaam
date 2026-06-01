import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

class ExerciseMultipleChoice extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  const ExerciseMultipleChoice(
      {required this.exercise, required this.onAnswered, super.key});

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
    // Identify correct answer by VALUE so shuffle doesn't break the answer
    final raw = List<String>.from(
        widget.exercise.correctAnswer['options'] as List);
    final correctAnswer =
        raw[widget.exercise.correctAnswer['correct_index'] as int];
    raw.shuffle();
    _options = raw;
    _correctIdx = raw.indexOf(correctAnswer);
  }

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
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                widget.exercise.promptAr!,
                style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic', fontSize: 26, height: 1.8),
                textAlign: TextAlign.center,
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
          // Staggered slide-in animation per option
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
                      : () {
                          setState(() => _selected = i);
                          widget.onAnswered(i == _correctIdx);
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        _options[i],
                        style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 20,
                            height: 1.8,
                            color: textColor ?? theme.colorScheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
