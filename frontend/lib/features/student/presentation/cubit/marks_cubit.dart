import 'package:first_try/features/student/data/mocks/student_mock_data.dart';
import 'package:first_try/features/student/data/repos/student_repo.dart';
import 'package:first_try/features/student/presentation/cubit/marks_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MarksCubit extends Cubit<MarksState> {
  final StudentRepo repo;

  MarksCubit({required this.repo}) : super(MarksInitial());

  Future<void> load() async {
    emit(MarksLoading());
    try {
      final marks = await repo.getMarks();
      final summary = await repo.getMarksSummary();
      emit(MarksLoaded(marks: marks, summary: summary));
    } catch (_) {
      emit(MarksLoaded(
        marks: StudentMockData.marks,
        summary: StudentMockData.marksSummary,
      ));
    }
  }

  void filterBySubject(String? subject) {
    final s = state;
    if (s is MarksLoaded) {
      emit(s.copyWith(selectedSubject: subject, clearSubject: subject == null));
    }
  }
}
