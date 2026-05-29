import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class LessonCompleteScreen extends StatelessWidget {
  final int correctCount;
  final int totalCount;
  final int xpEarned;

  const LessonCompleteScreen({
    required this.correctCount,
    required this.totalCount,
    required this.xpEarned,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = totalCount > 0 ? (correctCount / totalCount * 100).round() : 0;
    final duaa = AppConstants
        .completionDuaas[Random().nextInt(AppConstants.completionDuaas.length)];
    final parts = duaa.split(' — ');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Builder(builder: (ctx) {
                    final isDark = Theme.of(ctx).brightness == Brightness.dark;
                    return Image.asset(
                      isDark
                          ? 'assets/logo_dark-removebg-preview.png'
                          : 'assets/logo_light-removebg-preview.png',
                      height: 140,
                    );
                  }),
                  const SizedBox(height: 16),
                  Text(
                    'পাঠ সম্পন্ন!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _StatRow(
                    icon: Icons.stars,
                    label: 'XP অর্জিত',
                    value: '+$xpEarned XP',
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    icon: Icons.check_circle_outline,
                    label: 'নির্ভুলতা',
                    value: '$pct%',
                    color: pct >= 80
                        ? AppColors.correctBg
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    icon: Icons.quiz_outlined,
                    label: 'সঠিক উত্তর',
                    value: '$correctCount / $totalCount',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  // Du'aa
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (parts.isNotEmpty)
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              parts[0],
                              style: const TextStyle(
                                fontFamily: 'NotoNaskhArabic',
                                fontSize: 22,
                                height: 1.8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (parts.length > 1) ...[
                          const SizedBox(height: 4),
                          Text(
                            parts[1],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    icon: const Icon(Icons.home),
                    label: const Text('হোমে ফিরুন'),
                    onPressed: () => context.go('/home'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('আজকের রিভিউ করুন'),
                    onPressed: () => context.go('/review'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyLarge),
        const Spacer(),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
