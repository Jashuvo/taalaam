import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

/// Tested exercise: multiple choice about a surah's main theme/message.
class ExerciseSurahTheme extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool) onAnswered;

  const ExerciseSurahTheme({
    required this.exercise,
    required this.onAnswered,
    super.key,
  });

  @override
  State<ExerciseSurahTheme> createState() => _ExerciseSurahThemeState();
}

class _ExerciseSurahThemeState extends State<ExerciseSurahTheme> {
  int? _selected;
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ca = widget.exercise.correctAnswer;
    final options    = (ca['options']       as List?)?.cast<String>() ?? [];
    final correctIdx = ca['correct_index']  as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Surah icon + question
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(Icons.menu_book_rounded, size: 36, color: AppColors.forestGreen),
              const SizedBox(height: 12),
              Text(
                widget.exercise.promptBn ?? 'এই সূরার প্রধান বিষয় কী?',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Options
        ...options.asMap().entries.map((e) {
          final idx  = e.key;
          final text = e.value;
          Color? bg;
          Color? border;
          if (_answered) {
            if (idx == correctIdx) {
              bg     = AppColors.correctBg.withValues(alpha: 0.12);
              border = AppColors.correctBg;
            } else if (idx == _selected) {
              bg     = AppColors.wrongBg.withValues(alpha: 0.12);
              border = AppColors.wrongBg;
            }
          } else if (_selected == idx) {
            bg     = theme.colorScheme.primaryContainer;
            border = theme.colorScheme.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: _answered ? null : () => setState(() => _selected = idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: bg ?? theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: border ?? theme.colorScheme.outline.withValues(alpha: 0.4),
                    width: border != null ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selected == idx && !_answered
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(0x41 + idx),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selected == idx && !_answered
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: _selected == idx ? FontWeight.w600 : null,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (_answered && idx == correctIdx)
                      Icon(Icons.check_circle_rounded, color: AppColors.correctBg, size: 20),
                    if (_answered && idx == _selected && idx != correctIdx)
                      Icon(Icons.cancel_rounded, color: AppColors.wrongBg, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),

        FilledButton(
          onPressed: _selected == null || _answered
              ? null
              : () {
                  setState(() => _answered = true);
                  widget.onAnswered(_selected == correctIdx);
                },
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('উত্তর দিন', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
