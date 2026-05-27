import 'package:flutter/material.dart';
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

  List<String> get _options =>
      List<String>.from(widget.exercise.correctAnswer['options'] as List);
  int get _correctIndex =>
      widget.exercise.correctAnswer['correct_index'] as int;

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
          final correct = i == _correctIndex;
          Color? tileColor;
          Color? textColor;
          if (_selected != null) {
            if (correct) {
              tileColor = Colors.green.shade100;
              textColor = Colors.green.shade900;
            } else if (selected) {
              tileColor = Colors.red.shade100;
              textColor = Colors.red.shade900;
            }
          }
          return Padding(
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
                        widget.onAnswered(i == _correctIndex);
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
          );
        }),
      ],
    );
  }
}
