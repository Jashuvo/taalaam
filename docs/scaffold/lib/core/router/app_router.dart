import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../features/admin/presentation/admin_home_page.dart';
import '../../features/admin/presentation/admin_review_page.dart';
import '../../features/admin/presentation/admin_upload_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/home/presentation/home_page.dart';

// Manual provider — avoids riverpod_generator/analyzer_plugin version conflict
final appRouterProvider =
    Provider.family<GoRouter, AppFlavor>((ref, flavor) {
  return GoRouter(
    initialLocation: flavor == AppFlavor.admin ? '/admin' : '/home',
    routes: [
      // ── Auth ─────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),

      // ── Learner ──────────────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomePage(),
      ),
      GoRoute(
        path: '/track/:trackId',
        builder: (_, state) => _stub(
          'Track: ${state.pathParameters['trackId']}',
          'Track view — Phase 1 coming soon',
        ),
      ),
      GoRoute(
        path: '/lesson/:lessonId',
        builder: (_, __) => _stub(
          'Lesson',
          'Lesson Engine — Phase 1 coming soon',
          back: '/home',
        ),
      ),
      GoRoute(
        path: '/review',
        builder: (_, __) =>
            _stub('Daily Review', 'SRS Review — Phase 1 coming soon'),
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
                builder: (_, state) => _stub(
                  'Review Unit',
                  'Unit ID: ${state.pathParameters['unitId']}',
                  back: '/admin/review',
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

_StubPage _stub(String title, String body, {String? back}) =>
    _StubPage(title: title, body: body, back: back);

class _StubPage extends StatelessWidget {
  final String title;
  final String body;
  final String? back;
  const _StubPage({required this.title, required this.body, this.back});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: back != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(back!),
              )
            : null,
      ),
      body: Center(
        child: Text(body, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
