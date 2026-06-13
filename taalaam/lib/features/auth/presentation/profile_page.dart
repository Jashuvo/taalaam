import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/misbaha/ornament_stamp.dart';
import '../../home/presentation/home_provider.dart';
import '../../home/presentation/widgets/streak_goal_progress_widget.dart';
import 'auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  String? _displayName;
  bool _loadingName = true;
  late final AnimationController _entranceCtrl;

  // Staggered reveal order: stat grid -> weekly XP -> streak goal -> longest streak.
  static const _staggerCount = 4;
  static final _entranceDuration = Duration(
    milliseconds: AppMotion.gentle.inMilliseconds +
        (_staggerCount - 1) * AppMotion.completionStagger.inMilliseconds,
  );

  @override
  void initState() {
    super.initState();
    _loadName();
    _entranceCtrl = AnimationController(vsync: this, duration: _entranceDuration);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _entranceCtrl.value = 1;
      } else {
        _entranceCtrl.forward();
      }
    });
  }

  Animation<double> _entranceFor(int index) {
    final staggerMs = AppMotion.completionStagger.inMilliseconds;
    final itemMs = AppMotion.gentle.inMilliseconds;
    final totalMs = _entranceDuration.inMilliseconds;
    final start = (index * staggerMs) / totalMs;
    final end = ((start * totalMs + itemMs) / totalMs).clamp(start, 1.0);
    return CurvedAnimation(
      parent: _entranceCtrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Widget _staggered(int index, Widget child) {
    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (context, c) {
        final v = _entranceFor(index).value;
        if (MediaQuery.of(context).disableAnimations) return c!;
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 16), child: c),
        );
      },
      child: child,
    );
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
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

  Future<void> _createAccount() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
          title: const Text('অ্যাকাউন্ট তৈরি করুন'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'ইমেইল'),
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)'),
                obscureText: true,
              ),
            ],
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
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('তৈরি করুন'),
                ),
              ],
            ),
          ],
        );
      },
    );
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();
    emailCtrl.dispose();
    passCtrl.dispose();
    if (saved != true) return;
    if (email.isEmpty || pass.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('সঠিক ইমেইল ও কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড দিন।')),
        );
      }
      return;
    }
    try {
      await ref.read(authServiceProvider).linkEmailAccount(email, pass);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('যাচাইকরণ লিংক ইমেইলে পাঠানো হয়েছে। ইমেইল চেক করুন।')),
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
    // Navigate to login the instant the user signs out — catches all sign-out paths
    ref.listen<User?>(currentUserProvider, (_, user) {
      if (user == null && context.mounted) context.go('/login');
    });

    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final streak = ref.watch(streakProvider).valueOrNull;
    final completedCount = ref.watch(completedLessonIdsProvider).valueOrNull?.length ?? 0;
    final weeklyXp = ref.watch(weeklyXpProvider).valueOrNull ?? 0;
    final masteredCount = ref.watch(masteredWordCountProvider).valueOrNull ?? 0;
    final learningCount = ref.watch(learningWordCountProvider).valueOrNull ?? 0;
    final isAnon = user?.isAnonymous ?? false;

    final email = user?.email ?? '';
    final initials = _displayName?.isNotEmpty == true
        ? _displayName!.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    return Scaffold(
      body: Column(
        children: [
          _ProfileHeader(onBack: () => context.go('/home')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
          // ── Avatar + name ──────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.colorScheme.primary, width: 2.5),
                  ),
                  child: CircleAvatar(
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

          // ── 2x3 metric grid ────────────────────────────────────────────
          _staggered(
            0,
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.gradientStreak,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.lgBorder,
              ),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 8,
                childAspectRatio: 0.95,
                children: [
                  _MetricTile(
                    icon: Icons.local_fire_department_rounded,
                    value: streak?.currentStreak ?? 0,
                    label: 'স্ট্রিক',
                  ),
                  _MetricTile(
                    icon: Icons.star_rounded,
                    value: streak?.totalXp ?? 0,
                    label: 'মোট XP',
                  ),
                  _MetricTile(
                    icon: Icons.task_alt_rounded,
                    value: completedCount,
                    label: 'পাঠ শেষ',
                  ),
                  _MetricTile(
                    icon: Icons.emoji_events_rounded,
                    value: streak?.longestStreak ?? 0,
                    label: 'সর্বোচ্চ ধারা',
                  ),
                  _MetricTile(
                    icon: Icons.menu_book_rounded,
                    value: masteredCount,
                    label: 'মুখস্থ শব্দ',
                  ),
                  _MetricTile(
                    icon: Icons.auto_stories_rounded,
                    value: learningCount,
                    label: 'শেখার শব্দ',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Weekly XP card ─────────────────────────────────────────────
          _staggered(
            1,
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: AppRadius.lgBorder,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brightGreen.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.bar_chart_rounded,
                        color: AppColors.brightGreen),
                  ),
                  const SizedBox(width: 12),
                  Text('এই সপ্তাহের XP', style: theme.textTheme.bodyLarge),
                  const Spacer(),
                  _CountUpStat(
                    value: weeklyXp,
                    suffix: ' XP',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brightGreen),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Streak goal calendar ───────────────────────────────────────
          if ((streak?.streakGoal ?? 0) > 0)
            _staggered(
              2,
              StreakGoalProgressWidget(
                currentStreak: streak?.currentStreak ?? 0,
                streakGoal: streak!.streakGoal!,
              ),
            ),
          if ((streak?.streakGoal ?? 0) > 0) const SizedBox(height: 10),

          // ── Longest streak highlight ───────────────────────────────────
          _staggered(
            3,
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: AppRadius.lgBorder,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: AppColors.gold),
                  ),
                  const SizedBox(width: 12),
                  Text('সর্বোচ্চ ধারা', style: theme.textTheme.bodyLarge),
                  const Spacer(),
                  _CountUpStat(
                    value: streak?.longestStreak ?? 0,
                    suffix: ' দিন',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.gold),
                  ),
                ],
              ),
            ),
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
                    onPressed: _createAccount,
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
          ),
        ],
      ),
    );
  }
}

/// Gradient header with ornament watermark, matching the leaderboard header.
class _ProfileHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _ProfileHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 6, 12, 15),
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
                  IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text('প্রোফাইল',
                    style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 2),
                child: Text('আপনার অগ্রগতি ও সেটিংস',
                    style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontSize: 11,
                        color: Color(0xBFF5F0E8))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One tile of the 2x3 profile metric grid: icon in a tinted circle,
/// a value that counts up from 0 on first build, and a muted label.
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  const _MetricTile(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(height: 6),
        _CountUpStat(
          value: value,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 11, color: Colors.white.withValues(alpha: 0.85)),
        ),
      ],
    );
  }
}

/// Stat value that counts up from 0 once on first build.
class _CountUpStat extends StatelessWidget {
  final int value;
  final String suffix;
  final TextStyle? style;
  const _CountUpStat({required this.value, this.suffix = '', this.style});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: reduceMotion ? value : 0, end: value),
      duration: reduceMotion ? Duration.zero : AppMotion.statCountUp,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$v$suffix', style: style),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(
            color: isDark ? AppColors.darkOutlineVariant : AppColors.line),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
