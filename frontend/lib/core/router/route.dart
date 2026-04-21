import 'package:dio/dio.dart';
import 'package:first_try/core/api/dio_consumer.dart';
import 'package:first_try/core/router/go_router_refresh_stream.dart';
import 'package:first_try/core/router/route_name.dart';
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
          final home = '/${authState.user.roleType}';
          if (location == '/splash' || location == '/login') return home;
        }

        return null;
      },

      // ── Route table ──────────────────────────────────────────────────────
      routes: [
        GoRoute(
          path: '/splash',
          name: RouteName.splash,
          builder: (context, _) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          name: RouteName.login,
          builder: (context, _) => const LoginScreen(),
        ),
        GoRoute(
          path: '/student',
          name: RouteName.studentHome,
          builder: (context, _) => const StudentShellScreen(),
        ),
        GoRoute(
          path: '/teacher',
          name: RouteName.teacherHome,
          builder: (context, _) => const TeacherShellScreen(),
        ),
        GoRoute(
          path: '/parent',
          name: RouteName.parentHome,
          builder: (context, _) => const ParentShellScreen(),
        ),

        // ── Driver ──────────────────────────────────────────────────────────
        GoRoute(
          path: '/driver',
          name: RouteName.driverHome,
          builder: (context, _) => const DriverShellScreen(),
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
