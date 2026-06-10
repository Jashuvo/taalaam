import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';

final leaderboardProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;

  // Fetch streaks (RLS allows SELECT for all after migration 0009)
  final streaks = List<Map<String, dynamic>>.from(
    await client
        .from('streaks')
        .select('user_id, total_xp, current_streak')
        .order('total_xp', ascending: false)
        .limit(50) as List,
  );

  if (streaks.isEmpty) return [];

  // Fetch profiles for those user IDs in one query
  final ids = streaks.map((s) => s['user_id'] as String).toList();
  final profiles = List<Map<String, dynamic>>.from(
    await client
        .from('profiles')
        .select('id, display_name')
        .inFilter('id', ids) as List,
  );

  final nameMap = {
    for (final p in profiles)
      p['id'] as String: p['display_name'] as String? ?? '',
  };

  // Merge display_name into each streak row
  return streaks.map((s) => {
        ...s,
        'display_name': nameMap[s['user_id'] as String] ?? '',
      }).toList();
});

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final board = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: const Text('সর্বমোট র‍্যাংকিং'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(leaderboardProvider),
          ),
        ],
      ),
      body: board.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off,
                    size: 48, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                const Text('র‍্যাংকিং লোড হয়নি।',
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => ref.refresh(leaderboardProvider),
                  child: const Text('আবার চেষ্টা করুন'),
                ),
              ],
            ),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('এখনো কেউ নেই।\nপ্রথম পাঠ শেষ করুন!',
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          // Separate top 3 from the rest
          final top3 = entries.take(3).toList();
          final rest = entries.skip(3).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              // ── Podium ────────────────────────────────────────────────
              if (top3.length >= 2)
                _Podium(
                  entries: top3,
                  currentUserId: currentUser?.id,
                ),
              const SizedBox(height: 16),

              // ── Your rank highlight (if outside top 3) ───────────────
              () {
                final selfIdx = entries
                    .indexWhere((e) => e['user_id'] == currentUser?.id);
                if (selfIdx >= 3) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RankRow(
                        entry: entries[selfIdx],
                        rank: selfIdx + 1,
                        isSelf: true,
                        theme: theme,
                      ),
                      Divider(color: theme.colorScheme.outlineVariant),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }(),

              // ── Rest of the list ──────────────────────────────────────
              ...rest.asMap().entries.map((e) => _RankRow(
                    entry: e.value,
                    rank: e.key + 4,
                    isSelf: e.value['user_id'] == currentUser?.id,
                    theme: theme,
                  )),
            ],
          );
        },
      ),
    );
  }
}

// ── Podium widget (top 3) ────────────────────────────────────────────────────

class _Podium extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final String? currentUserId;
  const _Podium({required this.entries, this.currentUserId});

  @override
  State<_Podium> createState() => _PodiumState();
}

class _PodiumState extends State<_Podium>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.gentle);
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

  /// Staggered rise-up entrance for the podium slot at [displayIdx]
  /// (0 = left, 1 = centre, 2 = right).
  Animation<double> _entranceFor(int displayIdx) {
    final stagger = AppMotion.stagger.inMilliseconds /
        AppMotion.gentle.inMilliseconds;
    final start = (displayIdx * stagger).clamp(0.0, 1.0);
    final end = (start + (1 - 2 * stagger)).clamp(start, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = widget.entries;
    final currentUserId = widget.currentUserId;

    Widget slot(int rank) {
      if (rank > entries.length) return const SizedBox.shrink();
      final e = entries[rank - 1];
      final isSelf = e['user_id'] == currentUserId;
      final name = _displayName(e, isSelf);
      final xp = e['total_xp'] as int? ?? 0;
      final medalColors = [
        AppColors.gold,
        const Color(0xFF9E9E9E),
        const Color(0xFFA9745B),
      ];
      final heights = [100.0, 72.0, 56.0];
      // Show rank 2 left, rank 1 centre, rank 3 right
      final displayOrder = [2, 1, 3];
      final displayIdx = displayOrder.indexOf(rank);
      if (displayIdx == -1) return const SizedBox.shrink();
      final height = heights[displayIdx];

      final entrance = _entranceFor(displayIdx);

      return Expanded(
        child: AnimatedBuilder(
          animation: entrance,
          builder: (context, child) => Opacity(
            opacity: entrance.value,
            child: Transform.translate(
              offset: Offset(0, (1 - entrance.value) * 28),
              child: child,
            ),
          ),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Avatar circle
            CircleAvatar(
              radius: rank == 1 ? 28 : 22,
              backgroundColor: isSelf
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: rank == 1 ? 20 : 16,
                  fontWeight: FontWeight.bold,
                  color: isSelf
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
                color: isSelf
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              '$xp XP',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            // Podium block
            Container(
              height: height,
              decoration: BoxDecoration(
                color: rank == 1
                    ? AppColors.gold.withValues(alpha: 0.25)
                    : rank == 2
                        ? const Color(0xFFC0C0C0).withValues(alpha: 0.2)
                        : const Color(0xFFCD7F32).withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border.all(
                  color: rank == 1
                      ? AppColors.gold.withValues(alpha: 0.5)
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Center(
                child: Icon(Icons.emoji_events,
                    size: 24, color: medalColors[rank - 1]),
              ),
            ),
          ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [slot(2), const SizedBox(width: 8), slot(1), const SizedBox(width: 8), slot(3)],
      ),
    );
  }
}

// ── Individual rank row ──────────────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int rank;
  final bool isSelf;
  final ThemeData theme;
  const _RankRow(
      {required this.entry,
      required this.rank,
      required this.isSelf,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    final xp = entry['total_xp'] as int? ?? 0;
    final streak = entry['current_streak'] as int? ?? 0;
    final name = _displayName(entry, isSelf);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelf
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainer,
        borderRadius: AppRadius.lgBorder,
        border: isSelf
            ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#$rank',
              style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: isSelf
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelf
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isSelf ? FontWeight.bold : FontWeight.normal,
                    color: isSelf ? theme.colorScheme.primary : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(children: [
                  const Icon(Icons.local_fire_department,
                      size: 12, color: AppColors.gold),
                  const SizedBox(width: 2),
                  Text('$streak দিন',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ]),
              ],
            ),
          ),
          Text(
            '$xp XP',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _displayName(Map<String, dynamic> entry, bool isSelf) {
  if (isSelf) return 'আপনি';
  final name = entry['display_name'] as String?;
  if (name != null && name.isNotEmpty) return name;
  // Reproducible anonymous name from uid
  final uid = entry['user_id'] as String? ?? '';
  final hash = uid.hashCode.abs();
  const prefixes = [
    'ইমানদার', 'মুত্তাকী', 'সাবের', 'শাকের', 'মুজাহিদ',
    'তালিবুল', 'মুত্তাসিম', 'মুখলিস', 'সালিক', 'আবিদ'
  ];
  const suffixes = ['শিক্ষার্থী', 'পাঠক', 'মুসাফির', 'তালিব', 'মুরিদ'];
  return '${prefixes[hash % prefixes.length]} ${suffixes[(hash ~/ prefixes.length) % suffixes.length]}';
}
