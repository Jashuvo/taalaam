import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _usersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await Supabase.instance.client.functions.invoke('admin-users');
  if (res.data == null) throw Exception('No data returned');
  final list = (res.data as Map)['users'] as List? ?? [];
  return list.cast<Map<String, dynamic>>();
});

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(_usersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: usersAsync.maybeWhen(
          data: (users) => Text('Users (${users.length})'),
          orElse: () => const Text('Users'),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(_usersProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by email or name…',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),

          // ── Table ────────────────────────────────────────────────────
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text('Failed to load users', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('$e', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: () => ref.invalidate(_usersProvider),
                    ),
                  ],
                ),
              ),
              data: (users) {
                final filtered = _query.isEmpty
                    ? users
                    : users.where((u) {
                        final email = (u['email'] as String? ?? '').toLowerCase();
                        final name  = (u['display_name'] as String? ?? '').toLowerCase();
                        return email.contains(_query) || name.contains(_query);
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _query.isEmpty ? 'No users found.' : 'No users match "$_query".',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                return _UsersTable(users: filtered);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersTable extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  const _UsersTable({required this.users});

  @override
  State<_UsersTable> createState() => _UsersTableState();
}

class _UsersTableState extends State<_UsersTable> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: widget.users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) {
        final u = widget.users[i];
        final isExpanded = _expandedIndex == i;
        return _UserRow(
          user: u,
          isExpanded: isExpanded,
          onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
        );
      },
    );
  }
}

class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isExpanded;
  final VoidCallback onTap;

  const _UserRow({required this.user, required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isAnon     = user['is_anonymous'] as bool? ?? false;
    final email      = user['email'] as String? ?? '';
    final name       = user['display_name'] as String?;
    final provider   = user['provider'] as String? ?? 'email';
    final streak     = user['current_streak'] as int? ?? 0;
    final xp         = user['total_xp'] as int? ?? 0;
    final done       = user['lessons_completed'] as int? ?? 0;
    final lastActive = user['last_active'] as String?;
    final createdAt  = user['created_at'] as String?;
    final lastSignIn = user['last_sign_in_at'] as String?;

    final displayLabel = isAnon
        ? 'Anonymous'
        : (email.isNotEmpty ? email : name ?? 'Unknown');

    final providerIcon = switch (provider) {
      'google' => Icons.g_mobiledata,
      'email'  => Icons.email_outlined,
      _        => Icons.person_outline,
    };

    return Material(
      color: isExpanded
          ? cs.primaryContainer.withValues(alpha: 0.18)
          : cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Main row ─────────────────────────────────────────────
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isAnon
                        ? cs.surfaceContainerHighest
                        : cs.primaryContainer,
                    child: Icon(
                      isAnon ? Icons.person_off_outlined : Icons.person_outline,
                      size: 18,
                      color: isAnon ? cs.onSurfaceVariant : cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Identity
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(
                              displayLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isAnon ? cs.onSurfaceVariant : null,
                                fontStyle: isAnon ? FontStyle.italic : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(providerIcon, size: 14, color: cs.onSurfaceVariant),
                        ]),
                        if (name != null && email.isNotEmpty)
                          Text(name, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),

                  // Compact stats
                  _MiniStat(icon: Icons.local_fire_department_outlined, value: '$streak', color: Colors.deepOrange),
                  const SizedBox(width: 10),
                  _MiniStat(icon: Icons.star_outline, value: '$xp', color: Colors.amber.shade700),
                  const SizedBox(width: 10),
                  _MiniStat(icon: Icons.task_alt_outlined, value: '$done', color: Colors.teal),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18, color: cs.onSurfaceVariant,
                  ),
                ],
              ),

              // ── Expanded detail ──────────────────────────────────────
              if (isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _DetailChip(label: 'User ID', value: (user['id'] as String).substring(0, 8) + '…'),
                    _DetailChip(label: 'Joined', value: _formatDate(createdAt)),
                    _DetailChip(label: 'Last Sign-in', value: _formatDate(lastSignIn)),
                    _DetailChip(label: 'Last Active', value: _formatDate(lastActive)),
                    _DetailChip(label: 'Max Streak', value: '${user['longest_streak'] ?? 0} days'),
                    _DetailChip(label: 'Provider', value: provider),
                    _DetailChip(label: 'Type', value: isAnon ? 'Anonymous' : 'Registered'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
      if (diff.inHours   < 24)  return '${diff.inHours}h ago';
      if (diff.inDays    < 30)  return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '—';
    }
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _MiniStat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ],
  );
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  const _DetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
