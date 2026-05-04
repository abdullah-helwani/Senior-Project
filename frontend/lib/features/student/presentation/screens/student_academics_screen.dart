import 'package:file_picker/file_picker.dart';
import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/student/data/models/student_models.dart';
import 'package:first_try/features/student/presentation/cubit/attendance_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/attendance_state.dart';
import 'package:first_try/features/student/presentation/cubit/homework_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/homework_state.dart';
import 'package:first_try/features/student/presentation/cubit/marks_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/marks_state.dart';
import 'package:first_try/features/student/presentation/cubit/schedule_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/schedule_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class StudentAcademicsScreen extends StatefulWidget {
  const StudentAcademicsScreen({super.key});

  @override
  State<StudentAcademicsScreen> createState() =>
      _StudentAcademicsScreenState();
}

class _StudentAcademicsScreenState extends State<StudentAcademicsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academics',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Marks'),
            Tab(text: 'Schedule'),
            Tab(text: 'Homework'),
            Tab(text: 'Attendance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _MarksTab(),
          _ScheduleTab(),
          _HomeworkTab(),
          _AttendanceTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Marks Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _MarksTab extends StatelessWidget {
  const _MarksTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarksCubit, MarksState>(
      builder: (context, state) {
        if (state is MarksLoading || state is MarksInitial) {
          return const CardListSkeleton();
        }
        if (state is MarksError) {
          return ErrorView(
              message: state.message,
              onRetry: () => context.read<MarksCubit>().load());
        }
        if (state is! MarksLoaded) return const SizedBox.shrink();

        final subjects = state.marks.map((m) => m.subject).toSet().toList()
          ..sort();
        final displayMarks = state.selectedSubject == null
            ? state.marks
            : state.marks
                .where((m) => m.subject == state.selectedSubject)
                .toList();

        return RefreshIndicator(
          onRefresh: () => context.read<MarksCubit>().load(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _MarksSummaryCard(summary: state.summary),
              ),
              SliverToBoxAdapter(
                child: _SubjectFilter(
                  subjects: subjects,
                  selected: state.selectedSubject,
                  onSelect: (s) =>
                      context.read<MarksCubit>().filterBySubject(s),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) =>
                      _AssessmentCard(assessment: displayMarks[i]),
                  childCount: displayMarks.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }
}

class _MarksSummaryCard extends StatelessWidget {
  final MarksSummaryModel summary;
  const _MarksSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppCard.glass(
        gradient: palette.brandGradient,
        opacity: 0.92,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Average',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '${summary.overallAverage.toStringAsFixed(1)}%',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _MiniStat(
                  label: 'Highest',
                  value: '${summary.highest.toStringAsFixed(0)}%'),
              const SizedBox(width: 24),
              _MiniStat(
                  label: 'Lowest',
                  value: '${summary.lowest.toStringAsFixed(0)}%'),
            ]),
            if (summary.subjectAverages.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...summary.subjectAverages.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Expanded(
                        child: Text(e.key,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                      Text(
                        '${e.value.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ]),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      ],
    );
  }
}

class _SubjectFilter extends StatelessWidget {
  final List<String> subjects;
  final String? selected;
  final void Function(String?) onSelect;
  const _SubjectFilter(
      {required this.subjects,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        FilterPill(
          label: 'All',
          selected: selected == null,
          onSelected: (_) => onSelect(null),
        ),
        ...subjects.map((s) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterPill(
                label: s,
                selected: selected == s,
                onSelected: (_) => onSelect(selected == s ? null : s),
              ),
            )),
        const SizedBox(width: 8),
      ]),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  final AssessmentModel assessment;
  const _AssessmentCard({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = assessment.percentage;
    final pctColor = pct >= 85
        ? const Color(0xFF10B981)
        : pct >= 70
            ? const Color(0xFFF59E0B)
            : const Color(0xFFE11D48);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: AppCard.surface(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  assessment.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              if (assessment.grade != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pctColor.withValues(alpha: 0.12),
                    borderRadius: Radii.pillRadius,
                  ),
                  child: Text(
                    assessment.grade!,
                    style: TextStyle(
                        color: pctColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              _Tag(label: assessment.subject, color: cs.primary),
              const SizedBox(width: 8),
              _Tag(label: assessment.type, color: cs.secondary),
              const Spacer(),
              Text(
                '${assessment.score.toStringAsFixed(0)} / ${assessment.maxScore.toStringAsFixed(0)}',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: pctColor),
              ),
            ]),
            if (assessment.feedback != null) ...[
              const SizedBox(height: 8),
              Text(
                assessment.feedback!,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: Radii.xsRadius,
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 4,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(pctColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: Radii.smRadius,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Schedule Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab();

  static const _days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday',
  ];
  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        if (state is ScheduleLoading || state is ScheduleInitial) {
          return const CardListSkeleton();
        }
        if (state is ScheduleError) {
          return ErrorView(
              message: state.message,
              onRetry: () => context.read<ScheduleCubit>().load());
        }
        if (state is! ScheduleLoaded) return const SizedBox.shrink();

        return Column(
          children: [
            // Day selector
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              child: Row(
                children: List.generate(_days.length, (i) {
                  final selected = state.selectedDay == _days[i];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FilterPill(
                        label: _labels[i],
                        selected: selected,
                        onSelected: (_) => context
                            .read<ScheduleCubit>()
                            .selectDay(_days[i]),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: state.slotsForDay.isEmpty
                  ? Center(
                      child: Text(
                        'No classes on this day.',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: state.slotsForDay.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          _SlotCard(slot: state.slotsForDay[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SlotCard extends StatelessWidget {
  final ScheduleSlotModel slot;
  const _SlotCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard.surface(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: Radii.xsRadius,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slot.subject,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 3),
              Text(slot.teacherName,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(slot.startTime,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.primary)),
            Text(slot.endTime,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Homework Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeworkTab extends StatelessWidget {
  const _HomeworkTab();

  static const _filters = [
    null, 'pending', 'submitted', 'graded', 'late'
  ];
  static const _labels = ['All', 'Pending', 'Submitted', 'Graded', 'Late'];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeworkCubit, HomeworkState>(
      builder: (context, state) {
        if (state is HomeworkLoading || state is HomeworkInitial) {
          return const CardListSkeleton();
        }
        if (state is HomeworkError) {
          return ErrorView(
              message: state.message,
              onRetry: () => context.read<HomeworkCubit>().load());
        }
        if (state is! HomeworkLoaded) return const SizedBox.shrink();

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: List.generate(_filters.length, (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterPill(
                    label: _labels[i],
                    selected: state.statusFilter == _filters[i],
                    onSelected: (_) => context
                        .read<HomeworkCubit>()
                        .filterByStatus(_filters[i]),
                  ),
                )),
              ),
            ),
            Expanded(
              child: state.filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No homework here.',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16),
                      itemCount: state.filtered.length,
                      itemBuilder: (context, i) =>
                          _HomeworkCard(hw: state.filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final HomeworkModel hw;
  const _HomeworkCard({required this.hw});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard.surface(
        onTap: () => _showDetail(context, hw),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(hw.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              StatusPill(
                label: _statusLabel(hw.status),
                tone: _statusTone(hw.status),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.person_outline_rounded,
                  size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(hw.teacherName,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant)),
              const Spacer(),
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                _fmtDate(hw.dueDate),
                style: TextStyle(
                    fontSize: 12,
                    color: hw.status == 'late'
                        ? const Color(0xFFE11D48)
                        : cs.onSurfaceVariant),
              ),
            ]),
            if (hw.description != null) ...[
              const SizedBox(height: 8),
              Text(
                hw.description!,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (hw.status == 'graded' && hw.grade != null) ...[
              const SizedBox(height: 8),
              AppCard.filled(
                color: cs.surfaceContainerHighest,
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  Icon(Icons.star_rounded,
                      size: 16, color: const Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Text(
                    'Grade: ${hw.grade!.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  if (hw.gradeFeedback != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hw.gradeFeedback!,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ]),
              ),
            ],
            if (hw.status == 'pending' || hw.status == 'late') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.upload_rounded, size: 16),
                  label: const Text('Submit'),
                  onPressed: () => _showSubmitDialog(context, hw),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, HomeworkModel hw) {
    showAppBottomSheet<void>(
      context: context,
      title: hw.title,
      subtitle: hw.subject,
      builder: (_) => _HomeworkDetailContent(hw: hw),
    );
  }

  void _showSubmitDialog(BuildContext context, HomeworkModel hw) {
    final cubit = context.read<HomeworkCubit>();
    showAppBottomSheet<void>(
      context: context,
      title: 'Submit Homework',
      subtitle: hw.title,
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: _SubmitHomeworkSheet(hw: hw),
      ),
    );
  }

  StatusTone _statusTone(String status) => switch (status) {
        'submitted' => StatusTone.info,
        'graded' => StatusTone.success,
        'late' => StatusTone.error,
        _ => StatusTone.warning,
      };

  String _statusLabel(String status) => switch (status) {
        'submitted' => 'Submitted',
        'graded' => 'Graded',
        'late' => 'Late',
        _ => 'Pending',
      };

  String _fmtDate(String iso) {
    try {
      return DateFormat('d MMM y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

class _HomeworkDetailContent extends StatelessWidget {
  final HomeworkModel hw;
  const _HomeworkDetailContent({required this.hw});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _Tag(label: hw.subject, color: cs.primary),
            const SizedBox(width: 8),
            _Tag(label: hw.teacherName, color: cs.secondary),
          ]),
          const SizedBox(height: 16),
          if (hw.description != null)
            Text(hw.description!,
                style: TextStyle(fontSize: 14, color: cs.onSurface)),
          if (hw.isSubmitted) ...[
            const SizedBox(height: 16),
            Text('Your submission',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: cs.primary)),
            const SizedBox(height: 6),
            AppCard.filled(
              color: cs.surfaceContainerHighest,
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hw.submittedContent ??
                        'File submitted. Your teacher will review it.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ]),
            ),
          ],
          if (hw.grade != null) ...[
            const SizedBox(height: 16),
            Text('Teacher Feedback',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: cs.primary)),
            const SizedBox(height: 6),
            Text(
              'Grade: ${hw.grade!.toStringAsFixed(0)}'
              '${hw.gradeFeedback != null ? '\n${hw.gradeFeedback}' : ''}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Attendance Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        if (state is AttendanceLoading || state is AttendanceInitial) {
          return const CardListSkeleton();
        }
        if (state is AttendanceError) {
          return ErrorView(
              message: state.message,
              onRetry: () => context.read<AttendanceCubit>().load());
        }
        if (state is! AttendanceLoaded) return const SizedBox.shrink();
        final s = state.summary;

        return RefreshIndicator(
          onRefresh: () => context.read<AttendanceCubit>().load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AttendanceSummaryCard(summary: s),
              const SizedBox(height: 16),
              Row(children: [
                _AttendStat(
                    label: 'Present',
                    value: s.present,
                    color: const Color(0xFF10B981)),
                _AttendStat(
                    label: 'Absent',
                    value: s.absent,
                    color: const Color(0xFFE11D48)),
                _AttendStat(
                    label: 'Late',
                    value: s.late,
                    color: const Color(0xFFF59E0B)),
                _AttendStat(
                    label: 'Excused',
                    value: s.excused,
                    color: const Color(0xFF3B82F6)),
              ]),
              const SizedBox(height: 16),
              Text('Recent Records',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...s.records.reversed.take(20).map(
                    (r) => _AttendanceRow(record: r),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  final AttendanceSummaryModel summary;
  const _AttendanceSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final pct = summary.percent;
    final color = pct >= 90
        ? const Color(0xFF10B981)
        : pct >= 75
            ? const Color(0xFFF59E0B)
            : const Color(0xFFE11D48);

    return AppCard.filled(
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: pct / 100,
                strokeWidth: 8,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: color),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Attendance Rate',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                pct >= 90
                    ? 'Excellent! Keep it up.'
                    : pct >= 75
                        ? 'Needs improvement.'
                        : 'At risk. Please attend regularly.',
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _AttendStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _AttendStat(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AppCard.filled(
          color: color.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
              Text(label,
                  style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final AttendanceRecordModel record;
  const _AttendanceRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (color, icon, label) = switch (record.status) {
      'absent' => (
          const Color(0xFFE11D48),
          Icons.cancel_rounded,
          'Absent'
        ),
      'late' => (
          const Color(0xFFF59E0B),
          Icons.watch_later_rounded,
          'Late'
        ),
      'excused' => (
          const Color(0xFF3B82F6),
          Icons.info_rounded,
          'Excused'
        ),
      _ => (
          const Color(0xFF10B981),
          Icons.check_circle_rounded,
          'Present'
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          _fmtDate(record.date),
          style: TextStyle(fontSize: 13, color: cs.onSurface),
        ),
        const Spacer(),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _fmtDate(String iso) {
    try {
      return DateFormat('EEE, d MMM').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Homework submission sheet ─────────────────────────────────────────────────

class _SubmitHomeworkSheet extends StatefulWidget {
  final HomeworkModel hw;
  const _SubmitHomeworkSheet({required this.hw});

  @override
  State<_SubmitHomeworkSheet> createState() => _SubmitHomeworkSheetState();
}

class _SubmitHomeworkSheetState extends State<_SubmitHomeworkSheet> {
  PlatformFile? _picked;
  bool _busy = false;

  static const _allowedExtensions = [
    'pdf', 'doc', 'docx', 'ppt', 'pptx',
    'xls', 'xlsx', 'txt', 'zip',
    'jpg', 'jpeg', 'png',
  ];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      setState(() => _picked = result.files.single);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file picker: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a file to attach.')),
      );
      return;
    }
    final cubit = context.read<HomeworkCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _busy = true);
    final ok = await cubit.submit(
      hwId: widget.hw.id,
      filePath: _picked!.path,
      fileBytes: _picked!.bytes,
      fileName: _picked!.name,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Homework submitted.' : 'Submission failed.'),
      ),
    );
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final picked = _picked;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File picker tile
          InkWell(
            onTap: _busy ? null : _pickFile,
            borderRadius: Radii.mdRadius,
            child: AppCard.filled(
              color: cs.surfaceContainerHighest,
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(
                  picked == null
                      ? Icons.upload_file_rounded
                      : Icons.insert_drive_file_rounded,
                  color: picked == null ? cs.onSurfaceVariant : cs.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        picked?.name ?? 'Choose a file',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: picked == null
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        picked == null
                            ? 'PDF, Word, image, zip — up to 10 MB'
                            : _formatBytes(picked.size),
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (picked != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed:
                        _busy ? null : () => setState(() => _picked = null),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          AppButton.primary(
            label: 'Submit',
            icon: Icons.send_rounded,
            fullWidth: true,
            size: AppButtonSize.lg,
            loading: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
