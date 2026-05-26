import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

enum AppFlavor { learner, admin }

class TaalamaApp extends ConsumerWidget {
  final AppFlavor flavor;
  const TaalamaApp({required this.flavor, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider(flavor));
    return MaterialApp.router(
      title: "Ta'allam — تعلَّم",
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        // Add flutter_localizations delegates when needed
      ],
    );
  }
}
