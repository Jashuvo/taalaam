import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/home/presentation/home_provider.dart';
import 'features/home/presentation/settings_page.dart';

enum AppFlavor { learner, admin }

class TaalamaApp extends ConsumerWidget {
  final AppFlavor flavor;
  const TaalamaApp({required this.flavor, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider(flavor));

    // Kick off background sync on app start (fire and forget)
    ref.read(syncServiceProvider).syncTracks().ignore();

    // Restore user data from Supabase whenever a session is established
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      final event = next.valueOrNull?.event;
      final userId = next.valueOrNull?.session?.user.id;
      if (userId != null &&
          (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed)) {
        ref.read(syncServiceProvider).restoreUserData(userId).ignore();
      }
    });

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: "Ta'allam — تعلَّم",
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('bn'),
        Locale('ar'),
        Locale('en'),
      ],
    );
  }
}
