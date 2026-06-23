import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/otp_verification_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/routines/routines_screen.dart';
import '../../features/duo/invite_screen.dart';
import '../../features/workout/workout_screen.dart';
import '../../features/growth/growth_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/goals/create_goal_screen.dart';
import '../../features/goals/goal_details_screen.dart';
import '../../features/goals/category_detail_screen.dart';
import '../../features/workout/active_session_screen.dart';
import 'route_names.dart';

/// Top-level router configuration for Tandem.
///
/// Uses [StatefulShellRoute] for persistent bottom-tab navigation and
/// nested [GoRoute]s for sub-pages that push on the tab stack.
/// Auth routes (splash, login, signup, onboarding) sit outside the shell.
///
/// Tab order: Home → Routines → Growth → Workouts → Profile
final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  debugLogDiagnostics: false,
  routes: [
    // ─── Auth routes (full-screen, no shell) ─────────────────────
    GoRoute(
      name: 'splash',
      path: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      name: 'login',
      path: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      name: 'signup',
      path: RouteNames.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      name: 'onboarding',
      path: RouteNames.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      name: 'otp-verification',
      path: '/otp-verification',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return OtpVerificationScreen(email: email);
      },
    ),

    // ─── Main shell with bottom navigation ───────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0 — Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'home',
              path: RouteNames.home,
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  name: 'create-goal',
                  path: 'create-goal',
                  builder: (context, state) {
                    final category = state.uri.queryParameters['category'];
                    return CreateGoalScreen(initialCategory: category);
                  },
                ),
                GoRoute(
                  name: 'goal-details',
                  path: 'goal-details/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return GoalDetailsScreen(goalId: id);
                  },
                ),
                GoRoute(
                  name: 'category-detail',
                  path: 'category-detail/:category',
                  builder: (context, state) {
                    final category = state.pathParameters['category']!;
                    return CategoryDetailScreen(category: category);
                  },
                ),
              ],
            ),
          ],
        ),

        // Tab 1 — Routines (replaces Duo)
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'routines',
              path: RouteNames.routines,
              builder: (context, state) => const RoutinesScreen(),
              routes: [
                GoRoute(
                  name: 'invite',
                  path: 'invite',
                  builder: (context, state) => const InviteScreen(),
                ),
              ],
            ),
          ],
        ),

        // Tab 2 — Growth (replaces Stats)
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'growth',
              path: RouteNames.growth,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const GrowthScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurveTween(curve: Curves.easeInOut)
                        .animate(animation),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // Tab 3 — Workout
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'workout',
              path: RouteNames.workout,
              builder: (context, state) => const WorkoutScreen(),
              routes: [
                GoRoute(
                  name: 'active-session',
                  path: 'active-session',
                  builder: (context, state) => const ActiveSessionScreen(),
                ),
              ],
            ),
          ],
        ),

        // Tab 4 — Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'profile',
              path: RouteNames.profile,
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  name: 'settings',
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Scaffold wrapper that renders a persistent [NavigationBar] beneath the
/// current tab's [Navigator].
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  static const _tabs = <_TabItem>[
    _TabItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _TabItem(
      icon: Icons.replay_outlined,
      activeIcon: Icons.replay_rounded,
      label: 'Routines',
    ),
    _TabItem(
      icon: Icons.show_chart_outlined,
      activeIcon: Icons.show_chart_rounded,
      label: 'Growth',
    ),
    _TabItem(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center_rounded,
      label: 'Workouts',
    ),
    _TabItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        animationDuration: const Duration(milliseconds: 400),
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Lightweight struct for bottom-tab metadata.
class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
