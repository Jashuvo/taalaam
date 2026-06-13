import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

/// Informational card: shows a full Quranic ayah with Bengali translation.
/// Always "correct" — learner reads and taps Continue.
class ExerciseAyahRead extends StatelessWidget {
  final ExerciseModel exercise;
  final void Function(bool) onAnswered;

  const ExerciseAyahRead({
    required this.exercise,
    required this.onAnswered,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ca = exercise.correctAnswer;
    final ayahAr    = ca['ayah_ar']   as String? ?? '';
    final ayahBn    = ca['ayah_bn']   as String? ?? '';
    final surahName = ca['surah_name'] as String? ?? '';
    final ayahNum   = ca['ayah_number'] as int?;
    final contextBn = ca['context_bn'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Surah + ayah number chip
        Row(
          children: [
            _Badge(
              label: surahName,
              color: AppColors.forestGreen,
              icon: Icons.menu_book_rounded,
            ),
            if (ayahNum != null) ...[
              const SizedBox(width: 8),
              _Badge(
                label: 'আয়াত $ayahNum',
                color: AppColors.gold,
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // Arabic ayah text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.forestGreen.withValues(alpha: 0.25),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              ayahAr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 26,
                height: 2.0,
                color: AppColors.forestGreen,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Bengali translation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            ayahBn,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.6,
            ),
          ),
        ),

        // Context note (salah position, aqeedah context, etc.)
        if (contextBn.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contextBn,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.gold.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
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
            backgroundColor: AppColors.forestGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.check_rounded, size: 20),
          label: const Text('পড়লাম', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
