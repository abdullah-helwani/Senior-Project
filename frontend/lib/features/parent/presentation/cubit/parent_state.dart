import 'package:equatable/equatable.dart';
import 'package:first_try/features/parent/data/models/parent_extra_models.dart';
import 'package:first_try/features/parent/data/models/parent_models.dart';

// ── Selected child + all loaded data in one state ─────────────────────────────

abstract class ParentState extends Equatable {
  const ParentState();
  @override List<Object?> get props => [];
}

class ParentInitial extends ParentState {}
class ParentLoading extends ParentState {}

class ParentLoaded extends ParentState {
  final ParentProfileModel profile;
  final int selectedChildIndex;

  // Per-child data keyed by childId
  final Map<int, List<ParentAssessmentModel>> marks;
  final Map<int, ParentAttendanceSummaryModel> attendance;
  final Map<int, List<ParentHomeworkModel>> homework;
  final Map<int, List<ParentScheduleSlotModel>> schedule;
  final Map<int, ParentBusModel> bus;
  // Timeline of recent bus stop events per child (optional — populated on demand).
  final Map<int, List<BusEventModel>> busEvents;

  final List<ParentNotificationModel> notifications;
  final List<ParentNotificationModel> warnings;

  final String selectedDay;
  final String? marksSubjectFilter;
  final String? homeworkStatusFilter;

  const ParentLoaded({
    required this.profile,
    this.selectedChildIndex = 0,
    this.marks = const {},
    this.attendance = const {},
    this.homework = const {},
    this.schedule = const {},
    this.bus = const {},
    this.busEvents = const {},
    this.notifications = const [],
    this.warnings = const [],
    this.selectedDay = 'monday',
    this.marksSubjectFilter,
    this.homeworkStatusFilter,
  });

  ChildSummaryModel get selectedChild => profile.children[selectedChildIndex];
  int get selectedChildId => selectedChild.id;

  ParentLoaded copyWith({
    ParentProfileModel? profile,
    int? selectedChildIndex,
    Map<int, List<ParentAssessmentModel>>? marks,
    Map<int, ParentAttendanceSummaryModel>? attendance,
    Map<int, List<ParentHomeworkModel>>? homework,
    Map<int, List<ParentScheduleSlotModel>>? schedule,
    Map<int, ParentBusModel>? bus,
    Map<int, List<BusEventModel>>? busEvents,
    List<ParentNotificationModel>? notifications,
    List<ParentNotificationModel>? warnings,
    String? selectedDay,
    String? marksSubjectFilter,
    bool clearMarksFilter = false,
    String? homeworkStatusFilter,
    bool clearHomeworkFilter = false,
  }) =>
      ParentLoaded(
        profile: profile ?? this.profile,
        selectedChildIndex: selectedChildIndex ?? this.selectedChildIndex,
        marks: marks ?? this.marks,
        attendance: attendance ?? this.attendance,
        homework: homework ?? this.homework,
        schedule: schedule ?? this.schedule,
        bus: bus ?? this.bus,
        busEvents: busEvents ?? this.busEvents,
        notifications: notifications ?? this.notifications,
        warnings: warnings ?? this.warnings,
        selectedDay: selectedDay ?? this.selectedDay,
        marksSubjectFilter: clearMarksFilter ? null : (marksSubjectFilter ?? this.marksSubjectFilter),
        homeworkStatusFilter: clearHomeworkFilter ? null : (homeworkStatusFilter ?? this.homeworkStatusFilter),
      );

  List<ParentScheduleSlotModel> get slotsForDay {
    final slots = schedule[selectedChildId] ?? [];
    return slots.where((s) => s.day == selectedDay).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<ParentAssessmentModel> get filteredMarks {
    final all = marks[selectedChildId] ?? [];
    if (marksSubjectFilter == null) return all;
    return all.where((m) => m.subject == marksSubjectFilter).toList();
  }

  List<ParentHomeworkModel> get filteredHomework {
    final all = homework[selectedChildId] ?? [];
    if (homeworkStatusFilter == null) return all;
    return all.where((h) => h.status == homeworkStatusFilter).toList();
  }

  int get unreadCount =>
      notifications.where((n) => !n.isRead).length +
      warnings.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [
        profile, selectedChildIndex, marks, attendance,
        homework, schedule, bus, busEvents, notifications, warnings,
        selectedDay, marksSubjectFilter, homeworkStatusFilter,
      ];
}

class ParentError extends ParentState {
  final String message;
  const ParentError(this.message);
  @override List<Object?> get props => [message];
}
