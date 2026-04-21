import 'package:first_try/features/driver/data/mocks/driver_mock_data.dart';
import 'package:first_try/features/driver/data/repos/driver_repo.dart';
import 'package:first_try/features/driver/presentation/cubit/driver_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DriverProfileCubit extends Cubit<DriverProfileState> {
  final DriverRepo _repo;
  final int _driverId;

  DriverProfileCubit({required DriverRepo repo, required int driverId})
      : _repo = repo,
        _driverId = driverId,
        super(const DriverProfileInitial());

  Future<void> loadProfile() async {
    emit(const DriverProfileLoading());
    try {
      final profile = await _repo.getProfile(_driverId);
      emit(DriverProfileLoaded(profile: profile));
    } catch (_) {
      emit(DriverProfileLoaded(profile: DriverMockData.profile));
    }
  }
}
