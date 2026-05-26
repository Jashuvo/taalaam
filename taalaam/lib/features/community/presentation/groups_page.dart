import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';
import 'groups_provider.dart';

class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.isAnonymous == true) {
      return Scaffold(
        appBar: AppBar(title: const Text('হালাকা গ্রুপ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👥', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'গ্রুপে যোগ দিতে অ্যাকাউন্ট তৈরি করুন।',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('লগইন / নিবন্ধন'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _GroupsBody(userId: user.id);
  }
}

class _GroupsBody extends ConsumerWidget {
  final String userId;
  const _GroupsBody({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('হালাকা গ্রুপ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'নতুন গ্রুপ',
            onPressed: () => _showCreateDialog(context, ref, userId),
          ),
        ],
      ),
      body: Column(
        children: [
          // Join by code bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _JoinByCodeBar(userId: userId),
          ),
          Expanded(
            child: groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('গ্রুপ লোড হয়নি।',
                    style: TextStyle(color: theme.colorScheme.error)),
              ),
              data: (groups) => groups.isEmpty
                  ? _EmptyState(userId: userId)
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: groups.length,
                      itemBuilder: (_, i) =>
                          _GroupTile(group: groups[i], userId: userId),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(
      BuildContext context, WidgetRef ref, String userId) async {
    final nameCtrl = TextEditingController();
    final goalCtrl = TextEditingController(text: '0');
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('নতুন হালাকা তৈরি করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'গ্রুপের নাম',
                hintText: 'যেমন: সকালের হালাকা',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: goalCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'স্ট্রিক লক্ষ্য (দিন)',
                hintText: '০ = কোনো লক্ষ্য নেই',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('বাতিল')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('তৈরি করুন')),
        ],
      ),
    );
    if (result != true || !context.mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    final goal = int.tryParse(goalCtrl.text) ?? 0;
    final notifier = ref.read(groupsNotifierProvider(userId).notifier);
    final groupId = await notifier.createGroup(name, streakGoal: goal);
    if (context.mounted && groupId != null) {
      ref.invalidate(myGroupsProvider);
      context.go('/groups/$groupId');
    }
  }
}

class _JoinByCodeBar extends ConsumerStatefulWidget {
  final String userId;
  const _JoinByCodeBar({required this.userId});

  @override
  ConsumerState<_JoinByCodeBar> createState() => _JoinByCodeBarState();
}

class _JoinByCodeBarState extends ConsumerState<_JoinByCodeBar> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _ctrl.text.trim();
    if (code.length < 6) return;
    setState(() => _loading = true);
    final notifier =
        ref.read(groupsNotifierProvider(widget.userId).notifier);
    final groupId = await notifier.joinByCode(code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (groupId != null) {
      _ctrl.clear();
      ref.invalidate(myGroupsProvider);
      context.go('/groups/$groupId');
    } else {
      final err = ref.read(groupsNotifierProvider(widget.userId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(err.error?.toString() ?? 'যোগ দেওয়া যায়নি।')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: const InputDecoration(
              counterText: '',
              prefixIcon: Icon(Icons.key_outlined),
              hintText: 'আমন্ত্রণ কোড দিন (৬ অক্ষর)',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            onSubmitted: (_) => _join(),
          ),
        ),
        const SizedBox(width: 8),
        _loading
            ? const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 2))
            : FilledButton(
                onPressed: _join,
                child: const Text('যোগ দিন'),
              ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String userId;
  const _EmptyState({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🕌', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              'এখনো কোনো গ্রুপে নেই।',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'উপরের + বাটনে নতুন হালাকা তৈরি করুন,\nঅথবা কোড দিয়ে যোগ দিন।',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends ConsumerWidget {
  final GroupModel group;
  final String userId;
  const _GroupTile({required this.group, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(groupMemberCountProvider(group.id));
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/groups/${group.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🕌', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    countAsync.when(
                      data: (count) => Text(
                        '$count সদস্য${group.streakGoal > 0 ? " · লক্ষ্য: ${group.streakGoal} দিন 🔥" : ""}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'কোড: ${group.inviteCode}',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
