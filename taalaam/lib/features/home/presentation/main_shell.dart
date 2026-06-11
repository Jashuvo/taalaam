import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/xp_level.dart';
import '../../../shared/widgets/progress_share_card.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../track_quran/presentation/quran_reader_provider.dart';
import '../../track_quran/presentation/quran_word_reader_page.dart';
import 'home_page.dart';
import 'home_provider.dart';
import 'widgets/streak_goal_progress_widget.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _tab = 0;

  void _selectTab(int i) {
    setState(() => _tab = i);
    ref.read(quranNavBarVisibleProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final navVisible = ref.watch(quranNavBarVisibleProvider);
    final disableAnim = MediaQuery.of(context).disableAnimations;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _tab != 0) _selectTab(0);
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(
              index: _tab,
              children: [
                LearnTab(onPracticeTab: () => _selectTab(1)),
                const _PracticeTab(),
                const QuranWordReaderPage(showBackButton: false),
                const _ProfileTab(),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
                child: AnimatedSlide(
                  offset: navVisible ? Offset.zero : const Offset(0, 1.5),
                  duration: disableAnim ? Duration.zero : AppMotion.fast,
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: navVisible ? 1 : 0,
                    duration: disableAnim ? Duration.zero : AppMotion.fast,
                    child: IgnorePointer(
                      ignoring: !navVisible,
                      child: _NavPill(tab: _tab, onSelect: _selectTab),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating bottom-nav pill ────────────────────────────────────────────────

class _NavPill extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onSelect;

  const _NavPill({required this.tab, required this.onSelect});

  static const _labels = ['শিখুন', 'অনুশীলন', 'কুরআন', 'আমি'];
  static const _icons = [
    Icons.school_outlined,
    Icons.fitness_center_outlined,
    Icons.menu_book_outlined,
    Icons.person_outline,
  ];
  static const _selectedIcons = [
    Icons.school_rounded,
    Icons.fitness_center_rounded,
    Icons.menu_book_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnim = MediaQuery.of(context).disableAnimations;
    return Container(
      height: kNavPillHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          type: MaterialType.transparency,
          child: LayoutBuilder(builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / 4;
            const pillWidth = 56.0;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: disableAnim ? Duration.zero : AppMotion.normal,
                  curve: Curves.easeOutCubic,
                  left: tab * itemWidth + (itemWidth - pillWidth) / 2,
                  top: (kNavPillHeight - 36) / 2,
                  width: pillWidth,
                  height: 36,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    4,
                    (i) => Expanded(
                      child: _NavBarItem(
                        icon: _icons[i],
                        selectedIcon: _selectedIcons[i],
                        label: _labels[i],
                        selected: tab == i,
                        onTap: () => onSelect(i),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnim = MediaQuery.of(context).disableAnimations;
    final color = selected ? AppColors.gold : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.1 : 1.0,
            duration: disableAnim ? Duration.zero : AppMotion.normal,
            curve: Curves.easeOutCubic,
            child: Icon(selected ? selectedIcon : icon, color: color),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: disableAnim ? Duration.zero : AppMotion.normal,
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

// ── Practice tab ──────────────────────────────────────────────────────────────

class _PracticeTab extends ConsumerStatefulWidget {
  const _PracticeTab();

  @override
  ConsumerState<_PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends ConsumerState<_PracticeTab>
    with SingleTickerProviderStateMixin {
  static const _staggerCount = 5;
  static const _stagger = Duration(milliseconds: 50);
  static const _itemDuration = Duration(milliseconds: 300);
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final totalMs = _itemDuration.inMilliseconds +
        (_staggerCount - 1) * _stagger.inMilliseconds;
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: totalMs));
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _entranceFor(int index) {
    final totalMs = _controller.duration!.inMilliseconds;
    final start = (index * _stagger.inMilliseconds / totalMs).clamp(0.0, 1.0);
    final end = (start + _itemDuration.inMilliseconds / totalMs).clamp(start, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Widget _staggered(int index, Widget child) {
    final entrance = _entranceFor(index);
    return AnimatedBuilder(
      animation: entrance,
      builder: (context, child) => Opacity(
        opacity: entrance.value,
        child: Transform.translate(
          offset: Offset(0, (1 - entrance.value) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final newCount = ref.watch(newCardCountProvider).valueOrNull ?? 0;
    final dueCount = ref.watch(dueCountProvider).valueOrNull ?? 0;
    final learningCount = ref.watch(learningWordCountProvider).valueOrNull ?? 0;
    final masteredCount = ref.watch(masteredWordCountProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('অনুশীলন'),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, navClearance(context)),
        children: [
          _staggered(
            0,
            Row(
              children: [
                Expanded(
                    child: _PracticeStatChip(
                        label: 'আজ ডিউ',
                        value: '$dueCount',
                        color: AppColors.gold)),
                const SizedBox(width: 10),
                Expanded(
                    child: _PracticeStatChip(
                        label: 'শিখছি',
                        value: '$learningCount',
                        color: AppColors.teal)),
                const SizedBox(width: 10),
                Expanded(
                    child: _PracticeStatChip(
                        label: 'আয়ত্ত',
                        value: '$masteredCount',
                        color: AppColors.forestGreen)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _staggered(1, _ReviewCard(dueCount: dueCount)),
          const SizedBox(height: 12),
          _staggered(
            2,
            _PracticeCard(
              icon: Icons.add_circle_outline_rounded,
              iconColor: AppColors.forestGreen,
              title: 'নতুন শব্দ শিখুন',
              subtitle: newCount > 0
                  ? '$newCount টি নতুন শব্দ অপেক্ষা করছে'
                  : 'এখন নতুন শব্দ নেই',
              badge: newCount > 0 ? '$newCount' : null,
              onTap: newCount > 0 ? () => context.push('/memorize') : null,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('আরও কার্যক্রম',
                style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          _staggered(
            3,
            _PracticeCard(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: AppColors.teal,
              title: 'কথোপকথন',
              subtitle: 'আরবিতে কথা বলার অনুশীলন',
              onTap: () => context.push('/conversation'),
            ),
          ),
          const SizedBox(height: 12),
          _staggered(
            4,
            _PracticeCard(
              icon: Icons.groups_2_outlined,
              iconColor: Colors.purple,
              title: 'হালাকা',
              subtitle: 'গ্রুপ শিক্ষা কার্যক্রম',
              onTap: () => context.push('/groups'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PracticeStatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int dueCount;
  const _ReviewCard({required this.dueCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDue = dueCount > 0;

    if (!isDue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: AppRadius.lgBorder,
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.check_circle_rounded,
                  color: AppColors.forestGreen.withValues(alpha: 0.7),
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('আজকের রিভিউ শেষ!',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                  const SizedBox(height: 2),
                  Text('চমৎকার! আগামীকাল আবার আসুন',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => context.push('/review'),
      borderRadius: AppRadius.lgBorder,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.08),
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: AppColors.gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('রিভিউ করুন',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      )),
                  const SizedBox(height: 2),
                  Text('$dueCount টি কার্ড রিভিউ বাকি',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$dueCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.gold, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;

  const _PracticeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgBorder,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isEnabled
              ? theme.colorScheme.surfaceContainer
              : theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: AppRadius.lgBorder,
          border: Border.all(
            color: isEnabled
                ? theme.colorScheme.outlineVariant
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isEnabled ? 0.15 : 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isEnabled
                      ? iconColor
                      : iconColor.withValues(alpha: 0.4),
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isEnabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              )
            else if (isEnabled)
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Profile tab ───────────────────────────────────────────────────────────────

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final streak = ref.watch(streakProvider).valueOrNull;
    final weeklyXp = ref.watch(weeklyXpProvider).valueOrNull ?? 0;
    final mastered = ref.watch(masteredWordCountProvider).valueOrNull ?? 0;
    final user = ref.watch(currentUserProvider);
    final totalXp = streak?.totalXp ?? 0;
    final level = XpLevel.forXp(totalXp);
    final hearts = streak?.hearts ?? 0;
    final currentStreak = streak?.currentStreak ?? 0;
    final longestStreak = streak?.longestStreak ?? 0;
    final freezeCount = streak?.freezeCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('আমি'),
        centerTitle: false,
        actions: [
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
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, navClearance(context)),
        children: [
          // User info
          if (user != null && user.isAnonymous != true)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.forestGreen,
                    child: Text(
                      (user.email?.isNotEmpty == true
                              ? user.email![0].toUpperCase()
                              : '?'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.email ?? 'ব্যবহারকারী',
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Main stats card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.forestGreen, Color(0xFF2E7D52)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.lgBorder,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatPill('🔥', '$currentStreak', 'দিনের ধারা'),
                    _StatPill('⭐', '$totalXp', 'মোট XP'),
                    _StatPill('❤️', '$hearts/5', 'হার্টস'),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: Colors.white24,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatPill('🏆', level.nameAr, 'স্তর'),
                    _StatPill('📚', '$mastered', 'মুখস্থ শব্দ'),
                    _StatPill('❄️', '$freezeCount', 'ফ্রিজ বাকি'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly XP
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: AppRadius.lgBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('এই সপ্তাহ',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('$weeklyXp / 200 XP',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (weeklyXp / 200).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Streak goal widget if set
          if ((streak?.streakGoal ?? 0) > 0)
            StreakGoalProgressWidget(
              currentStreak: currentStreak,
              streakGoal: streak!.streakGoal!,
            ),

          if (longestStreak > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: AppRadius.lgBorder,
              ),
              child: Row(
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text('সর্বোচ্চ ধারা: $longestStreak দিন',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.person_outline),
            label: const Text('প্রোফাইল সম্পাদনা'),
            onPressed: () => context.push('/profile'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainer,
              foregroundColor: theme.colorScheme.onSurface,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatPill(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label,
            style: const TextStyle(
                color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}
