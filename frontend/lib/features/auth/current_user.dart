import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_state.dart';
import 'package:first_try/features/auth/data/models/auth_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Convenience accessors for the currently authenticated user.
///
/// Every screen needs the user's id + role to build its repo. This avoids
/// repeating the `authState is AuthAuthenticated ? authState.user.id : 0`
/// pattern, which silently masks "not logged in" bugs with id = 0.
///
/// Call these from inside a shell screen — by the time a shell mounts,
/// the router has already gated on AuthAuthenticated, so the user is
/// guaranteed present.
extension CurrentUserContext on BuildContext {
  /// The currently authenticated user. Throws if unauthenticated —
  /// if you might be on a pre-auth screen (splash/login), read the cubit directly.
  UserModel get currentUser {
    final state = read<AuthCubit>().state;
    if (state is AuthAuthenticated) return state.user;
    throw StateError(
      'currentUser accessed while unauthenticated. '
      'Only call this from a screen inside a role shell.',
    );
  }

  int get currentUserId   => currentUser.id;
  String get currentRole  => currentUser.roleType;

  /// Role-specific PK (`teachers.id` / `students.id` / `guardians.id` /
  /// `driver.driver_id`). Use this for `/teacher/{id}/...` style routes
  /// where `users.id` ≠ role table id. Falls back to `users.id` only when
  /// the backend hasn't populated it (mock/old sessions); call sites that
  /// can show a misleading "wrong user" view should still null-check.
  int get currentRoleId {
    final user = currentUser;
    if (user.roleId == null) {
      // Loud breadcrumb so we can spot stale/cached sessions in the console.
      // (DevTools → Console will show this if the role_id never made it.)
      // ignore: avoid_print
      print(
        '[currentRoleId] user.roleId is NULL — falling back to users.id=${user.id}. '
        'Backend probably did not return role_id, or the cached UserModel is stale '
        '(log out + back in to refresh).',
      );
    }
    return user.roleId ?? user.id;
  }
  String get currentToken {
    final state = read<AuthCubit>().state;
    if (state is AuthAuthenticated) return state.token;
    throw StateError('currentToken accessed while unauthenticated.');
  }
}
