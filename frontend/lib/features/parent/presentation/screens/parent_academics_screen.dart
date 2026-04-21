import 'package:first_try/core/widgets/shared/loading_view.dart';
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
  void initState() { super.initState(); _tab = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academics', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tab, isScrollable: true, tabAlignment: TabAlignment.start,
          tabs: const [Tab(text: 'Marks'), Tab(text: 'Schedule'), Tab(text: 'Homework'), Tab(text: 'Attendance')],
        ),
      ),
      body: BlocBuilder<ParentCubit, ParentState>(
        builder: (context, state) {
          if (state is! ParentLoaded) return const LoadingView();
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
    final cs = Theme.of(context).colorScheme;
    final subjects = (state.marks[state.selectedChildId] ?? [])
        .map((m) => m.subject).toSet().toList()..sort();

    return CustomScrollView(slivers: [
      // Summary
      SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(state.selectedChild.name,
                style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.85), fontSize: 13)),
            Text('${state.selectedChild.averageScore.toStringAsFixed(1)}% avg',
                style: TextStyle(color: cs.onPrimary, fontSize: 32, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
      // Subject filter
      SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            _Chip(label: 'All', selected: state.marksSubjectFilter == null,
                onTap: () => context.read<ParentCubit>().filterMarksBySubject(null)),
            ...subjects.map((s) => _Chip(
                label: s,
                selected: state.marksSubjectFilter == s,
                onTap: () => context.read<ParentCubit>()
                    .filterMarksBySubject(state.marksSubjectFilter == s ? null : s))),
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
    final color = pct >= 85 ? Colors.green.shade600 : pct >= 70 ? Colors.orange.shade600 : Colors.red.shade600;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: cs.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
            if (a.grade != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(a.grade!, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _Tag(label: a.subject, color: cs.primary),
            const SizedBox(width: 8),
            _Tag(label: a.type, color: cs.secondary),
            const Spacer(),
            Text('${a.score.toStringAsFixed(0)}/${a.maxScore.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
          ]),
          if (a.feedback != null) ...[
            const SizedBox(height: 6),
            Text(a.feedback!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100, minHeight: 4,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
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

  static const _days   = ['monday','tuesday','wednesday','thursday','friday'];
  static const _labels = ['Mon','Tue','Wed','Thu','Fri'];

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
              child: GestureDetector(
                onTap: () => context.read<ParentCubit>().selectDay(_days[i]),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? cs.primary : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_labels[i], textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: sel ? cs.onPrimary : cs.onSurfaceVariant)),
                ),
              ),
            );
          }),
        ),
      ),
      Expanded(
        child: state.slotsForDay.isEmpty
            ? Center(child: Text('No classes.', style: TextStyle(color: cs.onSurfaceVariant)))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: state.slotsForDay.length,
                separatorBuilder: (context, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final slot = state.slotsForDay[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: cs.surface, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant)),
                    child: Row(children: [
                      Container(width: 4, height: 44,
                          decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(slot.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(slot.teacherName, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(slot.startTime, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.primary)),
                        Text(slot.endTime, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      ]),
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
  static const _labels  = ['All', 'Pending', 'Submitted', 'Graded', 'Late'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: List.generate(_filters.length, (i) => _Chip(
            label: _labels[i],
            selected: state.homeworkStatusFilter == _filters[i],
            onTap: () => context.read<ParentCubit>().filterHomeworkByStatus(_filters[i]),
          )),
        ),
      ),
      Expanded(
        child: state.filteredHomework.isEmpty
            ? Center(child: Text('No homework here.', style: TextStyle(color: cs.onSurfaceVariant)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.filteredHomework.length,
                itemBuilder: (context, i) => _HwCard(hw: state.filteredHomework[i]),
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
    Color statusColor;
    String statusLabel;
    switch (hw.status) {
      case 'submitted': statusColor = Colors.blue.shade600;   statusLabel = 'Submitted'; break;
      case 'graded':    statusColor = Colors.green.shade600;  statusLabel = 'Graded'; break;
      case 'late':      statusColor = Colors.red.shade600;    statusLabel = 'Late'; break;
      default:          statusColor = Colors.orange.shade600; statusLabel = 'Pending';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: cs.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(hw.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.person_outline_rounded, size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(hw.teacherName, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const Spacer(),
            Icon(Icons.calendar_today_outlined, size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(_fmtDate(hw.dueDate),
                style: TextStyle(fontSize: 12,
                    color: hw.status == 'late' ? Colors.red.shade600 : cs.onSurfaceVariant)),
          ]),
          if (hw.description != null) ...[
            const SizedBox(height: 8),
            Text(hw.description!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (hw.grade != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade600),
                const SizedBox(width: 6),
                Text('Grade: ${hw.grade!.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                if (hw.gradeFeedback != null) ...[
                  const SizedBox(width: 8),
                  Expanded(child: Text(hw.gradeFeedback!,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  String _fmtDate(String iso) {
    try { return DateFormat('d MMM y').format(DateTime.parse(iso)); }
    catch (_) { return iso; }
  }
}

// ══ Attendance ════════════════════════════════════════════════════════════════

class _AttendanceTab extends StatelessWidget {
  final ParentLoaded state;
  const _AttendanceTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final summary = state.attendance[state.selectedChildId];
    if (summary == null) return const LoadingView();

    final pct = summary.percent;
    final color = pct >= 90 ? Colors.green.shade600 : pct >= 75 ? Colors.orange.shade600 : Colors.red.shade600;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Circle indicator
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            SizedBox(width: 80, height: 80, child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: pct / 100, strokeWidth: 8,
                  backgroundColor: color.withValues(alpha: 0.2), valueColor: AlwaysStoppedAnimation(color)),
              Text('${pct.toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
            ])),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(state.selectedChild.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(pct >= 90 ? 'Excellent attendance!' : pct >= 75 ? 'Needs improvement.' : 'At risk.',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _AttendStat(label: 'Present', value: summary.present, color: Colors.green.shade600),
          _AttendStat(label: 'Absent',  value: summary.absent,  color: Colors.red.shade600),
          _AttendStat(label: 'Late',    value: summary.late,    color: Colors.orange.shade600),
          _AttendStat(label: 'Excused', value: summary.excused, color: Colors.blue.shade600),
        ]),
        const SizedBox(height: 16),
        Text('Recent Records',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...summary.records.reversed.take(20).map((r) {
          Color c; IconData icon;
          switch (r.status) {
            case 'absent':  c = Colors.red.shade600;    icon = Icons.cancel_rounded; break;
            case 'late':    c = Colors.orange.shade600; icon = Icons.watch_later_rounded; break;
            case 'excused': c = Colors.blue.shade600;   icon = Icons.info_rounded; break;
            default:        c = Colors.green.shade600;  icon = Icons.check_circle_rounded;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 10),
              Text(_fmtDate(r.date), style: TextStyle(fontSize: 13, color: cs.onSurface)),
              const Spacer(),
              Text(r.status[0].toUpperCase() + r.status.substring(1),
                  style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w600)),
            ]),
          );
        }),
      ],
    );
  }

  String _fmtDate(String iso) {
    try { return DateFormat('EEE, d MMM').format(DateTime.parse(iso)); }
    catch (_) { return iso; }
  }
}

class _AttendStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _AttendStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ]),
        ),
      );
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );
}
