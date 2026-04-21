import 'dart:async';

import 'package:first_try/features/driver/data/mocks/driver_mock_data.dart';
import 'package:first_try/features/driver/data/repos/driver_repo.dart';
import 'package:first_try/features/driver/presentation/cubit/trip_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

class TripDetailCubit extends Cubit<TripDetailState> {
  final DriverRepo _repo;
  final int _driverId;
  final int _tripId;
  Timer? _pingTimer;

  TripDetailCubit({
    required DriverRepo repo,
    required int driverId,
    required int tripId,
  })  : _repo = repo,
        _driverId = driverId,
        _tripId = tripId,
        super(const TripDetailInitial());

  Future<void> loadTrip() async {
    emit(const TripDetailLoading());
    try {
      final trip = await _repo.getTripDetail(_driverId, _tripId);
      emit(TripDetailLoaded(trip: trip));
    } catch (_) {
      emit(TripDetailLoaded(trip: DriverMockData.tripDetail));
    }
  }

  // ── GPS pinging ────────────────────────────────────────────────────────────

  Future<void> startGpsPings() async {
    if (state is! TripDetailLoaded) return;

    final permission = await _requestLocationPermission();
    if (!permission) return;

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _sendPing());

    emit((state as TripDetailLoaded).copyWith(isGpsActive: true));
    await _sendPing(); // immediate first ping
  }

  void stopGpsPings() {
    _pingTimer?.cancel();
    _pingTimer = null;
    if (state is TripDetailLoaded) {
      emit((state as TripDetailLoaded).copyWith(isGpsActive: false));
    }
  }

  Future<bool> _requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> _sendPing() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      await _repo.pingLocation(
        driverId: _driverId,
        tripId: _tripId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (state is TripDetailLoaded) {
        emit((state as TripDetailLoaded).copyWith(lastPingAt: DateTime.now()));
      }
    } catch (_) {
      // Ping failures are silent — never block the driver's workflow
    }
  }

  // ── Stop events ────────────────────────────────────────────────────────────

  Future<void> markBoarded({
    required int studentId,
    required int stopId,
  }) async {
    if (state is! TripDetailLoaded) return;
    final prev = state as TripDetailLoaded;

    // Optimistic update
    final updated = prev.trip.students.map((s) {
      if (s.id == studentId) {
        return s.copyWith(status: 'boarded', boardedAt: DateTime.now());
      }
      return s;
    }).toList();
    emit(prev.copyWith(trip: prev.trip.copyWith(students: updated)));

    try {
      await _repo.postStopEvent(
        driverId: _driverId,
        tripId: _tripId,
        stopId: stopId,
        studentId: studentId,
        eventType: 'boarded',
      );
    } catch (_) {
      emit(prev); // rollback on error
    }
  }

  Future<void> markDropped({
    required int studentId,
    required int stopId,
  }) async {
    if (state is! TripDetailLoaded) return;
    final prev = state as TripDetailLoaded;

    final updated = prev.trip.students.map((s) {
      if (s.id == studentId) {
        return s.copyWith(status: 'dropped', droppedAt: DateTime.now());
      }
      return s;
    }).toList();
    emit(prev.copyWith(trip: prev.trip.copyWith(students: updated)));

    try {
      await _repo.postStopEvent(
        driverId: _driverId,
        tripId: _tripId,
        stopId: stopId,
        studentId: studentId,
        eventType: 'dropped',
      );
    } catch (_) {
      emit(prev);
    }
  }

  @override
  Future<void> close() {
    _pingTimer?.cancel();
    return super.close();
  }
}
