import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import '../../auth/presentation/auth_provider.dart';

// Returns true if the user has NOT yet set a streak goal (show goal screen once)
final _needsStreakGoalProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final db = ref.watch(appDatabaseProvider);
  final row = await (db.select(db.streaks)
        ..where((t) => t.userId.equals(user.id)))
      .getSingleOrNull();
  return row?.streakGoal == null;
});

// Finds the next lesson after the current one within the same unit,
// then falls back to the first lesson of the next unit.
final _nextLessonProvider =
    FutureProvider.family<Lesson?, _NextLessonArgs>((ref, args) async {
  final db = ref.watch(appDatabaseProvider);

  // Next lesson in same unit
  final siblings = await (db.select(db.lessons)
        ..where((t) => t.unitId.equals(args.unitId))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)]))
      .get();

  final currentIdx = siblings.indexWhere((l) => l.id == args.lessonId);
  if (currentIdx != -1 && currentIdx + 1 < siblings.length) {
    return siblings[currentIdx + 1];
  }

  // First lesson of the next unit in same track
  final currentUnit = await (db.select(db.units)
        ..where((t) => t.id.equals(args.unitId)))
      .getSingleOrNull();
  if (currentUnit == null) return null;

  final nextUnits = await (db.select(db.units)
        ..where((t) =>
            t.trackId.equals(currentUnit.trackId) &
            t.sortOrder.isBiggerThanValue(currentUnit.sortOrder))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)])
        ..limit(1))
      .get();
  if (nextUnits.isEmpty) return null;

  final firstOfNext = await (db.select(db.lessons)
        ..where((t) => t.unitId.equals(nextUnits.first.id))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)])
        ..limit(1))
      .get();
  return firstOfNext.isEmpty ? null : firstOfNext.first;
});

class _NextLessonArgs {
  final String lessonId;
  final String unitId;
  const _NextLessonArgs(this.lessonId, this.unitId);
  @override
  bool operator ==(Object o) =>
      o is _NextLessonArgs && o.lessonId == lessonId && o.unitId == unitId;
  @override
  int get hashCode => Object.hash(lessonId, unitId);
}

class LessonCompleteScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final String unitId;
  final int correctCount;
  final int totalCount;
  final int xpEarned;
  final int gemReward;
  final int perfectBonus;
  final int firstDayBonus;
  final int totalXpAfter;
  final String? weakHint;

  const LessonCompleteScreen({
    required this.lessonId,
    required this.unitId,
    required this.correctCount,
    required this.totalCount,
    required this.xpEarned,
    this.gemReward = 0,
    this.perfectBonus = 0,
    this.firstDayBonus = 0,
    this.totalXpAfter = 0,
    this.weakHint,
    super.key,
  });

  @override
  ConsumerState<LessonCompleteScreen> createState() =>
      _LessonCompleteScreenState();
}

class _LessonCompleteScreenState extends ConsumerState<LessonCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _fadeIn;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _fadeIn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeIn, curve: Curves.easeOut);
    // Start confetti + fade in after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      _fadeIn.forward();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _fadeIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nextLesson = ref
        .watch(_nextLessonProvider(
            _NextLessonArgs(widget.lessonId, widget.unitId)))
        .valueOrNull;
    final needsStreakGoal =
        ref.watch(_needsStreakGoalProvider).valueOrNull ?? false;
    final pct =
        widget.totalCount > 0
            ? (widget.correctCount / widget.totalCount * 100).round()
            : 0;
    final duaa = AppConstants
        .completionDuaas[Random().nextInt(AppConstants.completionDuaas.length)];
    final parts = duaa.split(' — ');

    return Scaffold(
      body: Stack(
        children: [
          // ── Confetti emitter centred at top ───────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.2,
              emissionFrequency: 0.05,
              colors: const [
                AppColors.brightGreen,
                AppColors.gold,
                AppColors.teal,
                Colors.white,
                Color(0xFF81C784),
              ],
            ),
          ),
          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Center(
                          child: Image.asset(
                            isDark
                                ? 'assets/logo_dark-removebg-preview.png'
                                : 'assets/logo_light-removebg-preview.png',
                            height: 130,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'পাঠ সম্পন্ন!',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        // Stats card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(
                                color: theme.colorScheme.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              _StatRow(
                                icon: Icons.stars_rounded,
                                label: 'XP অর্জিত',
                                value: '+${widget.xpEarned} XP',
                                color: AppColors.gold,
                              ),
                              if (widget.perfectBonus > 0) ...[
                                const Divider(height: 20),
                                _StatRow(
                                  icon: Icons.workspace_premium_rounded,
                                  label: 'পারফেক্ট বোনাস',
                                  value: '+${widget.perfectBonus} XP',
                                  color: AppColors.gold,
                                ),
                              ],
                              if (widget.firstDayBonus > 0) ...[
                                const Divider(height: 20),
                                _StatRow(
                                  icon: Icons.wb_sunny_rounded,
                                  label: 'প্রথম পাঠ বোনাস',
                                  value: '+${widget.firstDayBonus} XP',
                                  color: AppColors.brightGreen,
                                ),
                              ],
                              if (widget.gemReward > 0) ...[
                                const Divider(height: 20),
                                _StatRow(
                                  icon: Icons.diamond_outlined,
                                  label: 'রত্ন অর্জিত',
                                  value: '+${widget.gemReward} 💎',
                                  color: AppColors.teal,
                                ),
                              ],
                              const Divider(height: 20),
                              _StatRow(
                                icon: Icons.check_circle_outline_rounded,
                                label: 'নির্ভুলতা',
                                value: '$pct%',
                                color: pct >= 80
                                    ? AppColors.correctBg
                                    : theme.colorScheme.error,
                              ),
                              const Divider(height: 20),
                              _StatRow(
                                icon: Icons.quiz_outlined,
                                label: 'সঠিক উত্তর',
                                value:
                                    '${widget.correctCount} / ${widget.totalCount}',
                                color: theme.colorScheme.primary,
                              ),
                              if (widget.totalXpAfter > 0) ...[
                                const Divider(height: 20),
                                _StatRow(
                                  icon: Icons.trending_up_rounded,
                                  label: 'মোট XP',
                                  value: '${widget.totalXpAfter} XP',
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.weakHint != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: AppRadius.lgBorder,
                              border: Border.all(
                                  color: theme.colorScheme.error
                                      .withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb_outline_rounded,
                                    color: theme.colorScheme.error, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.weakHint!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Du'aa
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.25),
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.2)),
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
                        const SizedBox(height: 28),
                        if (nextLesson != null) ...[
                          FilledButton.icon(
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text('পরবর্তী: ${nextLesson.titleBn}',
                                overflow: TextOverflow.ellipsis),
                            onPressed: () =>
                                context.go('/lesson/${nextLesson.id}'),
                          ),
                          const SizedBox(height: 10),
                        ],
                        FilledButton.icon(
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('হোমে ফিরুন'),
                          style: nextLesson != null
                              ? FilledButton.styleFrom(
                                  backgroundColor: theme
                                      .colorScheme.surfaceContainerHighest,
                                  foregroundColor:
                                      theme.colorScheme.onSurface)
                              : null,
                          onPressed: () => context.go(
                              needsStreakGoal ? '/streak-goal' : '/home'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('আজকের রিভিউ করুন'),
                          onPressed: () => context.go('/review'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
