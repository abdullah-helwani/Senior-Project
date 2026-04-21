import 'package:first_try/features/student/data/mocks/student_mock_data.dart';
import 'package:first_try/features/student/data/repos/student_repo.dart';
import 'package:first_try/features/student/presentation/cubit/student_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentProfileCubit extends Cubit<StudentProfileState> {
  final StudentRepo repo;

  StudentProfileCubit({required this.repo}) : super(StudentProfileInitial());

  Future<void> load() async {
    emit(StudentProfileLoading());
    try {
      final data = await repo.getProfile();
      emit(StudentProfileLoaded(data));
    } catch (_) {
      emit(StudentProfileLoaded(StudentMockData.profile));
    }
  }
}
