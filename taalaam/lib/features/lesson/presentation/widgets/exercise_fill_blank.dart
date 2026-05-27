import 'package:flutter/material.dart';
import '../../domain/exercise_model.dart';

class ExerciseFillBlank extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  const ExerciseFillBlank(
      {required this.exercise, required this.onAnswered, super.key});

  @override
  State<ExerciseFillBlank> createState() => _ExerciseFillBlankState();
}

class _ExerciseFillBlankState extends State<ExerciseFillBlank> {
  int? _selected;

  String get _sentence =>
      widget.exercise.correctAnswer['sentence'] as String;
  String get _answer => widget.exercise.correctAnswer['answer'] as String;

  // Build distractor options: correct answer + up to 3 distractors
  List<String> get _options {
    final opts = <String>[_answer];
    final dist = widget.exercise.distractors;
    if (dist != null && dist['options'] is List) {
      for (final o in dist['options'] as List) {
        if (opts.length >= 4) break;
        final s = o.toString();
        if (s != _answer) opts.add(s);
      }
    }
    opts.shuffle();
    return opts;
  }

  late final List<String> _shuffled = _options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = _sentence.split('___');

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
        // Sentence with blank
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                    fontFamily: 'NotoNaskhArabic', fontSize: 24, height: 1.8,
                    color: theme.colorScheme.onSurface),
                children: [
                  if (parts.isNotEmpty) TextSpan(text: parts[0]),
                  WidgetSpan(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: _selected != null
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.primary),
                      ),
                      child: Text(
                        _selected != null
                            ? _shuffled[_selected!]
                            : '  ?  ',
                        style: const TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 22,
                            height: 1.8),
                      ),
                    ),
                  ),
                  if (parts.length > 1) TextSpan(text: parts[1]),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(_shuffled.length, (i) {
            final picked = _selected == i;
            return GestureDetector(
              onTap: _selected != null
                  ? null
                  : () {
                      setState(() => _selected = i);
                      widget.onAnswered(_shuffled[i] == _answer);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: picked
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: picked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    _shuffled[i],
                    style: const TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 20,
                        height: 1.6),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
