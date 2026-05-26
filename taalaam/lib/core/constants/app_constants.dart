class AppConstants {
  AppConstants._();

  // Injected via --dart-define at build time
  static const supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // Optional Phase 2 infrastructure (set via --dart-define to enable)
  static const sentryDsn =
      String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  static const posthogKey =
      String.fromEnvironment('POSTHOG_KEY', defaultValue: '');
  static const posthogHost =
      String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://app.posthog.com');

  // Gamification
  static const int heartsPerLesson = 5;
  static const int xpPerExercise = 5;
  static const int xpCompletionBonus = 10;

  // SRS
  static const int maxDailyReviews = 50;

  // Tracks
  static const String trackConversational = 'conversational';
  static const String trackQuranic = 'quranic';

  // Sync
  static const Duration syncInterval = Duration(seconds: 30);

  // Bangla error messages (shown to user)
  static const String kNetworkErrorBn =
      'ইন্টারনেট সংযোগ নেই। অফলাইনে শেখা চলবে।';
  static const String kSyncErrorBn =
      'ডেটা সংরক্ষণে সমস্যা হয়েছে। পুনরায় চেষ্টা করুন।';
  static const String kLoadErrorBn =
      'পাঠ লোড হচ্ছে না। অনুগ্রহ করে অপেক্ষা করুন।';

  // Du'aa shown on lesson completion (rotating)
  static const List<String> completionDuaas = [
    'بَارَكَ اللَّهُ فِيكَ — আল্লাহ আপনার মধ্যে বরকত দিন',
    'جَزَاكَ اللَّهُ خَيْرًا — আল্লাহ আপনাকে উত্তম প্রতিদান দিন',
    'وَفَّقَكَ اللَّهُ — আল্লাহ আপনাকে তাওফিক দিন',
    'زَادَكَ اللَّهُ عِلْمًا — আল্লাহ আপনার জ্ঞান বৃদ্ধি করুন',
  ];

  // Test Arabic text for RTL verification
  static const String arabicTestText = 'هُوَ أُسْتَاذٌ جَدِيدٌ';
}
