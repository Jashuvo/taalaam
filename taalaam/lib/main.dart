import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'shared/services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  final analytics = await AnalyticsService.init();

  Future<void> launchApp() async {
    runApp(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(analytics),
        ],
        child: const TaalamaApp(flavor: AppFlavor.learner),
      ),
    );
  }

  if (AppConstants.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConstants.sentryDsn;
        options.tracesSampleRate = 0.2;
        options.debug = false;
      },
      appRunner: launchApp,
    );
  } else {
    await launchApp();
  }
}
