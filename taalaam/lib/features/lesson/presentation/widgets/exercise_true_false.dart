import 'package:flutter/material.dart';
import '../../domain/exercise_model.dart';

class ExerciseTrueFalse extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  const ExerciseTrueFalse(
      {required this.exercise, required this.onAnswered, super.key});

  @override
  State<ExerciseTrueFalse> createState() => _ExerciseTrueFalseState();
}

class _ExerciseTrueFalseState extends State<ExerciseTrueFalse> {
  bool? _selected;

  bool get _isTrue =>
      widget.exercise.correctAnswer['is_true'] as bool? ?? true;
  String get _stmtAr =>
      widget.exercise.correctAnswer['statement_ar'] as String? ?? '';
  String get _stmtBn =>
      widget.exercise.correctAnswer['statement_bn'] as String? ?? '';

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
        // Arabic statement
        if (_stmtAr.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                _stmtAr,
                style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic', fontSize: 26, height: 1.8),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        // Bangla translation
        if (_stmtBn.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              _stmtBn,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _TFButton(
                label: '✓ সঠিক',
                color: Colors.green,
                selected: _selected == true,
                onTap: _selected != null
                    ? null
                    : () {
                        setState(() => _selected = true);
                        widget.onAnswered(_isTrue == true);
                      },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TFButton(
                label: '✗ ভুল',
                color: Colors.red,
                selected: _selected == false,
                onTap: _selected != null
                    ? null
                    : () {
                        setState(() => _selected = false);
                        widget.onAnswered(_isTrue == false);
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TFButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;
  const _TFButton(
      {required this.label,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? color : Colors.grey.shade300, width: 2),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: selected ? color : Colors.grey.shade600),
            ),
          ),
        ),
      );
}
