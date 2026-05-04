import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/parent/data/models/parent_models.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ParentAcademicsScreen extends StatefulWidget {
  const ParentAcademicsScreen({super.key});

  @override
  State<ParentAcademicsScreen> createState() => _ParentAcademicsScreenState();
}

class _ParentAcademicsScreenState extends State<ParentAcademicsScreen>
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
      body: BlocBuilder<ParentCubit, ParentState>(
        builder: (context, state) {
          if (state is! ParentLoaded) return const CardListSkeleton();
          return TabBarView(
            controller: _tab,
            children: [
              _MarksTab(state: state),
              _ScheduleTab(state: state),
              _HomeworkTab(state: state),
              _AttendanceTab(state: state),
            ],
          );
        },
      ),
    );
  }
}

// ══ Marks ═════════════════════════════════════════════════════════════════════

class _MarksTab extends StatelessWidget {
  final ParentLoaded state;
  const _MarksTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final subjects = (state.marks[state.selectedChildId] ?? [])
        .map((m) => m.subject)
        .toSet()
        .toList()
      ..sort();

    return CustomScrollView(slivers: [
      // Summary card
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppCard.glass(
            gradient: palette.brandGradient,
            opacity: 0.92,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                state.selectedChild.name,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '${state.selectedChild.averageScore.toStringAsFixed(1)}% avg',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800),
              ),
            ]),
          ),
        ),
      ),
      // Subject filter
      SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            FilterPill(
              label: 'All',
              selected: state.marksSubjectFilter == null,
              onSelected: (_) =>
                  context.read<ParentCubit>().filterMarksBySubject(null),
            ),
            ...subjects.map((s) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterPill(
                    label: s,
                    selected: state.marksSubjectFilter == s,
                    onSelected: (_) => context
                        .read<ParentCubit>()
                        .filterMarksBySubject(
                            state.marksSubjectFilter == s ? null : s),
                  ),
                )),
            const SizedBox(width: 8),
          ]),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _AssessmentCard(a: state.filteredMarks[i]),
          childCount: state.filteredMarks.length,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]);
  }
}

class _AssessmentCard extends StatelessWidget {
  final ParentAssessmentModel a;
  const _AssessmentCard({required this.a});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = a.percentage;
    final pctColor = pct >= 85
        ? const Color(0xFF10B981)
        : pct >= 70
            ? const Color(0xFFF59E0B)
            : const Color(0xFFE11D48);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: AppCard.surface(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(a.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            if (a.grade != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: pctColor.withValues(alpha: 0.12),
                    borderRadius: Radii.pillRadius),
                child: Text(a.grade!,
                    style: TextStyle(
                        color: pctColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _Tag(label: a.subject, color: cs.primary),
            const SizedBox(width: 8),
            _Tag(label: a.type, color: cs.secondary),
            const Spacer(),
            Text(
              '${a.score.toStringAsFixed(0)}/${a.maxScore.toStringAsFixed(0)}',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: pctColor),
            ),
          ]),
          if (a.feedback != null) ...[
            const SizedBox(height: 6),
            Text(a.feedback!,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic)),
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
        ]),
      ),
    );
  }
}

// ══ Schedule ══════════════════════════════════════════════════════════════════

class _ScheduleTab extends StatelessWidget {
  final ParentLoaded state;
  const _ScheduleTab({required this.state});

  static const _days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: List.generate(_days.length, (i) {
            final sel = state.selectedDay == _days[i];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FilterPill(
                  label: _labels[i],
                  selected: sel,
                  onSelected: (_) =>
                      context.read<ParentCubit>().selectDay(_days[i]),
                ),
              ),
            );
          }),
        ),
      ),
      Expanded(
        child: state.slotsForDay.isEmpty
            ? Center(
                child: Text('No classes.',
                    style: TextStyle(color: cs.onSurfaceVariant)))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                itemCount: state.slotsForDay.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final slot = state.slotsForDay[i];
                  return AppCard.surface(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 4,
                        height: 44,
                        decoration: BoxDecoration(
                            color: cs.primary, borderRadius: Radii.xsRadius),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(slot.subject,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
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
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }
}

// ══ Homework ══════════════════════════════════════════════════════════════════

class _HomeworkTab extends StatelessWidget {
  final ParentLoaded state;
  const _HomeworkTab({required this.state});

  static const _filters = [null, 'pending', 'submitted', 'graded', 'late'];
  static const _labels = ['All', 'Pending', 'Submitted', 'Graded', 'Late'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: List.generate(
              _filters.length,
              (i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterPill(
                      label: _labels[i],
                      selected: state.homeworkStatusFilter == _filters[i],
                      onSelected: (_) => context
                          .read<ParentCubit>()
                          .filterHomeworkByStatus(_filters[i]),
                    ),
                  )),
        ),
      ),
      Expanded(
        child: state.filteredHomework.isEmpty
            ? Center(
                child: Text('No homework here.',
                    style:
                        TextStyle(color: cs.onSurfaceVariant)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.filteredHomework.length,
                itemBuilder: (context, i) =>
                    _HwCard(hw: state.filteredHomework[i]),
              ),
      ),
    ]);
  }
}

