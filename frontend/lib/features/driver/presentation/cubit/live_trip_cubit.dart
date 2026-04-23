import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:first_try/features/driver/data/repos/driver_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

/// Drives GPS pings while a trip is active.
/// - Primary: geolocator position stream (best for battery / movement).
/// - Fallback: periodic Timer that getCurrentPosition + POSTs every [interval].
///
/// Call [start] once the driver taps "Start trip" and [stop] when the trip
/// ends / is paused. The cubit always cleans up in [close].
sealed class LiveTripState extends Equatable {
  const LiveTripState();
  @override
  List<Object?> get props => [];
}

class LiveTripIdle extends LiveTripState {
  const LiveTripIdle();
}

class LiveTripStarting extends LiveTripState {
  const LiveTripStarting();
}

class LiveTripActive extends LiveTripState {
  final int driverId;
  final int tripId;
  final Position? lastPosition;
  final DateTime? lastPingAt;
  final int pingsSent;
  final String? lastError;

  const LiveTripActive({
    required this.driverId,
    required this.tripId,
    this.lastPosition,
    this.lastPingAt,
    this.pingsSent = 0,
    this.lastError,
  });

  LiveTripActive copyWith({
    Position? lastPosition,
    DateTime? lastPingAt,
    int? pingsSent,
    String? lastError,
    bool clearError = false,
  }) =>
      LiveTripActive(
        driverId: driverId,
        tripId: tripId,
        lastPosition: lastPosition ?? this.lastPosition,
        lastPingAt: lastPingAt ?? this.lastPingAt,
        pingsSent: pingsSent ?? this.pingsSent,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );

  @override
  List<Object?> get props =>
      [driverId, tripId, lastPosition, lastPingAt, pingsSent, lastError];
}

class LiveTripError extends LiveTripState {
  final String message;
  const LiveTripError(this.message);
  @override
  List<Object?> get props => [message];
}

class LiveTripCubit extends Cubit<LiveTripState> {
  final DriverRepo repo;

  /// How often to ping when using the Timer fallback.
  final Duration interval;

  /// Minimum meters of movement before the stream emits a new position.
  final int distanceFilterMeters;

  StreamSubscription<Position>? _posSub;
  Timer? _timer;
  bool _sending = false;

  LiveTripCubit({
    required this.repo,
    this.interval = const Duration(seconds: 15),
    this.distanceFilterMeters = 10,
  }) : super(const LiveTripIdle());

  Future<bool> start({required int driverId, required int tripId}) async {
    if (state is LiveTripActive) return true;
    emit(const LiveTripStarting());

    try {
      final ok = await _ensurePermission();
      if (!ok) {
        emit(const LiveTripError('Location permission denied.'));
        return false;
      }
    } catch (e) {
      emit(LiveTripError(e.toString()));
      return false;
    }

    emit(LiveTripActive(driverId: driverId, tripId: tripId));

    // Initial ping so the backend knows we're live immediately.
    unawaited(_pingNow());

    // Primary: position stream.
    _posSub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    ).listen(
      (pos) => _sendPing(pos),
      onError: (Object e) {
        final s = state;
        if (s is LiveTripActive) {
          emit(s.copyWith(lastError: e.toString()));
        }
      },
    );

    // Fallback: periodic timer (covers long stops without movement).
    _timer = Timer.periodic(interval, (_) => _pingNow());

    return true;
  }

  Future<void> stop() async {
    await _posSub?.cancel();
    _posSub = null;
    _timer?.cancel();
    _timer = null;
    emit(const LiveTripIdle());
  }

  Future<void> _pingNow() async {
    if (state is! LiveTripActive) return;
    try {
      final pos = await Geolocator.getCurrentPosition();
      await _sendPing(pos);
    } catch (e) {
      final s = state;
      if (s is LiveTripActive) emit(s.copyWith(lastError: e.toString()));
    }
  }

  Future<void> _sendPing(Position pos) async {
    final s = state;
    if (s is! LiveTripActive) return;
    if (_sending) return;
    _sending = true;
    try {
      await repo.pingLocation(
        driverId: s.driverId,
        tripId: s.tripId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        capturedAt: pos.timestamp,
      );
      final cur = state;
      if (cur is LiveTripActive) {
        emit(cur.copyWith(
          lastPosition: pos,
          lastPingAt: DateTime.now(),
          pingsSent: cur.pingsSent + 1,
          clearError: true,
        ));
      }
    } catch (e) {
      final cur = state;
      if (cur is LiveTripActive) {
        emit(cur.copyWith(lastError: e.toString()));
      }
    } finally {
      _sending = false;
    }
  }

  Future<bool> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  @override
  Future<void> close() async {
    await _posSub?.cancel();
    _timer?.cancel();
    return super.close();
  }
}
