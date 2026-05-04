import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_classes_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherClassesCubit extends Cubit<TeacherClassesState> {
  final TeacherRepo repo;
  TeacherClassesCubit({required this.repo}) : super(TeacherClassesInitial());

  Future<void> load() async {
    emit(TeacherClassesLoading());
    try {
      emit(TeacherClassesLoaded(await repo.getClasses()));
    } catch (e) {
      emit(TeacherClassesError(e.toString()));
    }
  }
}
