import 'package:dio/dio.dart';
import 'package:first_try/core/api/dio_consumer.dart';
import 'package:first_try/core/widgets/shared/animated_shell.dart';
import 'package:first_try/features/auth/current_user.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_attendance_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_availability_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_behavior_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_classes_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_dashboard_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_homework_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_messages_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_notifications_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_performance_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_profile_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_salary_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_schedule_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_vacation_cubit.dart';
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
  late final TeacherMessagesCubit _messagesCubit;
  late final TeacherBehaviorCubit _behaviorCubit;
  late final TeacherPerformanceCubit _performanceCubit;
  late final TeacherSalaryCubit _salaryCubit;
  late final TeacherVacationCubit _vacationCubit;
  late final TeacherAvailabilityCubit _availabilityCubit;

  @override
  void initState() {
    super.initState();
    final teacherId = context.currentRoleId;

    _repo = TeacherRepo(api: DioConsumer(dio: Dio()), teacherId: teacherId);
    _dashboardCubit     = TeacherDashboardCubit(repo: _repo)..load();
    _scheduleCubit      = TeacherScheduleCubit(repo: _repo)..load();
    _classesCubit       = TeacherClassesCubit(repo: _repo)..load();
    _homeworkCubit      = TeacherHomeworkCubit(repo: _repo)..load();
    _attendanceCubit    = TeacherAttendanceCubit(repo: _repo)..load();
    _notificationsCubit = TeacherNotificationsCubit(repo: _repo)..load();
    _profileCubit       = TeacherProfileCubit(repo: _repo)..load();
    _messagesCubit      = TeacherMessagesCubit(repo: _repo);
    _behaviorCubit      = TeacherBehaviorCubit(repo: _repo);
    _performanceCubit   = TeacherPerformanceCubit(repo: _repo);
    _salaryCubit        = TeacherSalaryCubit(repo: _repo);
    _vacationCubit      = TeacherVacationCubit(repo: _repo);
    _availabilityCubit  = TeacherAvailabilityCubit(repo: _repo);
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
    _messagesCubit.close();
    _behaviorCubit.close();
    _performanceCubit.close();
    _salaryCubit.close();
    _vacationCubit.close();
    _availabilityCubit.close();
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
        BlocProvider.value(value: _messagesCubit),
        BlocProvider.value(value: _behaviorCubit),
        BlocProvider.value(value: _performanceCubit),
        BlocProvider.value(value: _salaryCubit),
        BlocProvider.value(value: _vacationCubit),
        BlocProvider.value(value: _availabilityCubit),
      ],
      child: Scaffold(
        body: AnimatedShell(
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
