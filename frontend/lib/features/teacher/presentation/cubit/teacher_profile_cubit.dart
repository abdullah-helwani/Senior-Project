import 'package:first_try/features/teacher/data/mocks/teacher_mock_data.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherProfileCubit extends Cubit<TeacherProfileState> {
  final TeacherRepo repo;
  TeacherProfileCubit({required this.repo}) : super(TeacherProfileInitial());

  Future<void> load() async {
    emit(TeacherProfileLoading());
    try {
      emit(TeacherProfileLoaded(await repo.getProfile()));
    } catch (_) {
      emit(TeacherProfileLoaded(TeacherMockData.profile));
    }
  }
}
