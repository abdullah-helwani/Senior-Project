import 'package:dio/dio.dart';
import 'package:first_try/core/api/dio_consumer.dart';
import 'package:first_try/core/widgets/shared/animated_shell.dart';
import 'package:first_try/features/auth/current_user.dart';
import 'package:first_try/features/student/data/repos/student_repo.dart';
import 'package:first_try/features/student/presentation/cubit/attendance_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/bus_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/dashboard_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/homework_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/marks_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/notifications_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/schedule_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/student_profile_cubit.dart';
import 'package:first_try/features/student/presentation/screens/student_academics_screen.dart';
import 'package:first_try/features/student/presentation/screens/student_bus_screen.dart';
import 'package:first_try/features/student/presentation/screens/student_home_screen.dart';
import 'package:first_try/features/student/presentation/screens/student_notifications_screen.dart';
import 'package:first_try/features/student/presentation/screens/student_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentShellScreen extends StatefulWidget {
  const StudentShellScreen({super.key});

  @override
  State<StudentShellScreen> createState() => _StudentShellScreenState();
}

class _StudentShellScreenState extends State<StudentShellScreen> {
  int _currentIndex = 0;

  late final StudentRepo _repo;
  late final DashboardCubit _dashboardCubit;
  late final MarksCubit _marksCubit;
  late final ScheduleCubit _scheduleCubit;
  late final HomeworkCubit _homeworkCubit;
  late final AttendanceCubit _attendanceCubit;
  late final NotificationsCubit _notificationsCubit;
  late final BusCubit _busCubit;
  late final StudentProfileCubit _profileCubit;

  @override
  void initState() {
    super.initState();
    final studentId = context.currentRoleId;

    _repo = StudentRepo(api: DioConsumer(dio: Dio()), studentId: studentId);

    _dashboardCubit     = DashboardCubit(repo: _repo)..load();
    _marksCubit         = MarksCubit(repo: _repo)..load();
    _scheduleCubit      = ScheduleCubit(repo: _repo)..load();
    _homeworkCubit      = HomeworkCubit(repo: _repo)..load();
    _attendanceCubit    = AttendanceCubit(repo: _repo)..load();
    _notificationsCubit = NotificationsCubit(repo: _repo)..load();
    _busCubit           = BusCubit(repo: _repo)..load();
    _profileCubit       = StudentProfileCubit(repo: _repo)..load();
  }

  @override
  void dispose() {
    _dashboardCubit.close();
    _marksCubit.close();
    _scheduleCubit.close();
    _homeworkCubit.close();
    _attendanceCubit.close();
    _notificationsCubit.close();
    _busCubit.close();
    _profileCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _dashboardCubit),
        BlocProvider.value(value: _marksCubit),
        BlocProvider.value(value: _scheduleCubit),
        BlocProvider.value(value: _homeworkCubit),
        BlocProvider.value(value: _attendanceCubit),
        BlocProvider.value(value: _notificationsCubit),
        BlocProvider.value(value: _busCubit),
        BlocProvider.value(value: _profileCubit),
      ],
      child: Scaffold(
        body: AnimatedShell(
          index: _currentIndex,
          children: const [
            StudentHomeScreen(),
            StudentAcademicsScreen(),
            StudentNotificationsScreen(),
            StudentBusScreen(),
            StudentProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school_rounded),
              label: 'Academics',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications_rounded),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.directions_bus_outlined),
              selectedIcon: Icon(Icons.directions_bus_rounded),
              label: 'Bus',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
