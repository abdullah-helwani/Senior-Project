import 'package:first_try/features/driver/data/mocks/driver_mock_data.dart';
import 'package:first_try/features/driver/data/repos/driver_repo.dart';
import 'package:first_try/features/driver/presentation/cubit/today_trips_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TodayTripsCubit extends Cubit<TodayTripsState> {
  final DriverRepo _repo;
  final int _driverId;

  TodayTripsCubit({required DriverRepo repo, required int driverId})
      : _repo = repo,
        _driverId = driverId,
        super(const TodayTripsInitial());

  Future<void> loadTodayTrips() async {
    emit(const TodayTripsLoading());
    try {
      final trips = await _repo.getTodayTrips(_driverId);
      emit(TodayTripsLoaded(trips: trips));
    } catch (_) {
      // Backend not ready — use mock data for interface preview
      emit(TodayTripsLoaded(trips: DriverMockData.todayTrips));
    }
  }
}
