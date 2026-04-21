import 'package:dio/dio.dart';
import 'package:first_try/core/api/dio_consumer.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_state.dart';
import 'package:first_try/features/parent/data/repos/parent_repo.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_state.dart';
import 'package:first_try/features/parent/presentation/screens/parent_academics_screen.dart';
import 'package:first_try/features/parent/presentation/screens/parent_home_screen.dart';
import 'package:first_try/features/parent/presentation/screens/parent_notifications_screen.dart';
import 'package:first_try/features/parent/presentation/screens/parent_bus_screen.dart';
import 'package:first_try/features/parent/presentation/screens/parent_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ParentShellScreen extends StatefulWidget {
  const ParentShellScreen({super.key});

  @override
  State<ParentShellScreen> createState() => _ParentShellScreenState();
}

class _ParentShellScreenState extends State<ParentShellScreen> {
  int _index = 0;
  late final ParentCubit _cubit;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>().state;
    final parentId = auth is AuthAuthenticated ? auth.user.id : 0;
    _cubit = ParentCubit(
      repo: ParentRepo(api: DioConsumer(dio: Dio()), parentId: parentId),
    )..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<ParentCubit, ParentState>(
        builder: (context, state) {
          final unread = state is ParentLoaded ? state.unreadCount : 0;
          return Scaffold(
            body: IndexedStack(
              index: _index,
              children: const [
                ParentHomeScreen(),
                ParentAcademicsScreen(),
                ParentNotificationsScreen(),
                ParentBusScreen(),
                ParentProfileScreen(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                const NavigationDestination(icon: Icon(Icons.home_outlined),          selectedIcon: Icon(Icons.home_rounded),          label: 'Home'),
                const NavigationDestination(icon: Icon(Icons.school_outlined),        selectedIcon: Icon(Icons.school_rounded),        label: 'Academics'),
                NavigationDestination(
                  icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_outlined)),
                  selectedIcon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_rounded)),
                  label: 'Alerts',
                ),
                const NavigationDestination(icon: Icon(Icons.directions_bus_outlined), selectedIcon: Icon(Icons.directions_bus_rounded), label: 'Bus'),
                const NavigationDestination(icon: Icon(Icons.person_outline_rounded),  selectedIcon: Icon(Icons.person_rounded),        label: 'Profile'),
              ],
            ),
          );
        },
      ),
    );
  }
}
