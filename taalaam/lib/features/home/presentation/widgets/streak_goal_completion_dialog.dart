import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

Future<void> showStreakGoalCompletionDialog(
    BuildContext context, int goal) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _StreakGoalCompletionDialog(goal: goal),
  );
}

class _StreakGoalCompletionDialog extends StatelessWidget {
  final int goal;
  const _StreakGoalCompletionDialog({required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              'লক্ষ্য অর্জিত!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$goal দিনের ধারা সম্পন্ন করেছেন!\nআল্লাহ আপনার পরিশ্রম কবুল করুন।',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Text(
                '+${50} XP বোনাস!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('চমৎকার!'),
            ),
          ],
        ),
      ),
    );
  }
}
