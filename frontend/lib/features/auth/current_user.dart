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
  String get currentToken {
    final state = read<AuthCubit>().state;
    if (state is AuthAuthenticated) return state.token;
    throw StateError('currentToken accessed while unauthenticated.');
  }
}
