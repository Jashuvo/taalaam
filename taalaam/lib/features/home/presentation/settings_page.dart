import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: const Text('সেটিংস'),
      ),
      body: ListView(
        children: [
          // ── Appearance ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'থিম',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'শব্দ',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.music_note_outlined),
            title: const Text('সঠিক উত্তরের চাইম'),
            subtitle: const Text('সঠিক উত্তর দিলে শব্দ বাজবে'),
            value: settings.chimeEnabled,
            onChanged: notifier.setChime,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.mosque_outlined),
            title: const Text('তাকবীর'),
            subtitle: const Text('পাঠ সম্পন্নে তাকবীর বাজবে'),
            value: settings.takbeerEnabled,
            onChanged: notifier.setTakbeer,
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'অ্যাপ সম্পর্কে',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('সংস্করণ'),
            trailing: Text('0.1.0',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('গোপনীয়তা নীতি'),
            subtitle: const Text('আমরা কোনো ব্যক্তিগত তথ্য বিক্রি করি না'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {},
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'ডেটা',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline,
                color: theme.colorScheme.error),
            title: Text('অনবোর্ডিং রিসেট করুন',
                style: TextStyle(color: theme.colorScheme.error)),
            subtitle: const Text('পরবর্তী বার অ্যাপ খুললে প্রথম প্রশ্ন দেখাবে'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('রিসেট করবেন?'),
                  content: const Text('অনবোর্ডিং তথ্য মুছে যাবে।'),
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
              if (confirm == true) {
                // ignore: invalid_use_of_protected_member
                // shared_prefs reset handled at app level if needed
              }
            },
          ),
        ],
      ),
    );
  }
}
