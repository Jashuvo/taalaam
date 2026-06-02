import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../home/presentation/home_provider.dart';
import 'auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String? _displayName;
  bool _loadingName = true;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await ref.read(authServiceProvider).getDisplayName();
    if (mounted) setState(() { _displayName = name; _loadingName = false; });
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _displayName ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
          title: const Text('নাম পরিবর্তন'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'আপনার নাম'),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('বাতিল')),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                  onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                  child: const Text('সংরক্ষণ'),
                ),
              ],
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    if (saved == null || saved.isEmpty) return;
    await ref.read(authServiceProvider).updateDisplayName(saved);
    setState(() => _displayName = saved);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('নাম আপডেট হয়েছে!')),
      );
    }
  }

  Future<void> _changePassword() async {
    final ctrl = TextEditingController();
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
          title: const Text('নতুন পাসওয়ার্ড'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'নতুন পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)'),
            obscureText: true,
            autofocus: true,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('বাতিল')),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                  onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                  child: const Text('পরিবর্তন করুন'),
                ),
              ],
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    if (saved == null || saved.length < 6) return;
    try {
      await ref.read(authServiceProvider).updatePassword(saved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('পাসওয়ার্ড পরিবর্তন হয়েছে!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ত্রুটি: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final streak = ref.watch(streakProvider).valueOrNull;
    final completedCount = ref.watch(completedLessonIdsProvider).valueOrNull?.length ?? 0;
    final isAnon = user?.isAnonymous ?? false;

    final email = user?.email ?? '';
    final initials = _displayName?.isNotEmpty == true
        ? _displayName!.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: const Text('প্রোফাইল'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ── Avatar + name ──────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_loadingName)
                  const SizedBox(
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _displayName ?? 'অতিথি',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (!isAnon) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          visualDensity: VisualDensity.compact,
                          onPressed: _editName,
                          tooltip: 'নাম পরিবর্তন',
                        ),
                      ],
                    ],
                  ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                if (isAnon)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'অস্থায়ী অ্যাকাউন্ট',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onTertiaryContainer),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Stats row ─────────────────────────────────────────────────
          Row(
            children: [
              _StatCard(
                icon: '🔥',
                value: '${streak?.currentStreak ?? 0}',
                label: 'স্ট্রিক',
                color: AppColors.gold,
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: '⭐',
                value: '${streak?.totalXp ?? 0}',
                label: 'মোট XP',
                color: AppColors.brightGreen,
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: '📖',
                value: '$completedCount',
                label: 'পাঠ শেষ',
                color: AppColors.tealLight,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Anonymous upgrade prompt ───────────────────────────────────
          if (isAnon) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: AppRadius.lgBorder,
                border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('অগ্রগতি সংরক্ষণ করুন',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'অ্যাকাউন্ট তৈরি করলে আপনার পাঠ, স্ট্রিক ও XP সব ডিভাইসে সুরক্ষিত থাকবে।',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('অ্যাকাউন্ট তৈরি করুন'),
                    onPressed: () => context.go('/login'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Account settings ──────────────────────────────────────────
          Text('অ্যাকাউন্ট',
              style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          _SettingsGroup(children: [
            if (!isAnon) ...[
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('পাসওয়ার্ড পরিবর্তন'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: _changePassword,
              ),
              Divider(
                  height: 1,
                  indent: 56,
                  color: theme.colorScheme.outlineVariant),
            ],
            ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: const Text('সাইন আউট'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'সাইন আউট',
                  body: 'আপনি কি সাইন আউট করতে চান?',
                );
                if (confirmed && context.mounted) {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/login');
                }
              },
            ),
          ]),
          const SizedBox(height: 16),
          if (!isAnon) ...[
            Text('বিপজ্জনক জোন',
                style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            _SettingsGroup(children: [
              ListTile(
                leading: Icon(Icons.delete_forever_outlined,
                    color: theme.colorScheme.error),
                title: Text('অ্যাকাউন্ট মুছুন',
                    style: TextStyle(color: theme.colorScheme.error)),
                subtitle: const Text('সমস্ত ডেটা স্থায়ীভাবে মুছে যাবে'),
                onTap: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'অ্যাকাউন্ট মুছবেন?',
                    body: 'আপনার সকল অগ্রগতি, স্ট্রিক এবং ডেটা স্থায়ীভাবে মুছে যাবে। এটি পূর্বাবস্থায় ফেরানো সম্ভব নয়।',
                    confirmLabel: 'মুছুন',
                    danger: true,
                  );
                  if (confirmed && context.mounted) {
                    await ref.read(authServiceProvider).deleteAccount();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),
            ]),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
