import 'dart:convert';

import 'package:first_try/core/services/storage_services.dart';
import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/features/auth/data/models/auth_model.dart';
import 'package:first_try/features/auth/data/repos/auth_repo.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo _repo;

  AuthCubit({required AuthRepo repo})
      : _repo = repo,
        super(const AuthInitial());

  /// Called once at app startup to restore a previous session.
  Future<void> hydrate() async {
    emit(const AuthLoading());
    final token    = await StorageService.getString(CacheKey.token);
    final userJson = await StorageService.getString(CacheKey.user);

    if (token != null && userJson != null) {
      try {
        final user = UserModel.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
        emit(AuthAuthenticated(token: token, user: user));
      } catch (_) {
        await StorageService.clearAll();
        emit(const AuthUnauthenticated());
      }
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final response = await _repo.login(email: email, password: password);
      await StorageService.saveString(CacheKey.token, response.token);
      await StorageService.saveString(
        CacheKey.user,
        jsonEncode(response.user.toJson()),
      );
      emit(AuthAuthenticated(token: response.token, user: response.user));
    } catch (_) {
      // ── Mock login (remove when backend is ready) ──────────────────────────
      final mockRole = _mockRoleFromEmail(email);
      if (mockRole != null) {
        const mockToken = 'mock-token';
        final mockUser = UserModel(
          id: 1,
          name: _mockNameFromEmail(email),
          email: email,
          roleType: mockRole,
        );
        await StorageService.saveString(CacheKey.token, mockToken);
        await StorageService.saveString(CacheKey.user, jsonEncode(mockUser.toJson()));
        emit(AuthAuthenticated(token: mockToken, user: mockUser));
        return;
      }
      // ── End mock ───────────────────────────────────────────────────────────
      emit(const AuthError(message: 'Login failed — backend not reachable'));
    }
  }

  String? _mockRoleFromEmail(String email) {
    final e = email.toLowerCase().trim();
    // Real seeded emails
    if (e == 'ali@school.test' || e == 'fatima@school.test') return 'student';
    if (e == 'sara@school.test' || e == 'omar@school.test')  return 'teacher';
    if (e == 'parent@school.test')                           return 'parent';
    // Generic demo emails (quick-access buttons)
    if (e.contains('student')) return 'student';
    if (e.contains('driver'))  return 'driver';
    if (e.contains('teacher')) return 'teacher';
    if (e.contains('parent'))  return 'parent';
    return null;
  }

  String _mockNameFromEmail(String email) {
    final e = email.toLowerCase().trim();
    if (e == 'ali@school.test')    return 'Ali Mohammed';
    if (e == 'fatima@school.test') return 'Fatima Khalid';
    if (e == 'sara@school.test')   return 'Sara Ahmed';
    if (e == 'omar@school.test')   return 'Omar Hassan';
    if (e == 'parent@school.test') return 'Mohammed Ali';
    final role = _mockRoleFromEmail(email) ?? 'user';
    switch (role) {
      case 'student': return 'Student User';
      case 'driver':  return 'Driver User';
      case 'teacher': return 'Teacher User';
      case 'parent':  return 'Parent User';
      default:        return 'User';
    }
  }

  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await _repo.logout();
    } catch (_) {
      // Clear local session regardless of API result
    }
    await StorageService.clearAll();
    emit(const AuthUnauthenticated());
  }
}
