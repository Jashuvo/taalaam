import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/misbaha/ornament_stamp.dart';
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
    await client.from('profiles').select('id, display_name').inFilter('id', ids)
        as List,
  );

  final nameMap = {
    for (final p in profiles)
      p['id'] as String: p['display_name'] as String? ?? '',
  };

  // Merge display_name into each streak row
  return streaks
      .map((s) => {
            ...s,
            'display_name': nameMap[s['user_id'] as String] ?? '',
          })
      .toList();
});

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final board = ref.watch(leaderboardProvider);

    return Scaffold(
      body: Column(
        children: [
          _LeaderboardHeader(
            onBack: () => context.go('/home'),
            onRefresh: () => ref.refresh(leaderboardProvider),
          ),
          Expanded(
            child: _buildBody(context, theme, board, currentUser,
                () => ref.refresh(leaderboardProvider)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      ThemeData theme,
      AsyncValue<List<Map<String, dynamic>>> board,
      User? currentUser,
      VoidCallback onRetry) {
    return board.when(
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
              const Text('র‍্যাংকিং লোড হয়নি।', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: onRetry,
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

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _RankRow(
            entry: entries[i],
            rank: i + 1,
            isSelf: entries[i]['user_id'] == currentUser?.id,
            theme: theme,
          ),
        );
      },
    );
  }
}

// ── Header (.lbh) ─────────────────────────────────────────────────────────────

/// Forest→mid-green gradient header with a faint ornament watermark, matching
/// the demo's `.lbh` leaderboard header.
class _LeaderboardHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  const _LeaderboardHeader({required this.onBack, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, MediaQuery.of(context).padding.top + 6, 12, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forestGreen, AppColors.midGreen],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: AppShadows.pop,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            right: -8,
            top: -28,
            child: Opacity(
              opacity: 0.13,
              child: OrnamentStamp(size: 88, color: AppColors.gold),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CircleIconButton(
                    onPressed: onBack,
                    icon: Icons.arrow_back,
                  ),
                  const Expanded(
                    child: Text(
                      'সাপ্তাহিক প্রতিযোগিতা',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
                  _CircleIconButton(
                    onPressed: onRefresh,
                    icon: Icons.refresh,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 6),
                child: Text(
                  'লিডারবোর্ড',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  'বেনামী নাম · প্রতি জুমু\'আয় রিসেট হয়',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 11,
                    color: Color(0xBFF5F0E8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Header back/refresh button (.back) ──────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  const _CircleIconButton({required this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 31,
          height: 31,
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}

// ── Individual rank row (.lbr) ───────────────────────────────────────────────

const _medals = ['🥇', '🥈', '🥉'];

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
    final name = _displayName(entry, isSelf);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: isSelf
            ? (isDark ? AppColors.darkCard : const Color(0xFFFFFDF4))
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: AppRadius.mdBorder,
        border: Border.all(
          color: isSelf
              ? AppColors.gold
              : (isDark ? AppColors.darkOutlineVariant : AppColors.line),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              rank <= 3 ? _medals[rank - 1] : '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: rank <= 3 ? 16 : 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isSelf
                    ? AppColors.goldDeep
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '$xp XP',
            style: TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
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
    'ইমানদার',
    'মুত্তাকী',
    'সাবের',
    'শাকের',
    'মুজাহিদ',
    'তালিবুল',
    'মুত্তাসিম',
    'মুখলিস',
    'সালিক',
    'আবিদ'
  ];
  const suffixes = ['শিক্ষার্থী', 'পাঠক', 'মুসাফির', 'তালিব', 'মুরিদ'];
  return '${prefixes[hash % prefixes.length]} ${suffixes[(hash ~/ prefixes.length) % suffixes.length]}';
}
