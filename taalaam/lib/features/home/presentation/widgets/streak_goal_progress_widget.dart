import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Dot-calendar showing the last N days toward a streak goal.
/// Filled dots = days with activity (based on current streak).
class StreakGoalProgressWidget extends StatelessWidget {
  final int currentStreak;
  final int streakGoal;

  const StreakGoalProgressWidget({
    super.key,
    required this.currentStreak,
    required this.streakGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = streakGoal > 0
        ? (currentStreak / streakGoal).clamp(0.0, 1.0)
        : 0.0;
    final totalDots = streakGoal.clamp(7, 30);
    final filledDots = currentStreak.clamp(0, totalDots);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentStreak / $streakGoal দিনের ধারা',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.brightGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(AppColors.brightGreen),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: List.generate(totalDots, (i) {
              final filled = i < filledDots;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? AppColors.brightGreen
                      : theme.colorScheme.surfaceContainerHighest,
                  border: filled
                      ? null
                      : Border.all(
                          color: theme.colorScheme.outlineVariant, width: 1),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            currentStreak >= streakGoal
                ? 'লক্ষ্য অর্জিত! অভিনন্দন!'
                : '${streakGoal - currentStreak} দিন বাকি',
            style: theme.textTheme.bodySmall?.copyWith(
              color: currentStreak >= streakGoal
                  ? AppColors.brightGreen
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
