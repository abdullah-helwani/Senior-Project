import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
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
          return const LoadingView();
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
              // Summary card
              SliverToBoxAdapter(
                child: _MarksSummaryCard(summary: state.summary),
              ),

              // Subject filter chips
              SliverToBoxAdapter(
                child: _SubjectFilter(
                  subjects: subjects,
                  selected: state.selectedSubject,
                  onSelect: (s) =>
                      context.read<MarksCubit>().filterBySubject(s),
                ),
              ),

              // Assessment list
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overall Average',
              style: TextStyle(
                  color: cs.onPrimary.withValues(alpha: 0.85),
                  fontSize: 13)),
          Text(
            '${summary.overallAverage.toStringAsFixed(1)}%',
            style: TextStyle(
                color: cs.onPrimary,
                fontSize: 36,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                  label: 'Highest',
                  value: '${summary.highest.toStringAsFixed(0)}%',
                  color: cs.onPrimary),
              const SizedBox(width: 24),
              _MiniStat(
                  label: 'Lowest',
                  value: '${summary.lowest.toStringAsFixed(0)}%',
                  color: cs.onPrimary),
            ],
          ),
          const SizedBox(height: 12),
          ...summary.subjectAverages.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.key,
                          style: TextStyle(
                              color: cs.onPrimary.withValues(alpha: 0.85),
                              fontSize: 12)),
                    ),
                    Text(
                      '${e.value.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: color.withValues(alpha: 0.7), fontSize: 11)),
        Text(value,
            style: TextStyle(
                color: color,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _Chip(
              label: 'All',
              selected: selected == null,
              onTap: () => onSelect(null)),
          ...subjects.map((s) => _Chip(
                label: s,
                selected: selected == s,
                onTap: () => onSelect(selected == s ? null : s),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 13,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
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
        ? Colors.green.shade600
        : pct >= 70
            ? Colors.orange.shade600
            : Colors.red.shade600;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      assessment.grade!,
                      style: TextStyle(
                          color: pctColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _Tag(label: assessment.subject, color: cs.primary),
                const SizedBox(width: 8),
                _Tag(
                    label: assessment.type,
                    color: cs.secondary),
                const Spacer(),
                Text(
                  '${assessment.score.toStringAsFixed(0)} / ${assessment.maxScore.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: pctColor),
                ),
              ],
            ),
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
            const SizedBox(height: 4),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
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
          return const LoadingView();
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
                  final cs = Theme.of(context).colorScheme;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => context
                          .read<ScheduleCubit>()
                          .selectDay(_days[i]),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primary
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _labels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? cs.onPrimary
                                : cs.onSurfaceVariant,
                          ),
                        ),
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
                      separatorBuilder: (context, _) =>
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(4),
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
                        fontSize: 12,
                        color: cs.onSurfaceVariant)),
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
        ],
      ),
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
          return const LoadingView();
        }
        if (state is HomeworkError) {
          return ErrorView(
              message: state.message,
              onRetry: () => context.read<HomeworkCubit>().load());
        }
        if (state is! HomeworkLoaded) return const SizedBox.shrink();

        return Column(
          children: [
            // Status filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: List.generate(_filters.length, (i) {
                  return _Chip(
                    label: _labels[i],
                    selected: state.statusFilter == _filters[i],
                    onTap: () => context
                        .read<HomeworkCubit>()
                        .filterByStatus(_filters[i]),
                  );
                }),
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
    final statusColor = _statusColor(hw.status);
    final statusLabel = _statusLabel(hw.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context, hw),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(hw.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                  _StatusBadge(
                      label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(hw.teacherName,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant)),
                  const Spacer(),
                  Icon(Icons.calendar_today_outlined,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDate(hw.dueDate),
                    style: TextStyle(
                        fontSize: 12,
                        color: hw.status == 'late'
                            ? Colors.red.shade600
                            : cs.onSurfaceVariant),
                  ),
                ],
              ),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 16,
                          color: Colors.amber.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Grade: ${hw.grade!.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                      if (hw.gradeFeedback != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hw.gradeFeedback!,
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (hw.status == 'pending' || hw.status == 'late') ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.upload_rounded, size: 16),
                    label: const Text('Submit'),
                    onPressed: () =>
                        _showSubmitDialog(context, hw),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, HomeworkModel hw) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _HomeworkDetailSheet(hw: hw),
    );
  }

  void _showSubmitDialog(BuildContext context, HomeworkModel hw) {
    final ctrl = TextEditingController();
    final cubit = context.read<HomeworkCubit>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Homework'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Type your answer here…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                cubit.submit(hw.id, ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.blue.shade600;
      case 'graded':
        return Colors.green.shade600;
      case 'late':
        return Colors.red.shade600;
      default:
        return Colors.orange.shade600;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'graded':
        return 'Graded';
      case 'late':
        return 'Late';
      default:
        return 'Pending';
    }
  }

  String _fmtDate(String iso) {
    try {
      return DateFormat('d MMM y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12)),
    );
  }
}

