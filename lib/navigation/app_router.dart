import 'package:go_router/go_router.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/admin/screens/admin_home_screen.dart';
import '../features/admin/screens/admin_users_screen.dart';
import '../features/admin/screens/admin_content_screen.dart';
import '../features/admin/screens/admin_tests_screen.dart';
import '../features/admin/screens/admin_create_test_screen.dart';
import '../features/admin/screens/admin_edit_test_screen.dart';
import '../features/admin/screens/admin_test_analytics_screen.dart';
import '../features/admin/screens/admin_settings_screen.dart';
import '../features/dashboard/screens/student_home_screen.dart';
import '../features/dashboard/screens/study_streak_screen.dart';
import '../features/dashboard/screens/performance_screen.dart';
import '../features/ai/screens/ai_teacher_screen.dart';
import '../features/mocktests/screens/mock_tests_screen.dart';
import '../features/mocktests/screens/test_taking_screen.dart';
import '../features/mocktests/screens/test_result_screen.dart';
import '../features/resources/screens/resources_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import 'student_tabs.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin/home',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/content',
        builder: (context, state) => const AdminContentScreen(),
      ),
      GoRoute(
        path: '/admin/tests',
        builder: (context, state) => const AdminTestsScreen(),
      ),
      GoRoute(
        path: '/admin/tests/create',
        builder: (context, state) => const AdminCreateTestScreen(),
      ),
      GoRoute(
        path: '/admin/tests/edit/:id',
        builder: (context, state) => AdminEditTestScreen(
          testId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin/tests/analytics',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AdminTestAnalyticsScreen(
            testId: extra['testId'] ?? '',
            testTitle: extra['testTitle'] ?? 'Analytics',
          );
        },
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: '/streak',
        builder: (context, state) => const StudyStreakScreen(),
      ),
      GoRoute(
        path: '/performance',
        builder: (context, state) => const PerformanceScreen(),
      ),
      GoRoute(
        path: '/test/:id/take',
        builder: (context, state) => TestTakingScreen(
          testId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/test/result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TestResultScreen(
            score: extra['score'] ?? 0,
            total: extra['total'] ?? 0,
            testTitle: extra['testTitle'] ?? 'Mock Test',
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StudentTabs(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const StudentHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai',
                builder: (context, state) => const AiTeacherScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mocktests',
                builder: (context, state) => const MockTestsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/resources',
                builder: (context, state) => const ResourcesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
