import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../features/home/presentation/home_provider.dart';

void showProgressShareDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const Dialog(
      child: _ShareCardDialog(),
    ),
  );
}

class _ShareCardDialog extends ConsumerWidget {
  const _ShareCardDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.share_outlined, size: 18),
                const SizedBox(width: 8),
                Text('অগ্রগতি শেয়ার করুন',
                    style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: streak.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('ডেটা লোড হয়নি।'),
              data: (s) => _ShareCard(
                currentStreak: s?.currentStreak ?? 0,
                totalXp: s?.totalXp ?? 0,
                longestStreak: s?.longestStreak ?? 0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Text(
              'স্ক্রিনশট নিয়ে শেয়ার করুন',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final int currentStreak;
  final int totalXp;
  final int longestStreak;
  const _ShareCard({
    required this.currentStreak,
    required this.totalXp,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duaa = AppConstants
        .completionDuaas[Random().nextInt(AppConstants.completionDuaas.length)];
    final parts = duaa.split(' — ');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
            theme.colorScheme.tertiary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App name
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'تعلَّم',
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 32,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            'Sahih Arabic Learning',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBox(
                  label: 'ধারা', value: '$currentStreak দিন', emoji: '🔥'),
              _StatBox(
                  label: 'মোট XP', value: '$totalXp', emoji: '⭐'),
              _StatBox(
                  label: 'সর্বোচ্চ', value: '$longestStreak দিন', emoji: '🏆'),
            ],
          ),
          const SizedBox(height: 20),
          // Du'aa
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
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
                        fontSize: 16,
                        height: 1.8,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (parts.length > 1)
                  Text(
                    parts[1],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  const _StatBox(
      {required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
        ),
      ],
    );
  }
}
