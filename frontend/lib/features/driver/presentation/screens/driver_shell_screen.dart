import 'package:dio/dio.dart';
import 'package:first_try/core/api/dio_consumer.dart';
import 'package:first_try/core/widgets/shared/animated_shell.dart';
import 'package:first_try/features/auth/current_user.dart';
import 'package:first_try/features/driver/data/repos/driver_repo.dart';
import 'package:first_try/features/driver/presentation/cubit/driver_profile_cubit.dart';
import 'package:first_try/features/driver/presentation/cubit/today_trips_cubit.dart';
import 'package:first_try/features/driver/presentation/cubit/trip_history_cubit.dart';
import 'package:first_try/features/driver/presentation/screens/driver_profile_screen.dart';
import 'package:first_try/features/driver/presentation/screens/today_trips_screen.dart';
import 'package:first_try/features/driver/presentation/screens/trip_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DriverShellScreen extends StatefulWidget {
  const DriverShellScreen({super.key});

  @override
  State<DriverShellScreen> createState() => _DriverShellScreenState();
}

class _DriverShellScreenState extends State<DriverShellScreen> {
  int _currentIndex = 0;

  late final DriverRepo _repo;
  late final TodayTripsCubit _todayCubit;
  late final TripHistoryCubit _historyCubit;
  late final DriverProfileCubit _profileCubit;

  @override
  void initState() {
    super.initState();
    final driverId = context.currentRoleId;

    _repo = DriverRepo(api: DioConsumer(dio: Dio()));
    _todayCubit   = TodayTripsCubit(repo: _repo, driverId: driverId)..loadTodayTrips();
    _historyCubit = TripHistoryCubit(repo: _repo, driverId: driverId)..loadHistory();
    _profileCubit = DriverProfileCubit(repo: _repo, driverId: driverId)..loadProfile();
  }

  @override
  void dispose() {
    _todayCubit.close();
    _historyCubit.close();
    _profileCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _todayCubit),
        BlocProvider.value(value: _historyCubit),
        BlocProvider.value(value: _profileCubit),
      ],
      child: Scaffold(
        body: AnimatedShell(
          index: _currentIndex,
          children: const [
            TodayTripsScreen(),
            TripHistoryScreen(),
            DriverProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today_rounded),
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'Trips',
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
