import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/local/database.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../shared/widgets/progress_share_card.dart';
import 'home_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final tracks = ref.watch(tracksProvider);
    final streak = ref.watch(streakProvider);
    final dueCount = ref.watch(dueCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'تعلَّم',
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 22,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        actions: [
          // Due cards badge
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
              onRefresh: () => ref.refresh(tracksProvider.future),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: _StreakXpCard(streak: streak, user: user),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'শেখার পথ বেছে নিন',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: _QuickAccessRow(),
                    ),
                  ),
                  tracks.when(
                    data: (list) => list.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'কোনো কোর্স পাওয়া যায়নি।\nইন্টারনেট সংযোগ পরীক্ষা করুন।',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                            style: TextStyle(color: theme.colorScheme.error)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentStreak দিনের ধারা',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '$totalXp XP অর্জিত',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (freezeCount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '❄️ $freezeCount',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isAnon)
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('সংরক্ষণ করুন'),
            )
          else if (userId != null && currentStreak > 0)
            Tooltip(
              message: 'স্ট্রিক ফ্রিজ করুন (একদিন মিস হলেও স্ট্রিক বজায় থাকবে)',
              child: IconButton(
                icon: const Text('❄️', style: TextStyle(fontSize: 20)),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('স্ট্রিক ফ্রিজ'),
                      content: const Text(
                          'একটি ফ্রিজ ব্যবহার করবেন? এটি একদিন মিস হলেও আপনার স্ট্রিক রক্ষা করবে।'),
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
                            content: Text('❄️ স্ট্রিক ফ্রিজ সক্রিয় হয়েছে!')),
                      );
                    }
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _QuickAccessButton(
            icon: Icons.chat_outlined,
            label: 'কথোপকথন',
            onTap: () => context.go('/conversation'),
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAccessButton(
            icon: Icons.psychology_outlined,
            label: 'মুখস্থ করুন',
            onTap: () => context.go('/memorize'),
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAccessButton(
            icon: Icons.group_outlined,
            label: 'হালাকা',
            onTap: () => context.go('/groups'),
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;
  const _QuickAccessButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final Track track;
  const _TrackCard({required this.track});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon =
        track.slug == 'quranic' ? Icons.menu_book : Icons.record_voice_over;
    final subtitle = track.slug == 'quranic'
        ? 'কুরআনের শব্দ ও ব্যাকরণ'
        : 'দৈনন্দিন কথোপকথন';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/track/${track.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    size: 28, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.nameBn,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        track.nameAr,
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 16,
                          height: 1.6,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
