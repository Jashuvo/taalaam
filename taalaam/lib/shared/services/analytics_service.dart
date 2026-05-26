import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../../core/constants/app_constants.dart';

class AnalyticsService {
  final bool _enabled;
  AnalyticsService({required bool enabled}) : _enabled = enabled;

  static Future<AnalyticsService> init() async {
    if (AppConstants.posthogKey.isEmpty) {
      return AnalyticsService(enabled: false);
    }
    final config = PostHogConfig(AppConstants.posthogKey);
    config.host = AppConstants.posthogHost;
    config.debug = false;
    await Posthog().setup(config);
    return AnalyticsService(enabled: true);
  }

  Future<void> identify(String userId, {Map<String, Object>? props}) async {
    if (!_enabled) return;
    await Posthog().identify(userId: userId, userProperties: props);
  }

  Future<void> track(String event, {Map<String, Object>? props}) async {
    if (!_enabled) return;
    await Posthog().capture(eventName: event, properties: props);
  }

  Future<void> reset() async {
    if (!_enabled) return;
    await Posthog().reset();
  }
}

// Overridden in main.dart via ProviderScope(overrides: [...])
final analyticsServiceProvider = Provider<AnalyticsService>(
  (_) => AnalyticsService(enabled: false),
);