class _HwCard extends StatelessWidget {
  final ParentHomeworkModel hw;
  const _HwCard({required this.hw});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (tone, label) = switch (hw.status) {
      'submitted' => (StatusTone.info, 'Submitted'),
      'graded' => (StatusTone.success, 'Graded'),
      'late' => (StatusTone.error, 'Late'),
      _ => (StatusTone.warning, 'Pending'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard.surface(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(hw.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            StatusPill(label: label, tone: tone),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.person_outline_rounded,
                size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(hw.teacherName,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const Spacer(),
            Icon(Icons.calendar_today_outlined,
                size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(_fmtDate(hw.dueDate),
                style: TextStyle(
                    fontSize: 12,
                    color: hw.status == 'late'
                        ? const Color(0xFFE11D48)
                        : cs.onSurfaceVariant)),
          ]),
          if (hw.description != null) ...[
            const SizedBox(height: 8),
            Text(hw.description!,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          if (hw.grade != null) ...[
            const SizedBox(height: 8),
            AppCard.filled(
              color: cs.surfaceContainerHighest,
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                const Icon(Icons.star_rounded,
                    size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Text('Grade: ${hw.grade!.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                if (hw.gradeFeedback != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(hw.gradeFeedback!,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      return DateFormat('d MMM y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ══ Attendance ════════════════════════════════════════════════════════════════

class _AttendanceTab extends StatelessWidget {
  final ParentLoaded state;
  const _AttendanceTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final summary = state.attendance[state.selectedChildId];
    if (summary == null) return const CardListSkeleton();

    final pct = summary.percent;
    final color = pct >= 90
        ? const Color(0xFF10B981)
        : pct >= 75
            ? const Color(0xFFF59E0B)
            : const Color(0xFFE11D48);
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard.filled(
          color: color.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: pct / 100,
                  strokeWidth: 8,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text('${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: color)),
              ]),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.selectedChild.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      pct >= 90
                          ? 'Excellent attendance!'
                          : pct >= 75
                              ? 'Needs improvement.'
                              : 'At risk.',
                      style: TextStyle(
                          fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _AttendStat(
              label: 'Present',
              value: summary.present,
              color: const Color(0xFF10B981)),
          _AttendStat(
              label: 'Absent',
              value: summary.absent,
              color: const Color(0xFFE11D48)),
          _AttendStat(
              label: 'Late',
              value: summary.late,
              color: const Color(0xFFF59E0B)),
          _AttendStat(
              label: 'Excused',
              value: summary.excused,
              color: const Color(0xFF3B82F6)),
        ]),
        const SizedBox(height: 16),
        Text('Recent Records',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...summary.records.reversed.take(20).map((r) {
          final (c, icon) = switch (r.status) {
            'absent' => (const Color(0xFFE11D48), Icons.cancel_rounded),
            'late' => (
                const Color(0xFFF59E0B),
                Icons.watch_later_rounded
              ),
            'excused' => (const Color(0xFF3B82F6), Icons.info_rounded),
            _ => (const Color(0xFF10B981), Icons.check_circle_rounded),
          };
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 10),
              Text(_fmtDate(r.date),
                  style: TextStyle(fontSize: 13, color: cs.onSurface)),
              const Spacer(),
              Text(
                r.status[0].toUpperCase() + r.status.substring(1),
                style: TextStyle(
                    fontSize: 13, color: c, fontWeight: FontWeight.w600),
              ),
            ]),
          );
        }),
      ],
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

class _AttendStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _AttendStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AppCard.filled(
            color: color.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              Text('$value',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ]),
          ),
        ),
      );
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), borderRadius: Radii.smRadius),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );
}
