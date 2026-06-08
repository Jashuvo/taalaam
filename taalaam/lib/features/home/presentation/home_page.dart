import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import '../../../shared/services/gamification_service.dart';
import '../../../shared/utils/xp_level.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/onboarding_page.dart';
import '../../../shared/widgets/progress_share_card.dart';
import 'home_provider.dart';
import 'widgets/streak_goal_completion_dialog.dart';
import 'widgets/streak_goal_progress_widget.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(onboardingDoneProvider, (_, next) {
      if (next.valueOrNull == false && context.mounted) {
        context.go('/onboarding');
      }
    });
    final user = ref.watch(currentUserProvider);
    // Show streak goal completion dialog once when goal is reached.
    ref.listen<AsyncValue<Streak?>>(streakProvider, (_, next) {
      final streakData = next.valueOrNull;
      final userId = user?.id;
      if (streakData == null || userId == null) return;
      final goal = streakData.streakGoal;
      if (goal == null) return;
      GamificationService.claimGoalRewardIfDue(
              userId, streakData.currentStreak, goal)
          .then((awarded) {
        if (awarded && context.mounted) {
          showStreakGoalCompletionDialog(context, goal);
        }
      });
    });
    final tracks = ref.watch(tracksProvider);
    final streak = ref.watch(streakProvider);
    final dueCount = ref.watch(dueCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Builder(builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Image.asset(
            isDark
                ? 'assets/logo_dark-removebg-preview.png'
                : 'assets/logo_light-removebg-preview.png',
            height: 44,
          );
        }),
        centerTitle: false,
        actions: [
          dueCount.when(
            data: (count) => count > 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: IconButton(
                      tooltip: '$count টি রিভিউ বাকি',
                      icon: Badge(
                        label: Text('$count'),
                        child: const Icon(Icons.refresh),
                      ),
                      onPressed: () => context.push('/review'),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'অগ্রগতি শেয়ার করুন',
            onPressed: () => showProgressShareDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'র‍্যাংকিং',
            onPressed: () => context.push('/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'সেটিংস',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'প্রোফাইল',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final sync = ref.read(syncServiceProvider);
                final knownTracks = ref.read(tracksProvider).valueOrNull ?? [];
                await sync.syncTracks();
                ref.invalidate(tracksProvider);
                for (final t in knownTracks) {
                  await sync.syncUnits(t.id);
                  ref.invalidate(unitsForTrackProvider(t.id));
                }
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _StreakXpCard(streak: streak, user: user),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _WeeklyXpCard(),
                    ),
                  ),
                  if ((streak.valueOrNull?.streakGoal ?? 0) > 0)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: StreakGoalProgressWidget(
                          currentStreak:
                              streak.valueOrNull?.currentStreak ?? 0,
                          streakGoal: streak.valueOrNull!.streakGoal!,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: _QuickAccessRow(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                      child: Text(
                        'শেখার পথ',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  tracks.when(
                    data: (list) => list.isEmpty
                        ? const SliverToBoxAdapter(child: _EmptyTracksState())
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 14),
                                child: _TrackCard(track: list[i]),
                              ),
                              childCount: list.length,
                            ),
                          ),
                    loading: () => const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: Center(
                        child: Text('পাঠ লোড হচ্ছে না।',
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.error)),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Streak / XP card ──────────────────────────────────────────────────────────

class _StreakXpCard extends ConsumerWidget {
  final AsyncValue<Streak?> streak;
  final dynamic user;
  const _StreakXpCard({required this.streak, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final streakData = streak.valueOrNull;
    final currentStreak = streakData?.currentStreak ?? 0;
    final longestStreak = streakData?.longestStreak ?? 0;
    final totalXp = streakData?.totalXp ?? 0;
    final freezeCount = streakData?.freezeCount ?? 0;
    final isAnon = user?.isAnonymous == true;
    final userId = user?.id as String?;
    final mastered = ref.watch(masteredWordCountProvider).valueOrNull ?? 0;
    final level = XpLevel.forXp(totalXp);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.gradientStreak,
        ),
        borderRadius: AppRadius.xlBorder,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Flame + streak count
            const Text('🔥', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentStreak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const Text(
                  'দিনের ধারা',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // XP / level / streak / mastered badges
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Badge(label: '✨ $totalXp XP', color: Colors.white24),
                  _Badge(
                    label: '${level.nameAr} Lv.${level.level}',
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                  if (longestStreak > 0)
                    _Badge(
                      label: '🏆 $longestStreak সর্বোচ্চ',
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  if (mastered > 0)
                    _Badge(
                      label: '📖 $mastered মুখস্থ',
                      color: AppColors.brightGreen.withValues(alpha: 0.3),
                    ),
                  if (freezeCount > 0)
                    _Badge(
                      label: '❄️ $freezeCount ফ্রিজ',
                      color: Colors.lightBlue.withValues(alpha: 0.25),
                    ),
                ],
              ),
            ),
            if (isAnon)
              OutlinedButton(
                onPressed: () => context.go('/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('সংরক্ষণ'),
              )
            else if (userId != null && currentStreak > 0)
              Tooltip(
                message: 'স্ট্রিক ফ্রিজ',
                child: IconButton(
                  icon: const Text('❄️', style: TextStyle(fontSize: 22)),
                  onPressed: () async {
                    final confirm = await showConfirmDialog(
                      context,
                      title: 'স্ট্রিক ফ্রিজ',
                      body: 'একটি ফ্রিজ ব্যবহার করবেন? একদিন মিস হলেও স্ট্রিক বজায় থাকবে।',
                    );
                    if (confirm == true) {
                      await ref
                          .read(streakFreezeProvider(userId).notifier)
                          .freeze();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('❄️ স্ট্রিক ফ্রিজ সক্রিয়!')),
                        );
                      }
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Weekly XP card ────────────────────────────────────────────────────────────

class _WeeklyXpCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weeklyXp = ref.watch(weeklyXpProvider).valueOrNull ?? 0;
    const weeklyGoal = 200;
    final pct = (weeklyXp / weeklyGoal).clamp(0.0, 1.0);
    final dayLabels = ['সো', 'মং', 'বু', 'বৃ', 'শু', 'শ', 'র'];
    final today = DateTime.now().weekday; // 1=Mon … 7=Sun

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
                'এই সপ্তাহ',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '$weeklyXp / $weeklyGoal XP',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final dayNum = i + 1;
              final isPast = dayNum < today;
              final isToday = dayNum == today;
              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPast
                          ? AppColors.brightGreen
                          : isToday
                              ? AppColors.gold
                              : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Icon(
                      isPast ? Icons.check : isToday ? Icons.star : null,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayLabels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w400,
                      color: isToday
                          ? AppColors.gold
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Quick access row ──────────────────────────────────────────────────────────

class _QuickAccessRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newCount = ref.watch(newCardCountProvider).valueOrNull ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _QuickAccessButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'কথোপকথন',
          color: AppColors.teal,
          onTap: () => context.push('/conversation'),
        ),
        _QuickAccessButton(
          icon: Icons.psychology_outlined,
          label: 'মুখস্থ',
          color: const Color(0xFF5B4FCF),
          badge: newCount,
          onTap: () => context.push('/memorize'),
        ),
        _QuickAccessButton(
          icon: Icons.groups_outlined,
          label: 'হালাকা',
          color: AppColors.midGreen,
          onTap: () => context.push('/groups'),
        ),
      ],
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badge;
  const _QuickAccessButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap,
      this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 26, color: Colors.white),
              ),
              if (badge > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Track card ────────────────────────────────────────────────────────────────

// ── Learn tab (used by MainShell) ─────────────────────────────────────────────

class LearnTab extends ConsumerWidget {
  const LearnTab({super.key, this.onPracticeTab});
  final VoidCallback? onPracticeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(tracksProvider);
    final streak = ref.watch(streakProvider).valueOrNull;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Builder(builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Image.asset(
            isDark
                ? 'assets/logo_dark-removebg-preview.png'
                : 'assets/logo_light-removebg-preview.png',
            height: 44,
          );
        }),
        centerTitle: false,
        actions: [
          // Compact streak chip
          if (streak != null) ...[
            _StatChip('🔥', '${streak.currentStreak}'),
            _StatChip('⭐', '${streak.totalXp}'),
            _StatChip('❤️', '${streak.hearts}/5'),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final sync = ref.read(syncServiceProvider);
                final knownTracks =
                    ref.read(tracksProvider).valueOrNull ?? [];
                await sync.syncTracks();
                ref.invalidate(tracksProvider);
                for (final t in knownTracks) {
                  await sync.syncUnits(t.id);
                  ref.invalidate(unitsForTrackProvider(t.id));
                }
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'শেখার পথ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  tracks.when(
                    data: (list) => list.isEmpty
                        ? const SliverToBoxAdapter(
                            child: _EmptyTracksState())
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 0, 20, 14),
                                child: _TrackCard(track: list[i]),
                              ),
                              childCount: list.length,
                            ),
                          ),
                    loading: () => const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: Center(
                        child: Text('পাঠ লোড হচ্ছে না।',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  const _StatChip(this.emoji, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$emoji $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TrackCard extends ConsumerWidget {
  final Track track;
  const _TrackCard({required this.track});

  bool get _isQuranic =>
      track.slug == 'quranic' ||
      track.nameBn.contains('কুরআন') ||
      track.nameBn.contains('তিলাওয়াত');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isQuranic = _isQuranic;
    final progress =
        ref.watch(trackProgressProvider(track.id)).valueOrNull;

    final gradientColors = isQuranic
        ? AppColors.gradientQuranic
        : AppColors.gradientConversational;

    final icon = isQuranic ? Icons.menu_book_rounded : Icons.record_voice_over_rounded;
    final subtitle =
        isQuranic ? 'কুরআনের শব্দ ও ব্যাকরণ' : 'দৈনন্দিন কথোপকথন';

    return Card(
      clipBehavior: Clip.antiAlias,
      shadowColor: gradientColors[0].withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      child: InkWell(
        onTap: () => context.push('/track/${track.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient header
            Container(
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative background Arabic text
                  Positioned(
                    right: -8,
                    bottom: -18,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        track.nameAr,
                        style: const TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 64,
                          color: Colors.white10,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  // Icon + name
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, size: 26, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              track.nameBn,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                track.nameAr,
                                style: const TextStyle(
                                  fontFamily: 'NotoNaskhArabic',
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom row
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (progress != null && progress.total > 0)
                        Text(
                          '${progress.completed}/${progress.total} পাঠ',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  if (progress != null && progress.total > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: AppRadius.xxlBorder,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress.fraction),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (_, val, __) => LinearProgressIndicator(
                          value: val,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                              gradientColors[0]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ] else
                    const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => context.push('/track/${track.slug}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: gradientColors[0],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(progress != null && progress.completed > 0
                        ? 'চালিয়ে যান'
                        : 'শুরু করুন'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyTracksState extends StatelessWidget {
  const _EmptyTracksState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo as hero illustration
          Image.asset(
            isDark
                ? 'assets/logo_dark-removebg-preview.png'
                : 'assets/logo_light-removebg-preview.png',
            height: 120,
          ),
          const SizedBox(height: 20),
          Text(
            'স্বাগতম!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'আরবি শেখার যাত্রা শুরু করুন।\nকোর্স লোড হচ্ছে — একটু অপেক্ষা করুন।',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          // Animated dots to indicate loading
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return _PulseDot(delay: Duration(milliseconds: i * 200));
            }),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Duration delay;
  const _PulseDot({required this.delay});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
