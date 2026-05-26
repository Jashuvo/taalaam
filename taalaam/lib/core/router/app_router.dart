import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../features/admin/presentation/admin_home_page.dart';
import '../../features/admin/presentation/admin_review_page.dart';
import '../../features/admin/presentation/admin_upload_page.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/onboarding_page.dart';
import '../../features/admin/presentation/admin_unit_review_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/home/presentation/leaderboard_page.dart';
import '../../features/home/presentation/settings_page.dart';
import '../../features/home/presentation/track_detail_page.dart';
import '../../features/lesson/presentation/lesson_screen.dart';
import '../../features/srs/presentation/memorize_screen.dart';
import '../../features/srs/presentation/review_screen.dart';
import '../../features/community/presentation/group_detail_page.dart';
import '../../features/community/presentation/groups_page.dart';
import '../../features/track_conv/presentation/conversation_screen.dart';
import '../../features/track_quran/presentation/tafsir_reader_page.dart';

// Manual provider — avoids riverpod_generator/analyzer_plugin version conflict
final appRouterProvider =
    Provider.family<GoRouter, AppFlavor>((ref, flavor) {
  final router = GoRouter(
    initialLocation: flavor == AppFlavor.admin ? '/admin' : '/home',
    redirect: (context, state) async {
      final user = ref.read(currentUserProvider);
      final isLoggedIn = user != null;
      final loc = state.matchedLocation;
      final goingToLogin = loc == '/login';
      final goingToOnboarding = loc == '/onboarding';

      if (!isLoggedIn && !goingToLogin) return '/login';
      if (flavor == AppFlavor.admin && isLoggedIn && !ref.read(isAdminProvider)) {
        return '/login';
      }
      if (isLoggedIn && goingToLogin) {
        return flavor == AppFlavor.admin ? '/admin' : '/home';
      }
      // Onboarding gate: redirect new learner users on first login
      if (flavor == AppFlavor.learner && isLoggedIn && !goingToOnboarding) {
        final done = ref.read(onboardingDoneProvider).valueOrNull ?? true;
        if (!done) return '/onboarding';
      }
      return null;
    },
    routes: [
      // ── Auth ─────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),

      // ── Learner ──────────────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomePage(),
      ),
      GoRoute(
        path: '/track/:trackId',
        builder: (_, state) => TrackDetailPage(
          slug: state.pathParameters['trackId']!,
        ),
      ),
      GoRoute(
        path: '/lesson/:lessonId',
        builder: (_, state) => LessonScreen(
          lessonId: state.pathParameters['lessonId']!,
        ),
      ),
      GoRoute(
        path: '/review',
        builder: (_, __) => const ReviewScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (_, __) => const LeaderboardPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsPage(),
      ),
      GoRoute(
        path: '/conversation',
        builder: (_, __) => const ConversationScreen(),
      ),
      GoRoute(
        path: '/memorize',
        builder: (_, __) => const MemorizeScreen(),
      ),
      GoRoute(
        path: '/groups',
        builder: (_, __) => const GroupsPage(),
      ),
      GoRoute(
        path: '/groups/:groupId',
        builder: (_, state) => GroupDetailPage(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/tafsir/:lessonId',
        builder: (_, state) => TafsirReaderPage(
          lessonId: state.pathParameters['lessonId']!,
        ),
      ),

      // ── Admin ────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminHomePage(),
        routes: [
          GoRoute(
            path: 'upload',
            builder: (_, __) => const AdminUploadPage(),
          ),
          GoRoute(
            path: 'review',
            builder: (_, __) => const AdminReviewPage(),
            routes: [
              GoRoute(
                path: ':unitId',
                builder: (_, state) => AdminUnitReviewPage(
                  unitId: state.pathParameters['unitId']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.listen(authStateProvider, (_, __) => router.refresh());
  return router;
});

