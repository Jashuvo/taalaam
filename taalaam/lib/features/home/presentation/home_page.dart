import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tap_scale.dart';
import '../../../data/local/database.dart';
import '../../../shared/services/gamification_service.dart';
import '../../../shared/utils/bn_digits.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/misbaha/gold_pill_button.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/onboarding_page.dart';
import 'home_provider.dart';
import 'track_detail_page.dart';
import 'widgets/streak_goal_completion_dialog.dart';

// Tier accent colours, mirroring track_detail_page._tierGradients (first colour).
const _heroTierColors = <int, Color>{
  1: AppColors.teal,
  2: AppColors.forestGreen,
  3: Color(0xFF78350F),
  4: Color(0xFF3B0764),
};

const _weekdaysBn = [
  'রবিবার',
  'সোমবার',
  'মঙ্গলবার',
  'বুধবার',
  'বৃহস্পতিবার',
  'শুক্রবার',
  'শনিবার',
];

const _hijriMonthsBn = [
  'মুহাররম',
  'সফর',
  'রবিউল আউয়াল',
  'রবিউস সানি',
  'জমাদিউল আউয়াল',
  'জমাদিউস সানি',
  'রজব',
  'শাবান',
  'রমজান',
  'শাওয়াল',
  'জিলকদ',
  'জিলহজ',
];

const _encouragements = [
  'আজকের ছোট একটি পাঠ আগামীর বড় পরিবর্তন',
  'ধারাবাহিকতাই বরকতের চাবি — চালিয়ে যান',
  'এক আয়াত শেখাও একটি অর্জন',
];
// ── Weekly XP card ────────────────────────────────────────────────────────────

