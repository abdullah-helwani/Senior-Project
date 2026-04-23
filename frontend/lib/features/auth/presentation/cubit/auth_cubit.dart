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
  /// Steps: read token + user from storage → optimistically emit authenticated →
  /// validate with /me in the background → update user or force-logout on failure.
  Future<void> hydrate() async {
    emit(const AuthLoading());
    final token    = await StorageService.getString(CacheKey.token);
    final userJson = await StorageService.getString(CacheKey.user);

    if (token == null || userJson == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    // Optimistic restore so the splash unblocks immediately.
    try {
      final cachedUser = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      emit(AuthAuthenticated(token: token, user: cachedUser));
    } catch (_) {
      await StorageService.clearAll();
      emit(const AuthUnauthenticated());
      return;
    }

    // Validate + refresh with /me (fire-and-forget). If the token is revoked
    // or expired, the 401 interceptor will call forceLogout() for us.
    try {
      final freshUser = await _repo.me();
      await StorageService.saveString(
        CacheKey.user,
        jsonEncode(freshUser.toJson()),
      );
      emit(AuthAuthenticated(token: token, user: freshUser));
    } catch (_) {
      // Non-401 errors (offline, 500, etc.) — keep the cached session as-is.
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
      // ── Mock login (used for UI testing when the backend is offline) ───────
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
      emit(const AuthError(message: 'Login failed — check your credentials or your connection'));
    }
  }

  String? _mockRoleFromEmail(String email) {
    final e = email.toLowerCase().trim();
    if (e == 'ali@school.test' || e == 'fatima@school.test') return 'student';
    if (e == 'sara@school.test' || e == 'omar@school.test')  return 'teacher';
    if (e == 'parent@school.test')                           return 'parent';
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
      // Ignore errors — we're clearing local session regardless.
    }
    await StorageService.clearAll();
    emit(const AuthUnauthenticated());
  }

  /// Called by the 401 interceptor when the server rejects our token.
  /// Skips the API call (token is already invalid) and just clears local state.
  Future<void> forceLogout() async {
    await StorageService.clearAll();
    emit(const AuthUnauthenticated());
  }
}
