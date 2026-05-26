import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/auth_provider.dart';

final leaderboardProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('streaks')
      .select('user_id, total_xp, current_streak')
      .order('total_xp', ascending: false)
      .limit(50);
  return List<Map<String, dynamic>>.from(data as List);
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
        title: const Text('সাপ্তাহিক র‍্যাংকিং'),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 48),
              const SizedBox(height: 16),
              const Text('লিডারবোর্ড লোড হয়নি।'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.refresh(leaderboardProvider),
                child: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('এখনো কেউ নেই।'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: entries.length,
            itemBuilder: (ctx, i) {
              final entry = entries[i];
              final uid = entry['user_id'] as String;
              final xp = entry['total_xp'] as int? ?? 0;
              final streak = entry['current_streak'] as int? ?? 0;
              final isSelf = uid == currentUser?.id;
              final rank = i + 1;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelf
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelf
                      ? Border.all(color: theme.colorScheme.primary)
                      : null,
                ),
                child: ListTile(
                  leading: _RankWidget(rank: rank),
                  title: Text(
                    isSelf ? 'আপনি' : _anonymousName(uid),
                    style: isSelf
                        ? theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary)
                        : null,
                  ),
                  subtitle: Row(
                    children: [
                      const Text('🔥 '),
                      Text('$streak দিন'),
                    ],
                  ),
                  trailing: Text(
                    '$xp XP',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: rank <= 3
                          ? _medalColor(rank)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _anonymousName(String uid) {
    // Generate a reproducible anonymous name from uid
    final hash = uid.hashCode.abs();
    const prefixes = [
      'ইমানদার', 'মুত্তাকী', 'সাবের', 'শাকের', 'মুজাহিদ',
      'তালিবুল', 'মুত্তাসিম', 'মুখলিস', 'সালিক', 'আবিদ'
    ];
    const suffixes = [
      'শিক্ষার্থী', 'পাঠক', 'মুসাফির', 'তালিব', 'মুরিদ'
    ];
    return '${prefixes[hash % prefixes.length]} ${suffixes[(hash ~/ prefixes.length) % suffixes.length]}';
  }

  Color _medalColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    return const Color(0xFFCD7F32);
  }
}

class _RankWidget extends StatelessWidget {
  final int rank;
  const _RankWidget({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      const medals = ['🥇', '🥈', '🥉'];
      return Text(medals[rank - 1], style: const TextStyle(fontSize: 28));
    }
    return SizedBox(
      width: 36,
      child: Text(
        '#$rank',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }
}
