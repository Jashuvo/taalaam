import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/xp_level.dart';
import '../../../shared/widgets/progress_share_card.dart';
import '../../auth/presentation/auth_provider.dart';
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
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          LearnTab(onPracticeTab: () => setState(() => _tab = 1)),
          const _PracticeTab(),
          const QuranWordReaderPage(showBackButton: false),
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(
          4,
          (i) => NavigationDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(_selectedIcons[i]),
            label: _labels[i],
          ),
        ),
      ),
    );
  }
}

// ── Practice tab ──────────────────────────────────────────────────────────────

class _PracticeTab extends ConsumerWidget {
  const _PracticeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final newCount = ref.watch(newCardCountProvider).valueOrNull ?? 0;
    final dueCount = ref.watch(dueCountProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('অনুশীলন'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // SRS cards
          _PracticeCard(
            icon: Icons.add_circle_outline_rounded,
            iconColor: AppColors.forestGreen,
            title: 'নতুন শব্দ শিখুন',
            subtitle: newCount > 0
                ? '$newCount টি নতুন শব্দ অপেক্ষা করছে'
                : 'এখন নতুন শব্দ নেই',
            badge: newCount > 0 ? '$newCount' : null,
            onTap: newCount > 0 ? () => context.go('/memorize') : null,
          ),
          const SizedBox(height: 12),
          _PracticeCard(
            icon: Icons.refresh_rounded,
            iconColor: Colors.orange,
            title: 'রিভিউ করুন',
            subtitle: dueCount > 0
                ? '$dueCount টি কার্ড রিভিউ বাকি'
                : 'আজকের রিভিউ শেষ!',
            badge: dueCount > 0 ? '$dueCount' : null,
            onTap: dueCount > 0 ? () => context.go('/review') : null,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('আরও কার্যক্রম',
                style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          _PracticeCard(
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: AppColors.teal,
            title: 'কথোপকথন',
            subtitle: 'আরবিতে কথা বলার অনুশীলন',
            onTap: () => context.go('/conversation'),
          ),
          const SizedBox(height: 12),
          _PracticeCard(
            icon: Icons.groups_2_outlined,
            iconColor: Colors.purple,
            title: 'হালাকা',
            subtitle: 'গ্রুপ শিক্ষা কার্যক্রম',
            onTap: () => context.go('/groups'),
          ),
        ],
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
            onPressed: () => context.go('/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'সেটিংস',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
            onPressed: () => context.go('/profile'),
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
