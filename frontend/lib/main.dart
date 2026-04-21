import 'package:dio/dio.dart';
import 'package:first_try/core/api/dio_consumer.dart';
import 'package:first_try/core/router/route.dart';
import 'package:first_try/core/services/storage_services.dart';
import 'package:first_try/features/auth/data/repos/auth_repo.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  final authCubit = AuthCubit(
    repo: AuthRepo(api: DioConsumer(dio: Dio())),
  );

  runApp(
    BlocProvider.value(
      value: authCubit..hydrate(),
      child: _App(authCubit: authCubit),
    ),
  );
}

class _App extends StatefulWidget {
  final AuthCubit authCubit;
  const _App({required this.authCubit});

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  late final _router = AppRouter.createRouter(widget.authCubit);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      title: 'School App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF533483),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
    );
  }
}
