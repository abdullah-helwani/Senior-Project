import 'package:first_try/features/student/data/mocks/student_mock_data.dart';
import 'package:first_try/features/student/data/models/student_models.dart';
import 'package:first_try/features/student/data/repos/student_repo.dart';
import 'package:first_try/features/student/presentation/cubit/homework_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeworkCubit extends Cubit<HomeworkState> {
  final StudentRepo repo;

  HomeworkCubit({required this.repo}) : super(HomeworkInitial());

  Future<void> load() async {
    emit(HomeworkLoading());
    try {
      final hw = await repo.getHomework();
      emit(HomeworkLoaded(homework: hw));
    } catch (_) {
      emit(HomeworkLoaded(homework: StudentMockData.homework));
    }
  }

  void filterByStatus(String? status) {
    final s = state;
    if (s is HomeworkLoaded) {
      emit(s.copyWith(statusFilter: status, clearFilter: status == null));
    }
  }

  /// Submits homework with an optional file attachment.
  /// Returns true on success, false on failure (UI surfaces a snackbar).
  Future<bool> submit({
    required int hwId,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final s = state;
    if (s is! HomeworkLoaded) {
      // ignore: avoid_print
      print('[HomeworkCubit.submit] aborted — state is ${state.runtimeType}');
      return false;
    }
    try {
      await repo.submitHomework(
        hwId: hwId,
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      // Refresh list after submission
      final updated = await repo.getHomework();
      emit(HomeworkLoaded(homework: updated, statusFilter: s.statusFilter));
      return true;
    } catch (e, st) {
      // ignore: avoid_print
      print('[HomeworkCubit.submit] failed: $e');
      // ignore: avoid_print
      print(st);
      return false;
    }
  }
}
