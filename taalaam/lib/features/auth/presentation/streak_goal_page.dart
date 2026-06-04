import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import 'auth_provider.dart';

class StreakGoalPage extends ConsumerStatefulWidget {
  const StreakGoalPage({super.key});

  @override
  ConsumerState<StreakGoalPage> createState() => _StreakGoalPageState();
}

class _StreakGoalPageState extends ConsumerState<StreakGoalPage> {
  int _selected = 7;
  bool _saving = false;

  static const _goals = [
    (7,  'সহজ',     'প্রতিদিন একটু একটু করে শিখুন'),
    (14, 'ভালো',    'নিয়মিত অভ্যাস তৈরি করুন'),
    (30, 'দারুণ',   'শেখার গতি বাড়ান'),
    (50, 'অসাধারণ', 'লক্ষ্য স্থির রাখুন'),
  ];

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final db = ref.read(appDatabaseProvider);
        await (db.update(db.streaks)
              ..where((t) => t.userId.equals(user.id)))
            .write(StreaksCompanion(streakGoal: drift.Value(_selected)));
        Supabase.instance.client.from('streaks').upsert({
          'user_id': user.id,
          'streak_goal': _selected,
        }, onConflict: 'user_id').then((_) {}).catchError((_) {});
      }
    } finally {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  Text(
                    'আপনার লক্ষ্য নির্ধারণ করুন',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'নিয়মিত অভ্যাস আপনাকে কোর্স সম্পন্ন করতে ২× বেশি সাহায্য করে!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ..._goals.map((g) {
                    final (days, label, desc) = g;
                    final isSelected = _selected == days;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = days),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.teal.withValues(alpha: 0.12)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.teal
                                  : theme.colorScheme.outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$days দিনের ধারা',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.teal
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      desc,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.teal
                                      : theme.colorScheme.outline
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('শুরু করি!'),
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
