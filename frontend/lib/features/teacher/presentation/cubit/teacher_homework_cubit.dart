import 'package:first_try/features/teacher/data/mocks/teacher_mock_data.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_homework_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherHomeworkCubit extends Cubit<TeacherHomeworkState> {
  final TeacherRepo repo;
  TeacherHomeworkCubit({required this.repo}) : super(TeacherHomeworkInitial());

  Future<void> load() async {
    emit(TeacherHomeworkLoading());
    try {
      emit(TeacherHomeworkLoaded(homework: await repo.getHomework()));
    } catch (_) {
      emit(TeacherHomeworkLoaded(homework: TeacherMockData.homework));
    }
  }

  Future<void> loadSubmissions(int hwId) async {
    final s = state;
    if (s is! TeacherHomeworkLoaded) return;
    if (s.submissions.containsKey(hwId)) return; // already loaded

    emit(s.copyWith(loadingSubmissions: {...s.loadingSubmissions, hwId}));
    try {
      final subs = await repo.getSubmissions(hwId);
      final updated = Map<int, List<HomeworkSubmissionModel>>.from(s.submissions)
        ..[hwId] = subs;
      emit(s.copyWith(
        submissions: updated,
        loadingSubmissions: s.loadingSubmissions.difference({hwId}),
      ));
    } catch (_) {
      // Fall back to mock submissions for hw id=1
      final subs = hwId == 1 ? TeacherMockData.submissionsHw1 : <HomeworkSubmissionModel>[];
      final updated = Map<int, List<HomeworkSubmissionModel>>.from(s.submissions)
        ..[hwId] = subs;
      emit(s.copyWith(
        submissions: updated,
        loadingSubmissions: s.loadingSubmissions.difference({hwId}),
      ));
    }
  }

  Future<void> gradeSubmission({
    required int hwId,
    required int submissionId,
    required double grade,
    String? feedback,
  }) async {
    final s = state;
    if (s is! TeacherHomeworkLoaded) return;

    // Optimistic update
    final subs = List<HomeworkSubmissionModel>.from(s.submissions[hwId] ?? []);
    final idx = subs.indexWhere((sub) => sub.id == submissionId);
    if (idx != -1) {
      subs[idx] = subs[idx].copyWith(
          grade: grade, feedback: feedback, status: 'graded');
    }
    final updated = Map<int, List<HomeworkSubmissionModel>>.from(s.submissions)
      ..[hwId] = subs;
    emit(s.copyWith(submissions: updated));

    try {
      await repo.gradeSubmission(
          hwId: hwId,
          submissionId: submissionId,
          grade: grade,
          feedback: feedback);
    } catch (_) {
      // Optimistic update stays
    }
  }
}
