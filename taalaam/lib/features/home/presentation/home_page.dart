import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/onboarding_page.dart';
import '../../../shared/widgets/progress_share_card.dart';
import 'home_provider.dart';

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
                      onPressed: () => context.go('/review'),
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
            onPressed: () => context.go('/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'সেটিংস',
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('সাইন আউট'),
                  content: const Text('আপনি কি সাইন আউট করতে চান?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('না')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('হ্যাঁ')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(authServiceProvider).signOut();
              }
            },
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
    final totalXp = streakData?.totalXp ?? 0;
    final freezeCount = streakData?.freezeCount ?? 0;
    final isAnon = user?.isAnonymous == true;
    final userId = user?.id as String?;

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
            // XP + freeze badges
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Badge(label: '✨ $totalXp XP', color: Colors.white24),
                if (freezeCount > 0) ...[
                  const SizedBox(height: 6),
                  _Badge(
                      label: '❄️ $freezeCount ফ্রিজ',
                      color: Colors.lightBlue.withValues(alpha: 0.25)),
                ],
              ],
            ),
            const Spacer(),
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
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('স্ট্রিক ফ্রিজ'),
                        content: const Text(
                            'একটি ফ্রিজ ব্যবহার করবেন? একদিন মিস হলেও স্ট্রিক বজায় থাকবে।'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('না')),
                          FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('হ্যাঁ')),
                        ],
                      ),
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

// ── Quick access row ──────────────────────────────────────────────────────────

class _QuickAccessRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _QuickAccessButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'কথোপকথন',
          color: AppColors.teal,
          onTap: () => context.go('/conversation'),
        ),
        _QuickAccessButton(
          icon: Icons.psychology_outlined,
          label: 'মুখস্থ',
          color: const Color(0xFF5B4FCF),
          onTap: () => context.go('/memorize'),
        ),
        _QuickAccessButton(
          icon: Icons.groups_outlined,
          label: 'হালাকা',
          color: AppColors.midGreen,
          onTap: () => context.go('/groups'),
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
  const _QuickAccessButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Track card ────────────────────────────────────────────────────────────────

class _TrackCard extends ConsumerWidget {
  final Track track;
  const _TrackCard({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isQuranic = track.slug == 'quranic';
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
        onTap: () => context.go('/track/${track.slug}'),
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
                    onPressed: () => context.go('/track/${track.slug}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: gradientColors[0],
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
