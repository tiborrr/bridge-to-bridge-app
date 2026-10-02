import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/trajectories_screen.dart';
import 'screens/trajectory_form_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/team_management_screen.dart';
import 'models/trajectory.dart';
import 'main.dart'; // For MainNavigationScreen

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MainNavigationScreen(initialIndex: 0);
      },
    ),
    GoRoute(
      path: '/history',
      builder: (BuildContext context, GoRouterState state) {
        return const MainNavigationScreen(initialIndex: 1);
      },
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (BuildContext context, GoRouterState state) {
        return const MainNavigationScreen(initialIndex: 2);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) {
        return const ProfileScreen();
      },
    ),
    GoRoute(
      path: '/team',
      builder: (BuildContext context, GoRouterState state) {
        return const TeamManagementScreen();
      },
    ),
    GoRoute(
      path: '/trajectories',
      builder: (BuildContext context, GoRouterState state) {
        return const TrajectoriesScreen();
      },
      routes: [
        GoRoute(
          path: 'new',
          builder: (BuildContext context, GoRouterState state) {
            return const TrajectoryFormScreen();
          },
        ),
        GoRoute(
          path: 'edit',
          builder: (BuildContext context, GoRouterState state) {
            final trajectory = state.extra as Trajectory?;
            return TrajectoryFormScreen(trajectory: trajectory);
          },
        ),
      ],
    ),
  ],
);
