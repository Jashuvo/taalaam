import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

/// Tested exercise: full ayah shown with one word highlighted.
/// Learner picks the correct meaning from 4 options.
class ExerciseAyahContext extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool) onAnswered;

  const ExerciseAyahContext({
    required this.exercise,
    required this.onAnswered,
    super.key,
  });

  @override
  State<ExerciseAyahContext> createState() => _ExerciseAyahContextState();
}

class _ExerciseAyahContextState extends State<ExerciseAyahContext> {
  int? _selected;
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ca = widget.exercise.correctAnswer;
    final ayahAr      = ca['ayah_ar']        as String? ?? '';
    final highlighted = ca['highlighted_word'] as String? ?? '';
    final options     = (ca['options']        as List?)?.cast<String>() ?? [];
    final correctIdx  = ca['correct_index']   as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question
        Text(
          widget.exercise.promptBn ?? 'হাইলাইট করা শব্দটির অর্থ কী?',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // Ayah with highlighted word
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.2)),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: _AyahWithHighlight(
              ayah: ayahAr,
              highlighted: highlighted,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Highlighted word label
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                highlighted,
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 20,
                  height: 1.6,
                  color: Color(0xFF7B4F00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Options
        ...options.asMap().entries.map((e) {
          final idx = e.key;
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          String.fromCharCode(0x41 + idx), // A, B, C, D
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

/// Renders ayah text with one word highlighted in gold.
class _AyahWithHighlight extends StatelessWidget {
  final String ayah;
  final String highlighted;

  const _AyahWithHighlight({required this.ayah, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    if (highlighted.isEmpty || !ayah.contains(highlighted)) {
      return Text(
        ayah,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: 22,
          height: 2.0,
        ),
      );
    }

    final parts = ayah.split(highlighted);
    final spans = <InlineSpan>[];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i]));
      }
      if (i < parts.length - 1) {
        spans.add(TextSpan(
          text: highlighted,
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            backgroundColor: AppColors.gold.withValues(alpha: 0.15),
          ),
        ));
      }
    }

    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: 22,
          height: 2.0,
          color: Color(0xFF1B3A2D),
        ),
        children: spans,
      ),
      textAlign: TextAlign.center,
    );
  }
}
