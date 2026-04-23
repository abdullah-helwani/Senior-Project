import 'package:dio/dio.dart';
import 'package:first_try/core/api/dio_consumer.dart';
import 'package:first_try/features/auth/current_user.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_attendance_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_classes_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_dashboard_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_homework_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_notifications_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_profile_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_schedule_cubit.dart';
import 'package:first_try/features/teacher/presentation/screens/teacher_attendance_screen.dart';
import 'package:first_try/features/teacher/presentation/screens/teacher_classes_screen.dart';
import 'package:first_try/features/teacher/presentation/screens/teacher_home_screen.dart';
import 'package:first_try/features/teacher/presentation/screens/teacher_homework_screen.dart';
import 'package:first_try/features/teacher/presentation/screens/teacher_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherShellScreen extends StatefulWidget {
  const TeacherShellScreen({super.key});

  @override
  State<TeacherShellScreen> createState() => _TeacherShellScreenState();
}

class _TeacherShellScreenState extends State<TeacherShellScreen> {
  int _index = 0;

  late final TeacherRepo _repo;
  late final TeacherDashboardCubit _dashboardCubit;
  late final TeacherScheduleCubit _scheduleCubit;
  late final TeacherClassesCubit _classesCubit;
  late final TeacherHomeworkCubit _homeworkCubit;
  late final TeacherAttendanceCubit _attendanceCubit;
  late final TeacherNotificationsCubit _notificationsCubit;
  late final TeacherProfileCubit _profileCubit;

  @override
  void initState() {
    super.initState();
    final teacherId = context.currentUserId;

    _repo = TeacherRepo(api: DioConsumer(dio: Dio()), teacherId: teacherId);
    _dashboardCubit     = TeacherDashboardCubit(repo: _repo)..load();
    _scheduleCubit      = TeacherScheduleCubit(repo: _repo)..load();
    _classesCubit       = TeacherClassesCubit(repo: _repo)..load();
    _homeworkCubit      = TeacherHomeworkCubit(repo: _repo)..load();
    _attendanceCubit    = TeacherAttendanceCubit(repo: _repo)..load();
    _notificationsCubit = TeacherNotificationsCubit(repo: _repo)..load();
    _profileCubit       = TeacherProfileCubit(repo: _repo)..load();
  }

  @override
  void dispose() {
    _dashboardCubit.close();
    _scheduleCubit.close();
    _classesCubit.close();
    _homeworkCubit.close();
    _attendanceCubit.close();
    _notificationsCubit.close();
    _profileCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _dashboardCubit),
        BlocProvider.value(value: _scheduleCubit),
        BlocProvider.value(value: _classesCubit),
        BlocProvider.value(value: _homeworkCubit),
        BlocProvider.value(value: _attendanceCubit),
        BlocProvider.value(value: _notificationsCubit),
        BlocProvider.value(value: _profileCubit),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [
            TeacherHomeScreen(),
            TeacherClassesScreen(),
            TeacherHomeworkScreen(),
            TeacherAttendanceScreen(),
            TeacherProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined),        selectedIcon: Icon(Icons.home_rounded),        label: 'Home'),
            NavigationDestination(icon: Icon(Icons.groups_outlined),      selectedIcon: Icon(Icons.groups_rounded),      label: 'Classes'),
            NavigationDestination(icon: Icon(Icons.assignment_outlined),  selectedIcon: Icon(Icons.assignment_rounded),  label: 'Homework'),
            NavigationDestination(icon: Icon(Icons.fact_check_outlined),  selectedIcon: Icon(Icons.fact_check_rounded),  label: 'Attendance'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded),    label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
