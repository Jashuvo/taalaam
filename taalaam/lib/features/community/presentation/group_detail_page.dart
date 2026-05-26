import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/auth_provider.dart';
import 'groups_provider.dart';

final _groupDetailProvider =
    FutureProvider.family<GroupModel?, String>((ref, groupId) async {
  final c = Supabase.instance.client;
  final row =
      await c.from('groups').select().eq('id', groupId).maybeSingle();
  if (row == null) return null;
  return GroupModel.fromJson(row);
});

class GroupDetailPage extends ConsumerWidget {
  final String groupId;
  const GroupDetailPage({required this.groupId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(_groupDetailProvider(groupId));
    final user = ref.watch(currentUserProvider);

    return groupAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('হালাকা')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('হালাকা')),
        body: Center(child: Text('$e')),
      ),
      data: (group) {
        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('হালাকা')),
            body: const Center(child: Text('গ্রুপটি পাওয়া যায়নি।')),
          );
        }
        return _DetailBody(
          group: group,
          currentUserId: user?.id,
          isCreator: user?.id == group.createdBy,
        );
      },
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final GroupModel group;
  final String? currentUserId;
  final bool isCreator;
  const _DetailBody({
    required this.group,
    required this.currentUserId,
    required this.isCreator,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(group.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/groups')),
        title: Text(group.name),
        actions: [
          // Copy invite code
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'আমন্ত্রণ কোড কপি করুন',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: group.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('কোড কপি হয়েছে: ${group.inviteCode}')),
              );
            },
          ),
          if (isCreator)
            PopupMenuButton<String>(
              onSelected: (v) => _onMenu(context, ref, v),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'goal',
                  child: ListTile(
                    leading: Icon(Icons.flag_outlined),
                    title: Text('স্ট্রিক লক্ষ্য পরিবর্তন করুন'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          if (currentUserId != null && !isCreator)
            PopupMenuButton<String>(
              onSelected: (v) => _onMenu(context, ref, v),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'leave',
                  child: ListTile(
                    leading: Icon(Icons.exit_to_app),
                    title: Text('গ্রুপ ছেড়ে যান'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Invite code + streak goal header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'আমন্ত্রণ কোড',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        group.inviteCode,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (group.streakGoal > 0) ...[
                  const VerticalDivider(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'সবার লক্ষ্য',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        '${group.streakGoal} দিন 🔥',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Text('সদস্যরা',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  'সর্বোচ্চ ${group.maxMembers} জন',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

          Expanded(
            child: membersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  const Center(child: Text('সদস্য লোড হয়নি।')),
              data: (members) => ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                itemCount: members.length,
                itemBuilder: (_, i) => _MemberTile(
                  member: members[i],
                  rank: i + 1,
                  isMe: members[i].userId == currentUserId,
                  streakGoal: group.streakGoal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMenu(BuildContext context, WidgetRef ref, String action) async {
    if (action == 'leave' && currentUserId != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('গ্রুপ ছেড়ে যান'),
          content: const Text('আপনি কি এই হালাকা ছেড়ে যেতে চান?'),
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
        await ref
            .read(groupsNotifierProvider(currentUserId!).notifier)
            .leaveGroup(group.id);
        if (context.mounted) {
          ref.invalidate(myGroupsProvider);
          context.go('/groups');
        }
      }
    } else if (action == 'goal' && currentUserId != null) {
      final goalCtrl =
          TextEditingController(text: '${group.streakGoal}');
      final result = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('স্ট্রিক লক্ষ্য নির্ধারণ করুন'),
          content: TextField(
            controller: goalCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'লক্ষ্য (দিন)',
              hintText: '০ = কোনো লক্ষ্য নেই',
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('বাতিল')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('সংরক্ষণ করুন')),
          ],
        ),
      );
      if (result == true && context.mounted) {
        final goal = int.tryParse(goalCtrl.text) ?? 0;
        await ref
            .read(groupsNotifierProvider(currentUserId!).notifier)
            .updateGoal(group.id, goal);
        ref.invalidate(_groupDetailProvider(group.id));
      }
    }
  }
}

class _MemberTile extends StatelessWidget {
  final GroupMember member;
  final int rank;
  final bool isMe;
  final int streakGoal;
  const _MemberTile({
    required this.member,
    required this.rank,
    required this.isMe,
    required this.streakGoal,
  });

  String _anonymousName(String uid) {
    final prefixes = [
      'ত্বালিব', 'মুতাআল্লিম', 'হাফিজ', 'সাইয়িদ', 'আবু', 'উম্মু'
    ];
    final suffixes = [
      'আল-ইলম', 'আল-হুদা', 'আল-কুরআন', 'আল-নূর', 'আল-ফুরকান'
    ];
    final h = uid.hashCode.abs();
    return '${prefixes[h % prefixes.length]} ${suffixes[(h ~/ 7) % suffixes.length]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : '$rank.';
    final metGoal =
        streakGoal > 0 && member.currentStreak >= streakGoal;
    final name = isMe ? 'আপনি' : _anonymousName(member.userId);

    return Card(
      elevation: isMe ? 1 : 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isMe
            ? BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.4))
            : BorderSide(
                color:
                    theme.colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                medal,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isMe
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (metGoal) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '✓ লক্ষ্য পূরণ',
                            style: TextStyle(
                                fontSize: 10, color: Colors.green),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${member.totalXp} XP',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '🔥 ${member.currentStreak}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'দিন',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
