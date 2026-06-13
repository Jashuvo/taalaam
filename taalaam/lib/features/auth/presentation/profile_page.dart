import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tap_scale.dart';
import '../../../shared/utils/bn_digits.dart';
import '../../../shared/utils/xp_level.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/misbaha/ornament_stamp.dart';
import '../../../shared/widgets/progress_share_card.dart';
import '../../home/presentation/home_provider.dart';
import '../../home/presentation/widgets/streak_goal_progress_widget.dart';
import 'auth_provider.dart';

/// The "আমি" (Me) tab — single source of truth for the profile UI,
/// matching the demo's `.pf` profile section (no back header; this *is*
/// a top-level tab).
class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab>
    with SingleTickerProviderStateMixin {
  String? _displayName;
  bool _loadingName = true;
  late final AnimationController _entranceCtrl;

  // Staggered reveal order: tier card -> action buttons -> weekly streak ->
  // badges -> stat grid -> streak goal -> bookmarks.
  static const _staggerCount = 7;
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
    final weeklyXp = ref.watch(weeklyXpProvider).valueOrNull ?? 0;
    final masteredCount = ref.watch(masteredWordCountProvider).valueOrNull ?? 0;
    final accuracyMap = ref.watch(lessonAccuracyMapProvider).valueOrNull ?? {};
    final avgAccuracy = accuracyMap.isEmpty
        ? 0
        : (accuracyMap.values.reduce((a, b) => a + b) / accuracyMap.length).round();
    final perfectRuns = accuracyMap.values.where((v) => v >= 100).length;
    final bookmarkCount =
        ref.watch(bookmarkedLessonIdsProvider).valueOrNull?.length ?? 0;
    final totalXp = streak?.totalXp ?? 0;
    final tier = XpLevel.forXp(totalXp);
    final longestStreak = streak?.longestStreak ?? 0;
    final badges = <_BadgeData>[
      if (longestStreak >= 7) const _BadgeData('🔥', '৭ দিনের ধারা'),
      if (longestStreak >= 30) const _BadgeData('🔥', '৩০ দিনের ধারা'),
      if (perfectRuns >= 1) _BadgeData('💯', 'পারফেক্ট পাঠ · ${bnDigits(perfectRuns)}'),
      if (masteredCount >= 25) const _BadgeData('📚', 'শব্দ সংগ্রাহক'),
      if (masteredCount >= 100) const _BadgeData('📖', 'শব্দ পণ্ডিত'),
    ];
    final isAnon = user?.isAnonymous ?? false;

    final email = user?.email ?? '';
    final initials = _displayName?.isNotEmpty == true
        ? _displayName!.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, navClearance(context)),
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

          // ── Tier / level card ───────────────────────────────────────────
          _staggered(
            0,
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.gradientStreak,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.lgBorder,
                boxShadow: AppShadows.pop,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                    right: -10,
                    top: -22,
                    child: Opacity(
                      opacity: 0.13,
                      child: OrnamentStamp(size: 80, color: AppColors.gold),
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: tier.progressFraction(totalXp),
                              strokeWidth: 5,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                            ),
                            Text('${tier.level}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                tier.nameAr,
                                style: const TextStyle(
                                  fontFamily: 'NotoNaskhArabic',
                                  fontSize: 22,
                                  height: 1.8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(tier.nameBn,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              tier.maxXp == -1
                                  ? '${bnDigits(totalXp)} XP'
                                  : '${bnDigits(totalXp)} / ${bnDigits(tier.maxXp)} XP',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Action buttons ──────────────────────────────────────────────
          _staggered(
            1,
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'শেয়ার',
                    onTap: () => showProgressShareDialog(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.leaderboard_outlined,
                    label: 'র‍্যাংকিং',
                    onTap: () => context.go('/leaderboard'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.settings_outlined,
                    label: 'সেটিংস',
                    onTap: () => context.go('/settings'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Weekly streak calendar ──────────────────────────────────────
          _staggered(
            2,
            _WeeklyStreakCard(
              currentStreak: streak?.currentStreak ?? 0,
              lastActivityDate: streak?.lastActivityDate,
            ),
          ),
          const SizedBox(height: 10),

          // ── Badges ───────────────────────────────────────────────────────
          if (badges.isNotEmpty) ...[
            _staggered(
              3,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: badges
                    .map((b) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(b.emoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(b.label,
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── 2x2 stat grid ────────────────────────────────────────────────
          _staggered(
            4,
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _StatTile(
                  icon: Icons.menu_book_rounded,
                  color: AppColors.brightGreen,
                  value: masteredCount,
                  label: 'মুখস্থ শব্দ',
                ),
                _StatTile(
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.gold,
                  value: streak?.longestStreak ?? 0,
                  suffix: ' দিন',
                  label: 'সর্বোচ্চ ধারা',
                ),
                _StatTile(
                  icon: Icons.bar_chart_rounded,
                  color: AppColors.teal,
                  value: weeklyXp,
                  suffix: ' XP',
                  label: 'এই সপ্তাহের XP',
                ),
                _StatTile(
                  icon: Icons.track_changes_rounded,
                  color: AppColors.midGreen,
                  value: avgAccuracy,
                  suffix: '%',
                  label: 'সঠিকতার হার',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Streak goal calendar ─────────────────────────────────────────
          if ((streak?.streakGoal ?? 0) > 0) ...[
            _staggered(
              5,
              StreakGoalProgressWidget(
                currentStreak: streak?.currentStreak ?? 0,
                streakGoal: streak!.streakGoal!,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── Bookmarked lessons ───────────────────────────────────────────
          if (bookmarkCount > 0) ...[
            _staggered(
              6,
              TapScale(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: AppRadius.lgBorder,
                    onTap: () => context.go('/home'),
                    child: Container(
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
                            child: const Icon(Icons.bookmark_rounded,
                                color: AppColors.gold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                                'বুকমার্ক করা পাঠ · ${bnDigits(bookmarkCount)}টি',
                                style: theme.textTheme.bodyLarge),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
    );
  }
}

/// A derived achievement badge: an emoji and a short Bengali label.
class _BadgeData {
  final String emoji;
  final String label;
  const _BadgeData(this.emoji, this.label);
}

/// One of the three header action buttons (share / ranking / settings).
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TapScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.lgBorder,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(height: 4),
                Text(label, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tile of the 2x2 profile stat grid: icon in a tinted circle,
/// a value that counts up from 0 on first build, and a muted label.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String suffix;
  final String label;
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    this.suffix = '',
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const Spacer(),
          _CountUpStat(
            value: value,
            suffix: suffix,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// 7-day row showing which of the last 7 days were part of the user's
/// active streak (derived from currentStreak + lastActivityDate).
class _WeeklyStreakCard extends StatelessWidget {
  final int currentStreak;
  final DateTime? lastActivityDate;
  const _WeeklyStreakCard({required this.currentStreak, this.lastActivityDate});

  static const _dayLabels = {
    1: 'সোম', 2: 'মঙ্গল', 3: 'বুধ', 4: 'বৃহ', 5: 'শুক্র', 6: 'শনি', 7: 'রবি',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = lastActivityDate == null
        ? null
        : DateTime(
            lastActivityDate!.year, lastActivityDate!.month, lastActivityDate!.day);
    final streakStart = (last != null && currentStreak > 0)
        ? last.subtract(Duration(days: currentStreak - 1))
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('সাপ্তাহিক ধারা',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = today.subtract(Duration(days: 6 - i));
              final active = last != null &&
                  streakStart != null &&
                  !day.isBefore(streakStart) &&
                  !day.isAfter(last);
              final isToday = day == today;
              return Column(
                children: [
                  Text(_dayLabels[day.weekday] ?? '',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? AppColors.brightGreen
                          : theme.colorScheme.surfaceContainerHighest,
                      border: isToday
                          ? Border.all(color: AppColors.gold, width: 2)
                          : null,
                    ),
                    child: active
                        ? const Icon(Icons.local_fire_department_rounded,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
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
