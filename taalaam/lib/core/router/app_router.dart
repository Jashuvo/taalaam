import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../features/admin/presentation/admin_dashboard_page.dart';
import '../../features/admin/presentation/admin_home_page.dart';
import '../../features/admin/presentation/admin_review_page.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/admin/presentation/admin_unit_review_page.dart';
import '../../features/admin/presentation/admin_upload_page.dart';
import '../../features/admin/presentation/admin_users_page.dart';
import '../../features/auth/presentation/admin_login_page.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/onboarding_page.dart';
import '../../features/auth/presentation/profile_page.dart';
import '../../features/auth/presentation/streak_goal_page.dart';
import '../../features/lesson/presentation/exam_screen.dart';
import '../../features/home/presentation/main_shell.dart';
import '../../features/home/presentation/leaderboard_page.dart';
import '../../features/home/presentation/settings_page.dart';
import '../../features/home/presentation/track_detail_page.dart';
import '../../features/lesson/presentation/lesson_screen.dart';
import '../../features/srs/presentation/memorize_screen.dart';
import '../../features/srs/presentation/review_screen.dart';
import '../../features/community/presentation/group_detail_page.dart';
import '../../features/community/presentation/groups_page.dart';
import '../../features/track_conv/presentation/conversation_screen.dart';
import '../../features/track_quran/presentation/quran_word_reader_page.dart';
import '../../features/track_quran/presentation/tafsir_reader_page.dart';

// Manual provider — avoids riverpod_generator/analyzer_plugin version conflict
final appRouterProvider =
    Provider.family<GoRouter, AppFlavor>((ref, flavor) {
  final isAdmin = flavor == AppFlavor.admin;

  final router = GoRouter(
    initialLocation: isAdmin ? '/admin' : '/login',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/') return '/login';

      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return loc == '/login' ? null : '/login';

      final user = ref.read(currentUserProvider);
      final isLoggedIn = user != null;
      final goingToLogin = loc == '/login';

      // ── Learner flavor: hard-block any /admin path ──────────────────
      if (!isAdmin && loc.startsWith('/admin')) return '/home';

      // ── Admin flavor: hard-block non-admin, non-login paths ─────────
      if (isAdmin && !loc.startsWith('/admin') && !goingToLogin) {
        return '/admin';
      }

      if (!isLoggedIn && !goingToLogin) return '/login';

      // Admin flavor: non-admin account → back to login
      if (isAdmin && isLoggedIn && !ref.read(isAdminProvider)) {
        return '/login';
      }

      // After login, go to the right home screen
      if (isLoggedIn && goingToLogin) {
        return isAdmin ? '/admin' : '/home';
      }

      return null;
    },
    routes: [
      // ── Shared: login ────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) =>
            isAdmin ? const AdminLoginPage() : const LoginPage(),
      ),

      // ── Learner-only routes ──────────────────────────────────────────
      if (!isAdmin) ...[
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingPage(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const MainShell(),
        ),
        GoRoute(
          path: '/track/:trackId',
          builder: (_, state) =>
              TrackDetailPage(slug: state.pathParameters['trackId']!),
        ),
        GoRoute(
          path: '/lesson/:lessonId',
          builder: (_, state) =>
              LessonScreen(lessonId: state.pathParameters['lessonId']!),
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
          path: '/profile',
          builder: (_, __) => const ProfilePage(),
        ),
        GoRoute(
          path: '/exam/:examLessonId',
          builder: (_, state) =>
              ExamScreen(examLessonId: state.pathParameters['examLessonId']!),
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
          builder: (_, state) =>
              GroupDetailPage(groupId: state.pathParameters['groupId']!),
        ),
        GoRoute(
          path: '/tafsir/:lessonId',
          builder: (_, state) =>
              TafsirReaderPage(lessonId: state.pathParameters['lessonId']!),
        ),
        GoRoute(
          path: '/streak-goal',
          builder: (_, __) => const StreakGoalPage(),
        ),
        GoRoute(
          path: '/quran-reader',
          builder: (_, __) => const QuranWordReaderPage(),
        ),
      ],

      // ── Admin-only routes ────────────────────────────────────────────
      if (isAdmin) ...[
        // Shell wraps dashboard, content review, upload, users
        ShellRoute(
          builder: (context, state, child) => AdminShell(
            currentLocation: state.matchedLocation,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/admin',
              builder: (_, __) => const AdminDashboardPage(),
            ),
            GoRoute(
              path: '/admin/home',
              builder: (_, __) => const AdminHomePage(),
            ),
            GoRoute(
              path: '/admin/review',
              builder: (_, __) => const AdminReviewPage(),
            ),
            GoRoute(
              path: '/admin/upload',
              builder: (_, __) => const AdminUploadPage(),
            ),
            GoRoute(
              path: '/admin/users',
              builder: (_, __) => const AdminUsersPage(),
            ),
          ],
        ),

        // Full-page (no shell) — unit detail editor
        GoRoute(
          path: '/admin/review/:unitId',
          builder: (_, state) => AdminUnitReviewPage(
            unitId: state.pathParameters['unitId']!,
          ),
        ),
      ],
    ],
  );

  ref.listen(authStateProvider, (_, __) => router.refresh());
  return router;
});
