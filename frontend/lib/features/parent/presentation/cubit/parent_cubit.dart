import 'package:first_try/features/parent/data/mocks/parent_mock_data.dart';
import 'package:first_try/features/parent/data/models/parent_models.dart';
import 'package:first_try/features/parent/data/repos/parent_repo.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ParentCubit extends Cubit<ParentState> {
  final ParentRepo repo;

  ParentCubit({required this.repo}) : super(ParentInitial());

  // ── Initial load ───────────────────────────────────────────────────────────

  Future<void> load() async {
    emit(ParentLoading());
    try {
      // Backend: /notes = school notifications. Warnings = child behavior logs
      // (no separate /warnings endpoint), so warnings always come from mock.
      final profile = await repo.getProfile();
      final notes   = await repo.getNotes();
      final loaded = ParentLoaded(
        profile: profile,
        notifications: notes,
        warnings: ParentMockData.warnings,   // behavior logs — no dedicated endpoint
        selectedDay: _todayKey(),
      );
      emit(loaded);
      if (profile.children.isNotEmpty) {
        await _loadChildData(profile.children.first.id);
      }
    } catch (_) {
      final loaded = ParentLoaded(
        profile: ParentMockData.parentProfile,
        notifications: ParentMockData.notifications,
        warnings: ParentMockData.warnings,
        selectedDay: _todayKey(),
      );
      emit(loaded);
      await _loadChildData(ParentMockData.parentProfile.children.first.id);
    }
  }

  // ── Switch child ───────────────────────────────────────────────────────────

  Future<void> selectChild(int index) async {
    final s = state;
    if (s is! ParentLoaded) return;
    emit(s.copyWith(
      selectedChildIndex: index,
      clearMarksFilter: true,
      clearHomeworkFilter: true,
      selectedDay: _todayKey(),
    ));
    final childId = s.profile.children[index].id;
    await _loadChildData(childId);
  }

  // ── Load all data for a child ──────────────────────────────────────────────

  Future<void> _loadChildData(int childId) async {
    final s = state;
    if (s is! ParentLoaded) return;
    if (s.marks.containsKey(childId)) return;

    try {
      final results = await Future.wait([
        repo.getChildMarks(childId),
        repo.getChildAttendance(childId),
        repo.getChildHomework(childId),
        repo.getChildSchedule(childId),
        repo.getChildBusAssignment(childId),   // was getChildBus
      ]);

      final current = state;
      if (current is! ParentLoaded) return;

      emit(current.copyWith(
        marks:      Map.from(current.marks)      ..[childId] = results[0] as List<ParentAssessmentModel>,
        attendance: Map.from(current.attendance) ..[childId] = results[1] as ParentAttendanceSummaryModel,
        homework:   Map.from(current.homework)   ..[childId] = results[2] as List<ParentHomeworkModel>,
        schedule:   Map.from(current.schedule)   ..[childId] = results[3] as List<ParentScheduleSlotModel>,
        bus:        Map.from(current.bus)        ..[childId] = results[4] as ParentBusModel,
      ));
    } catch (_) {
      _loadMockForChild(childId);
    }
  }

  void _loadMockForChild(int childId) {
    final s = state;
    if (s is! ParentLoaded) return;
    if (s.marks.containsKey(childId)) return;

    final isChild1 =
        childId == ParentMockData.parentProfile.children.first.id;
    emit(s.copyWith(
      marks:      Map.from(s.marks)      ..[childId] = isChild1 ? ParentMockData.marksChild1      : ParentMockData.marksChild2,
      attendance: Map.from(s.attendance) ..[childId] = isChild1 ? ParentMockData.attendanceChild1 : ParentMockData.attendanceChild2,
      homework:   Map.from(s.homework)   ..[childId] = isChild1 ? ParentMockData.homeworkChild1   : ParentMockData.homeworkChild2,
      schedule:   Map.from(s.schedule)   ..[childId] = isChild1 ? ParentMockData.scheduleChild1   : ParentMockData.scheduleChild2,
      bus:        Map.from(s.bus)        ..[childId] = isChild1 ? ParentMockData.busChild1        : ParentMockData.busChild2,
    ));
  }

  // ── UI interactions ────────────────────────────────────────────────────────

  void selectDay(String day) {
    final s = state;
    if (s is ParentLoaded) emit(s.copyWith(selectedDay: day));
  }

  void filterMarksBySubject(String? subject) {
    final s = state;
    if (s is ParentLoaded) {
      emit(s.copyWith(
          marksSubjectFilter: subject, clearMarksFilter: subject == null));
    }
  }

  void filterHomeworkByStatus(String? status) {
    final s = state;
    if (s is ParentLoaded) {
      emit(s.copyWith(
          homeworkStatusFilter: status,
          clearHomeworkFilter: status == null));
    }
  }

  Future<void> markRead(int id, {bool isWarning = false}) async {
    final s = state;
    if (s is! ParentLoaded) return;

    if (isWarning) {
      // Warnings = behavior logs; no mark-read endpoint on backend.
      final updated = s.warnings
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
      emit(s.copyWith(warnings: updated));
    } else {
      final updated = s.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
      emit(s.copyWith(notifications: updated));
      // PUT /parent/{id}/notes/{recipientId}/read
      try { await repo.markNoteRead(id); } catch (_) {}
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _todayKey() {
    const keys = [
      'monday', 'tuesday', 'wednesday', 'thursday',
      'friday', 'saturday', 'sunday'
    ];
    return keys[(DateTime.now().weekday - 1).clamp(0, 6)];
  }
}
