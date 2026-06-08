import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

/// Informational card: tadabbur (reflection) prompt with a scholarly note.
/// Always "correct" — learner reflects and taps Continue.
class ExerciseReflectionCard extends StatelessWidget {
  final ExerciseModel exercise;
  final void Function(bool) onAnswered;

  const ExerciseReflectionCard({
    required this.exercise,
    required this.onAnswered,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ca = exercise.correctAnswer;
    final reflectionPrompt = ca['reflection_prompt'] as String? ?? '';
    final scholarlyNote    = ca['scholarly_note_bn'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology_outlined, size: 13, color: AppColors.gold),
                  const SizedBox(width: 5),
                  Text(
                    'তাদাব্বুর',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Reflection prompt
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gold.withValues(alpha: 0.12),
                AppColors.gold.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.format_quote_rounded, size: 28, color: AppColors.gold.withValues(alpha: 0.6)),
              const SizedBox(height: 10),
              Text(
                reflectionPrompt,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        // Scholarly note (Ibn Uthaymin or similar)
        if (scholarlyNote.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    scholarlyNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),

        FilledButton.icon(
          onPressed: () => onAnswered(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.favorite_rounded, size: 18),
          label: const Text('চিন্তা করলাম', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
