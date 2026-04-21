import 'dart:async';
import 'package:first_try/features/student/data/mocks/student_mock_data.dart';
import 'package:first_try/features/student/data/repos/student_repo.dart';
import 'package:first_try/features/student/presentation/cubit/bus_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BusCubit extends Cubit<BusState> {
  final StudentRepo repo;
  Timer? _liveTimer;

  BusCubit({required this.repo}) : super(BusInitial());

  Future<void> load() async {
    emit(BusLoading());
    try {
      final assignment = await repo.getBusAssignment();
      final events = await repo.getBusEvents();
      emit(BusLoaded(assignment: assignment, events: events));
      _startLivePolling();
    } catch (_) {
      emit(BusLoaded(
        assignment: StudentMockData.busAssignment,
        liveLocation: StudentMockData.busLiveLocation,
        events: StudentMockData.busEvents,
      ));
    }
  }

  void _startLivePolling() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final live = await repo.getBusLiveLocation();
        final s = state;
        if (s is BusLoaded) {
          emit(s.copyWith(liveLocation: live));
        }
      } catch (_) {
        // Silent — keep showing last known location
      }
    });
  }

  Future<void> refreshLive() async {
    final s = state;
    if (s is! BusLoaded) return;
    try {
      final live = await repo.getBusLiveLocation();
      emit(s.copyWith(liveLocation: live));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _liveTimer?.cancel();
    return super.close();
  }
}