class _HomeworkDetailSheet extends StatelessWidget {
  final HomeworkModel hw;
  const _HomeworkDetailSheet({required this.hw});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(hw.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            _Tag(label: hw.subject, color: cs.primary),
            const SizedBox(width: 8),
            _Tag(label: hw.teacherName, color: cs.secondary),
          ]),
          const SizedBox(height: 16),
          if (hw.description != null)
            Text(hw.description!,
                style: TextStyle(
                    fontSize: 14, color: cs.onSurface)),
          if (hw.submittedContent != null) ...[
            const SizedBox(height: 16),
            Text('Your submission',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.primary)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(hw.submittedContent!,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
          if (hw.grade != null) ...[
            const SizedBox(height: 16),
            Text('Teacher Feedback',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.primary)),
            const SizedBox(height: 6),
            Text(
                'Grade: ${hw.grade!.toStringAsFixed(0)}${hw.gradeFeedback != null ? '\n${hw.gradeFeedback}' : ''}',
                style: const TextStyle(fontSize: 13)),
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
          return const LoadingView();
        }
        if (state is AttendanceError) {
          return ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<AttendanceCubit>().load());
        }
        if (state is! AttendanceLoaded) return const SizedBox.shrink();
        final s = state.summary;

        return RefreshIndicator(
          onRefresh: () => context.read<AttendanceCubit>().load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary circle
              _AttendanceSummaryCard(summary: s),
              const SizedBox(height: 16),
              // Stats row
              Row(
                children: [
                  _AttendStat(
                      label: 'Present',
                      value: s.present,
                      color: Colors.green.shade600),
                  _AttendStat(
                      label: 'Absent',
                      value: s.absent,
                      color: Colors.red.shade600),
                  _AttendStat(
                      label: 'Late',
                      value: s.late,
                      color: Colors.orange.shade600),
                  _AttendStat(
                      label: 'Excused',
                      value: s.excused,
                      color: Colors.blue.shade600),
                ],
              ),
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
    final cs = Theme.of(context).colorScheme;
    final pct = summary.percent;
    final color = pct >= 90
        ? Colors.green.shade600
        : pct >= 75
            ? Colors.orange.shade600
            : Colors.red.shade600;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pct / 100,
                  strokeWidth: 8,
                  backgroundColor:
                      color.withValues(alpha: 0.2),
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
                      color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
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
                style:
                    TextStyle(fontSize: 11, color: color)),
          ],
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
    Color color;
    IconData icon;
    String label;
    switch (record.status) {
      case 'absent':
        color = Colors.red.shade600;
        icon = Icons.cancel_rounded;
        label = 'Absent';
      case 'late':
        color = Colors.orange.shade600;
        icon = Icons.watch_later_rounded;
        label = 'Late';
      case 'excused':
        color = Colors.blue.shade600;
        icon = Icons.info_rounded;
        label = 'Excused';
      default:
        color = Colors.green.shade600;
        icon = Icons.check_circle_rounded;
        label = 'Present';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
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
        ],
      ),
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
