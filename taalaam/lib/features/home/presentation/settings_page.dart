import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/utils/bn_digits.dart';
import '../../auth/presentation/auth_provider.dart';
import 'home_provider.dart';

const _kSoundChime   = 'sound_chime';
const _kSoundTakbeer = 'sound_takbeer';
const _kThemeMode    = 'theme_mode';

// ── Theme mode provider ────────────────────────────────────────────────────

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = switch (prefs.getString(_kThemeMode)) {
      'light'  => ThemeMode.light,
      'dark'   => ThemeMode.dark,
      _        => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode.name);
    state = mode;
  }
}

final soundSettingsProvider =
    StateNotifierProvider<SoundSettingsNotifier, SoundSettings>((ref) {
  return SoundSettingsNotifier();
});

class SoundSettings {
  final bool chimeEnabled;
  final bool takbeerEnabled;
  const SoundSettings({
    this.chimeEnabled = true,
    this.takbeerEnabled = true,
  });
  SoundSettings copyWith({bool? chimeEnabled, bool? takbeerEnabled}) =>
      SoundSettings(
        chimeEnabled: chimeEnabled ?? this.chimeEnabled,
        takbeerEnabled: takbeerEnabled ?? this.takbeerEnabled,
      );
}

class SoundSettingsNotifier extends StateNotifier<SoundSettings> {
  SoundSettingsNotifier() : super(const SoundSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SoundSettings(
      chimeEnabled: prefs.getBool(_kSoundChime) ?? true,
      takbeerEnabled: prefs.getBool(_kSoundTakbeer) ?? true,
    );
  }

  Future<void> setChime(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundChime, value);
    state = state.copyWith(chimeEnabled: value);
  }

  Future<void> setTakbeer(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundTakbeer, value);
    state = state.copyWith(takbeerEnabled: value);
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(soundSettingsProvider);
    final notifier = ref.read(soundSettingsProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final themeModeNotifier = ref.read(themeModeProvider.notifier);
    final streak = ref.watch(streakProvider).valueOrNull;
    final userId = ref.watch(currentUserProvider)?.id;
    final freezeCount = streak?.freezeCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: const Text('সেটিংস'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const _SectionHeader('থিম'),
          _SettingsCard(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('সিস্টেম'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('আলো'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('অন্ধকার'),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (modes) =>
                    themeModeNotifier.setMode(modes.first),
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                        borderRadius: AppRadius.lgBorder),
                  ),
                ),
              ),
            ),
          ]),
          const _SectionHeader('শব্দ'),
          _SettingsCard(children: [
            SwitchListTile(
              secondary: const Icon(Icons.music_note_outlined),
              title: const Text('সঠিক উত্তরের চাইম'),
              subtitle: const Text('সঠিক উত্তর দিলে শব্দ বাজবে'),
              value: settings.chimeEnabled,
              onChanged: notifier.setChime,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.lgBorder
                      .copyWith(bottomLeft: Radius.zero, bottomRight: Radius.zero)),
            ),
            Divider(
                height: 1,
                indent: 56,
                color: theme.colorScheme.outlineVariant),
            SwitchListTile(
              secondary: const Icon(Icons.mosque_outlined),
              title: const Text('তাকবীর'),
              subtitle: const Text('পাঠ সম্পন্নে তাকবীর বাজবে'),
              value: settings.takbeerEnabled,
              onChanged: notifier.setTakbeer,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.lgBorder
                      .copyWith(topLeft: Radius.zero, topRight: Radius.zero)),
            ),
          ]),
          const _SectionHeader('রিমাইন্ডার'),
          _SettingsCard(children: [
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('সালাহ-সচেতন নোটিফিকেশন'),
              subtitle: const Text(
                  'মাগরিবের ৩০ মিনিট পর মনে করিয়ে দেবে · শীঘ্রই আসছে'),
              value: false,
              onChanged: null,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
            ),
          ]),
          if (userId != null) ...[
            const _SectionHeader('ধারা সুরক্ষা'),
            _SettingsCard(children: [
              ListTile(
                leading: const Icon(Icons.ac_unit_rounded,
                    color: AppColors.teal),
                title: Text('স্ট্রিক ফ্রিজ · ${bnDigits(freezeCount)}টি আছে'),
                subtitle: const Text(
                    'একদিন মিস হলেও ধারা অটুট থাকবে'),
                trailing: FilledButton(
                  onPressed: freezeCount > 0
                      ? () async {
                          final used = await ref
                              .read(streakFreezeProvider(userId).notifier)
                              .useFreeze();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(used
                                  ? 'ফ্রিজ ব্যবহার করা হয়েছে — আপনার ধারা সুরক্ষিত!'
                                  : 'আপনার ধারা এখনই সুরক্ষিত — ফ্রিজের প্রয়োজন নেই।'),
                            ),
                          );
                        }
                      : null,
                  child: const Text('ব্যবহার করুন'),
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
              ),
            ]),
          ],
          const _SectionHeader('অ্যাপ সম্পর্কে'),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('সংস্করণ'),
              trailing: Text('0.1.0',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.lgBorder
                      .copyWith(bottomLeft: Radius.zero, bottomRight: Radius.zero)),
            ),
            Divider(
                height: 1,
                indent: 56,
                color: theme.colorScheme.outlineVariant),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('গোপনীয়তা নীতি'),
              subtitle: const Text('আমরা কোনো ব্যক্তিগত তথ্য বিক্রি করি না'),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              onTap: () {},
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.lgBorder
                      .copyWith(topLeft: Radius.zero, topRight: Radius.zero)),
            ),
          ]),
          const _SectionHeader('ডেটা'),
          _SettingsCard(children: [
            ListTile(
              leading:
                  Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text('অনবোর্ডিং রিসেট করুন',
                  style: TextStyle(color: theme.colorScheme.error)),
              subtitle: const Text('পরবর্তী বার অ্যাপ খুললে প্রথম প্রশ্ন দেখাবে'),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
              onTap: () async {
                final confirm = await showConfirmDialog(
                  context,
                  title: 'রিসেট করবেন?',
                  body: 'অনবোর্ডিং তথ্য মুছে যাবে।',
                  danger: true,
                );
                if (confirm) {
                  // shared_prefs onboarding reset handled at app level
                }
              },
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// `.sh2` — uppercase gold-deep section label.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'HindSiliguri',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: AppColors.goldDeep,
        ),
      ),
    );
  }
}

/// `.srow`-style card group.
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
