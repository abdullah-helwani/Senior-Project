import 'dart:async';
import 'package:flutter/foundation.dart';

/// Bridges a [Stream] to a [ChangeNotifier] so [GoRouter.refreshListenable]
/// can react to BLoC/Cubit state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
