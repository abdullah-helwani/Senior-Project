import 'package:dio/dio.dart';
import 'package:first_try/core/api/dio_consumer.dart';
import 'package:first_try/core/router/go_router_refresh_stream.dart';
import 'package:first_try/core/router/route_name.dart';
import 'package:first_try/core/theme/app_motion.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_state.dart';
import 'package:first_try/features/auth/presentation/screens/login_screen.dart';
import 'package:first_try/features/auth/presentation/screens/splash_screen.dart';
import 'package:first_try/features/driver/data/repos/driver_repo.dart';
import 'package:first_try/features/driver/presentation/cubit/trip_detail_cubit.dart';
import 'package:first_try/features/driver/presentation/screens/driver_shell_screen.dart';
import 'package:first_try/features/driver/presentation/screens/trip_detail_screen.dart';
import 'package:first_try/features/parent/presentation/screens/parent_shell_screen.dart';
import 'package:first_try/features/student/presentation/screens/student_shell_screen.dart';
import 'package:first_try/features/teacher/presentation/screens/teacher_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Wraps a route in a soft fade-through transition. Used for the auth flow
/// (splash → login → role home) where a snap or slide feels jarring.
CustomTransitionPage<T> _fadePage<T>({required Widget child, LocalKey? key}) {
  return CustomTransitionPage<T>(
    key: key,
    transitionDuration: Motion.medium,
    reverseTransitionDuration: Motion.fast,
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      final fade = CurvedAnimation(parent: animation, curve: Motion.standard);
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          // Subtle zoom-in so the next screen feels like it's stepping
          // forward, not just appearing.
          scale: Tween<double>(begin: 0.985, end: 1).animate(fade),
          child: child,
        ),
      );
    },
  );
}

class AppRouter {
  static GoRouter createRouter(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: GoRouterRefreshStream(authCubit.stream),

      // ── Role-based redirect ───────────────────────────────────────────────
      redirect: (context, state) {
        final authState = authCubit.state;
        final location  = state.uri.path;

        if (authState is AuthInitial || authState is AuthLoading) {
          return location == '/splash' ? null : '/splash';
        }

        if (authState is AuthUnauthenticated || authState is AuthError) {
          return location == '/login' ? null : '/login';
        }

        if (authState is AuthAuthenticated) {
          final role = authState.user.roleType;
          // Admin has no mobile shell — send them back to login and sign them out.
          // (Admin uses the web dashboard in admin-dashboard/.)
          const mobileRoles = {'student', 'teacher', 'parent', 'driver'};
          if (!mobileRoles.contains(role)) {
            authCubit.forceLogout();
            return '/login';
          }
          final home = '/$role';
          if (location == '/splash' || location == '/login') return home;

          // Cross-role guard: a student cannot visit /teacher, etc.
          // Send them to their own home if they try.
          for (final otherRole in mobileRoles) {
            if (otherRole != role && location.startsWith('/$otherRole')) {
              return home;
            }
          }
        }

        return null;
      },

      // ── Route table ──────────────────────────────────────────────────────
      routes: [
        GoRoute(
          path: '/splash',
          name: RouteName.splash,
          pageBuilder: (context, _) => _fadePage(child: const SplashScreen()),
        ),
        GoRoute(
          path: '/login',
          name: RouteName.login,
          pageBuilder: (context, _) => _fadePage(child: const LoginScreen()),
        ),
        GoRoute(
          path: '/student',
          name: RouteName.studentHome,
          pageBuilder: (context, _) =>
              _fadePage(child: const StudentShellScreen()),
        ),
        GoRoute(
          path: '/teacher',
          name: RouteName.teacherHome,
          pageBuilder: (context, _) =>
              _fadePage(child: const TeacherShellScreen()),
        ),
        GoRoute(
          path: '/parent',
          name: RouteName.parentHome,
          pageBuilder: (context, _) =>
              _fadePage(child: const ParentShellScreen()),
        ),

        // ── Driver ──────────────────────────────────────────────────────────
        GoRoute(
          path: '/driver',
          name: RouteName.driverHome,
          pageBuilder: (context, _) =>
              _fadePage(child: const DriverShellScreen()),
          routes: [
            GoRoute(
              path: 'trip/:tripId',
              name: RouteName.driverTripDetail,
              builder: (context, state) {
                final tripId = int.tryParse(
                        state.pathParameters['tripId'] ?? '') ??
                    0;
                final authState = authCubit.state;
                final driverId = authState is AuthAuthenticated
                    ? authState.user.id
                    : 0;
                final repo =
                    DriverRepo(api: DioConsumer(dio: Dio()));

                return BlocProvider(
                  create: (_) => TripDetailCubit(
                    repo: repo,
                    driverId: driverId,
                    tripId: tripId,
                  )..loadTrip(),
                  child: TripDetailScreen(tripId: tripId),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
