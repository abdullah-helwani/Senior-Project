import 'package:first_try/features/driver/data/mocks/driver_mock_data.dart';
import 'package:first_try/features/driver/data/repos/driver_repo.dart';
import 'package:first_try/features/driver/presentation/cubit/trip_history_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripHistoryCubit extends Cubit<TripHistoryState> {
  final DriverRepo _repo;
  final int _driverId;

  TripHistoryCubit({required DriverRepo repo, required int driverId})
      : _repo = repo,
        _driverId = driverId,
        super(const TripHistoryInitial());

  Future<void> loadHistory({
    DateTime? from,
    DateTime? to,
    String? period,
  }) async {
    emit(const TripHistoryLoading());
    try {
      final trips = await _repo.getTripHistory(
        _driverId,
        from: from,
        to: to,
        period: period,
      );
      emit(TripHistoryLoaded(trips: trips));
    } catch (_) {
      emit(TripHistoryLoaded(trips: DriverMockData.tripHistory));
    }
  }
}
