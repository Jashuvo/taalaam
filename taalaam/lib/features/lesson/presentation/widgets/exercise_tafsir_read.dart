import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

/// Informational card: surah overview with revelation context, theme, aqeedah point, tafsir.
/// Always "correct" — learner reads and taps Continue.
class ExerciseTafsirRead extends StatelessWidget {
  final ExerciseModel exercise;
  final void Function(bool) onAnswered;

  const ExerciseTafsirRead({
    required this.exercise,
    required this.onAnswered,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ca = exercise.correctAnswer;
    final surahName  = ca['surah_name']  as String? ?? '';
    final revelation = ca['revelation']  as String? ?? '';
    final themeBn    = ca['theme_bn']    as String? ?? '';
    final aqeedahBn  = ca['aqeedah_bn']  as String? ?? '';
    final tafsirBn   = ca['tafsir_bn']   as String? ?? '';

    final isRevelationMakki = revelation.contains('মাক্কী') || revelation.toLowerCase().contains('makki');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: surah name + revelation badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 12, color: AppColors.forestGreen),
                  const SizedBox(width: 4),
                  Text(
                    surahName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ],
              ),
            ),
            if (revelation.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isRevelationMakki ? Colors.deepOrange : Colors.teal)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isRevelationMakki ? Colors.deepOrange : Colors.teal)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  revelation,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isRevelationMakki ? Colors.deepOrange : Colors.teal,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Theme card
        if (themeBn.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.topic_outlined,
            label: 'মূল বিষয়',
            value: themeBn,
            color: AppColors.forestGreen,
            theme: theme,
          ),
          const SizedBox(height: 10),
        ],

        // Aqeedah point
        if (aqeedahBn.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                    const SizedBox(width: 6),
                    Text(
                      'আকীদার শিক্ষা',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  aqeedahBn,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Tafsir excerpt
        if (tafsirBn.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'তাফসীর',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tafsirBn,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),

        FilledButton.icon(
          onPressed: () => onAnswered(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.forestGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.check_rounded, size: 20),
          label: const Text('বুঝলাম', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
