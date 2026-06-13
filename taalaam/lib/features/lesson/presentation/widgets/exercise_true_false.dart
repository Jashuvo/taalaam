import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/vocabulary_model.dart';
import '../../domain/exercise_model.dart';
import 'arabic_word_tooltip.dart';

class ExerciseTrueFalse extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  final Map<String, VocabularyModel> vocabMap;
  const ExerciseTrueFalse(
      {required this.exercise, required this.onAnswered,
       this.vocabMap = const {}, super.key});

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

  bool get _canCheck => _selected != null;

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
        if (_stmtAr.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: ArabicSentenceWithTooltips(
                sentence: _stmtAr,
                vocabMap: widget.vocabMap,
                style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic', fontSize: 26, height: 1.8),
              ),
            ),
          ),
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
                selected: _selected == true,
                onTap: _selected != null
                    ? null
                    : () => setState(() => _selected = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TFButton(
                label: '✗ ভুল',
                selected: _selected == false,
                onTap: _selected != null
                    ? null
                    : () => setState(() => _selected = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _canCheck
              ? () => widget.onAnswered(_selected == _isTrue)
              : null,
          child: const Text('যাচাই করুন'),
        ),
      ],
    );
  }
}

class _TFButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _TFButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: selected
          ? (isDark
              ? AppColors.darkPrimaryContainer
              : const Color(0xFFEAF4F2))
          : Colors.transparent,
      borderRadius: AppRadius.mdBorder,
      child: InkWell(
        borderRadius: AppRadius.mdBorder,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdBorder,
            border: Border.all(
              color: selected
                  ? AppColors.tealLight
                  : (isDark ? AppColors.darkOutlineVariant : AppColors.line),
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected
                  ? (isDark ? AppColors.darkPrimary : AppColors.teal)
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