class _WeeklyXpCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weeklyXp = ref.watch(weeklyXpProvider).valueOrNull ?? 0;
    final rank = ref.watch(leaderboardRankProvider).valueOrNull;
    const weeklyGoal = 200;
    final pct = (weeklyXp / weeklyGoal).clamp(0.0, 1.0);
    final remaining = (weeklyGoal - weeklyXp).clamp(0, weeklyGoal);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: isDark ? AppColors.darkOutlineVariant : AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'সাপ্তাহিক XP · ${bnDigits(weeklyXp)}/${bnDigits(weeklyGoal)}',
                style: TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkOnSurface : AppColors.ink,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/leaderboard'),
                child: Text(
                  rank != null ? 'লিডারবোর্ড #${bnDigits(rank)} ›' : 'লিডারবোর্ড ›',
                  style: const TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 7,
                backgroundColor: const Color(0xFFE9E2D2),
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            remaining > 0
                ? 'লক্ষ্য পূরণে আর ${bnDigits(remaining)} XP — ইনশাআল্লাহ হয়ে যাবে'
                : 'এই সপ্তাহের লক্ষ্য পূর্ণ হয়েছে — মাশাআল্লাহ!',
            style: const TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 10.5,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Continue learning hero card ─────────────────────────────────────────────

class _ContinueLearningCard extends ConsumerWidget {
  const _ContinueLearningCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current = ref.watch(currentLessonProvider).valueOrNull;
    if (current == null) return const SizedBox.shrink();

    final accent = _heroTierColors[current.unit.tierLevel] ?? AppColors.teal;
    final fraction =
        current.unitTotal == 0 ? 0.0 : current.unitCompleted / current.unitTotal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TapScale(
        child: Material(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: AppRadius.lgBorder,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/lesson/${current.lesson.id}'),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                        width: 5, height: double.infinity, color: accent),
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 5),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'চালিয়ে যাও',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              current.lesson.titleBn,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              current.unit.titleBn,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: AppRadius.xxlBorder,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: fraction),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOut,
                                builder: (_, val, __) =>
                                    LinearProgressIndicator(
                                  value: val,
                                  minHeight: 5,
                                  backgroundColor: theme
                                      .colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(accent),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.play_arrow_rounded,
                            color: accent, size: 26),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── SRS row (মুখস্থ / রিভিউ) ──────────────────────────────────────────────────

class _SrsRow extends ConsumerWidget {
  const _SrsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newCount = ref.watch(newCardCountProvider).valueOrNull ?? 0;
    final dueCount = ref.watch(dueCountProvider).valueOrNull ?? 0;

    return Row(
      children: [
        Expanded(
          child: _SrsCard(
            icon: '✍️',
            iconBg: const Color(0xFFFBF3DE),
            iconColor: AppColors.goldDeep,
            title: 'মুখস্থ',
            subtitle: 'নতুন শব্দ',
            count: newCount,
            onTap: () => context.push('/memorize'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SrsCard(
            icon: '↻',
            iconBg: const Color(0xFFE2EFEA),
            iconColor: AppColors.midGreen,
            title: 'রিভিউ',
            subtitle: 'আজ বাকি',
            count: dueCount,
            onTap: dueCount > 0 ? () => context.push('/review') : null,
          ),
        ),
      ],
    );
  }
}

class _SrsCard extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback? onTap;

  const _SrsCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TapScale(
      child: Material(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: AppRadius.mdBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdBorder,
              border:
                  Border.all(color: isDark ? AppColors.darkOutlineVariant : AppColors.line),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 33,
                  height: 33,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(icon, style: TextStyle(fontSize: 15, color: iconColor)),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkOnSurface : AppColors.ink,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontFamily: 'HindSiliguri', fontSize: 10.5, color: AppColors.ink2),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Center(
                    child: Text(
                      bnDigits(count),
                      style: const TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Track card ────────────────────────────────────────────────────────────────

// ── Learn tab (used by MainShell) ─────────────────────────────────────────────

class LearnTab extends ConsumerStatefulWidget {
  const LearnTab({super.key, this.onPracticeTab});
  final VoidCallback? onPracticeTab;

  @override
  ConsumerState<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends ConsumerState<LearnTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flameController;
  bool _pulseTriggered = false;

  @override
  void initState() {
    super.initState();
    _flameController =
        AnimationController(vsync: this, duration: AppMotion.gentle);
  }

  @override
  void dispose() {
    _flameController.dispose();
    super.dispose();
  }

  void _maybePulseFlame(Streak? streak) {
    if (_pulseTriggered || streak == null) return;
    final last = streak.lastActivityDate;
    if (last == null) return;
    final now = DateTime.now();
    final isToday =
        last.year == now.year && last.month == now.month && last.day == now.day;
    if (!isToday) return;
    _pulseTriggered = true;
    if (!MediaQuery.of(context).disableAnimations) {
      _flameController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final streak = ref.watch(streakProvider).valueOrNull;
    _maybePulseFlame(streak);

    final flameScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.3)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
    ]).animate(_flameController);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
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
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _HomeHeaderRow(
                          user: user,
                          streak: streak,
                          flameScale: flameScale,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 13, 20, 9),
                        child: _GreetingBlock(user: user),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                        child: _ContinueLearningCard(),
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
                                      20, 0, 20, 11),
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 11),
                        child: _WeeklyXpCard(),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 1, 20, 16),
                        child: _SrsRow(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: navClearance(context)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header row (avatar + streak/XP/hearts chips) ────────────────────────────

class _HomeHeaderRow extends StatelessWidget {
  final User? user;
  final Streak? streak;
  final Animation<double> flameScale;

  const _HomeHeaderRow({required this.user, required this.streak, required this.flameScale});

  @override
  Widget build(BuildContext context) {
    final email = user?.email;
    final initial =
        (email != null && email.isNotEmpty) ? email[0].toUpperCase() : 'আ';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.forestGreen, AppColors.midGreen],
            ),
            border: Border.all(color: AppColors.gold, width: 2),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.goldLight,
              ),
            ),
          ),
        ),
        Row(
          children: [
            if (streak != null) ...[
              ScaleTransition(
                scale: flameScale,
                child: StatChip(
                  icon: '🔥',
                  iconColor: AppColors.gold,
                  label: bnDigits(streak!.currentStreak),
                ),
              ),
              const SizedBox(width: 7),
              StatChip(
                icon: '✦',
                iconColor: AppColors.tealLight,
                label: '${bnDigits(streak!.totalXp)} XP',
              ),
              const SizedBox(width: 7),
              StatChip(
                icon: '❤️',
                label: '${bnDigits(streak!.hearts)}/${bnDigits(5)}',
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Greeting block (Hijri date + greeting + sub-line) ───────────────────────

class _GreetingBlock extends ConsumerWidget {
  final User? user;
  const _GreetingBlock({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final hijri = HijriCalendar.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dateLine =
        '${_weekdaysBn[now.weekday % 7]} · ${bnDigits(hijri.hDay)} ${_hijriMonthsBn[hijri.hMonth - 1]} ${bnDigits(hijri.hYear)}';

    final email = user?.email;
    final firstName = (email != null && email.contains('@'))
        ? email.split('@').first
        : 'শিক্ষার্থী';

    final greeting = now.weekday == DateTime.friday
        ? "জুমু'আ মুবারাকাহ, $firstName"
        : 'আসসালামু আলাইকুম, $firstName';

    final bonusAvailable =
        ref.watch(firstLessonBonusAvailableProvider).valueOrNull ?? false;
    final subLine = bonusAvailable
        ? '⚡ দিনের প্রথম পাঠে ২× XP — আজকের পাঠ শুরু করুন'
        : _encouragements[now.day % _encouragements.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLine,
          style: const TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.goldDeep,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          greeting,
          style: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: isDark ? AppColors.darkOnSurface : AppColors.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subLine,
          style: const TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 12.5,
            color: AppColors.ink2,
          ),
        ),
      ],
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

    return TapScale(
      child: OpenContainer(
        closedElevation: 1,
        closedColor: theme.cardColor,
        closedShape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        transitionDuration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : AppMotion.route,
        openBuilder: (context, _) => TrackDetailPage(slug: track.slug),
        closedBuilder: (context, openContainer) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient header
            Container(
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
              child: ClipRRect(
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
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 64,
                            color: Colors.white.withValues(alpha: 0.06),
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
                              const SizedBox(height: 1),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontFamily: 'HindSiliguri',
                                  fontSize: 11.5,
                                  color: Colors.white70,
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
            ),
            // Bottom row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  if (progress != null && progress.total > 0)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.xxlBorder,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress.fraction),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (_, val, __) => LinearProgressIndicator(
                            value: val,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE9E2D2),
                            valueColor:
                                AlwaysStoppedAnimation(gradientColors[0]),
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (progress != null && progress.total > 0) ...[
                    const SizedBox(width: 10),
                    Text(
                      '${bnDigits(progress.completed)}/${bnDigits(progress.total)} পাঠ',
                      style: const TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink2,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  const Text('›', style: TextStyle(fontSize: 15, color: Color(0xFFC2B89F))),
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
