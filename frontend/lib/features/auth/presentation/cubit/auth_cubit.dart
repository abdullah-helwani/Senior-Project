import 'dart:convert';

import 'package:first_try/core/services/storage_services.dart';
import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/features/auth/data/models/auth_model.dart';
import 'package:first_try/features/auth/data/repos/auth_repo.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

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

      // If login response lacked role_id (e.g. older backend cached in PHP
      // memory), fetch /me to fill it in. /me returns the canonical shape
      // and the interceptor will already have the new token attached.
      if (response.user.roleId == null) {
        try {
          final fresh = await _repo.me();
          if (fresh.roleId != null) {
            await StorageService.saveString(
              CacheKey.user,
              jsonEncode(fresh.toJson()),
            );
            emit(AuthAuthenticated(token: response.token, user: fresh));
          }
        } catch (_) {
          // /me failure isn't fatal — UI will use the (possibly null) roleId
          // and currentRoleId will print a breadcrumb.
        }
      }
    } catch (e) {
      emit(AuthError(message: 'Login failed: $e'));
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

  /// Wraps the repo call so screens don't have to reach into the private
  /// `_repo` field (which is brittle and hostile to refactoring).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  /// Uploads a new avatar and updates the cached user with the returned path.
  /// Returns true on success, false otherwise.
  Future<bool> updateProfilePicture(XFile file) async {
    final s = state;
    if (s is! AuthAuthenticated) return false;
    try {
      final newPath = await _repo.updateProfilePicture(file);
      final updated = s.user.copyWith(profilePicture: newPath);
      await StorageService.saveString(
        CacheKey.user,
        jsonEncode(updated.toJson()),
      );
      emit(AuthAuthenticated(token: s.token, user: updated));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProfilePicture() async {
    final s = state;
    if (s is! AuthAuthenticated) return false;
    try {
      await _repo.deleteProfilePicture();
      final updated = s.user.copyWith(clearProfilePicture: true);
      await StorageService.saveString(
        CacheKey.user,
        jsonEncode(updated.toJson()),
      );
      emit(AuthAuthenticated(token: s.token, user: updated));
      return true;
    } catch (_) {
      return false;
    }
  }
}
