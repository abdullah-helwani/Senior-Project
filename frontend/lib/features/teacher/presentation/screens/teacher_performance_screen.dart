import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/teacher/data/models/teacher_extra_models.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_performance_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TeacherPerformanceScreen extends StatefulWidget {
  const TeacherPerformanceScreen({super.key});

  @override
  State<TeacherPerformanceScreen> createState() =>
      _TeacherPerformanceScreenState();
}

class _TeacherPerformanceScreenState extends State<TeacherPerformanceScreen> {
  final _sectionCtrl = TextEditingController();
  DateTime? _weekOf;

  @override
  void dispose() {
    _sectionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Report',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // ── Filters ─────────────────────────────────────────────────────
          _Filters(
            sectionCtrl: _sectionCtrl,
            weekOf: _weekOf,
            onWeekTap: _pickWeek,
            onLoad: _load,
          ),
          const Divider(height: 1),
          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<TeacherPerformanceCubit, TeacherPerformanceState>(
              builder: (context, state) {
                if (state is TeacherPerformanceInitial) {
                  return const EmptyState(
                    icon: Icons.insights_rounded,
                    title: 'Select a section',
                    subtitle:
                        'Enter a section ID and tap Load to view weekly performance.',
                  );
                }
                if (state is TeacherPerformanceLoading) {
                  return const CardListSkeleton();
                }
                if (state is TeacherPerformanceError) {
                  return ErrorView(
                      message: state.message, onRetry: _load);
                }
                if (state is! TeacherPerformanceLoaded) {
                  return const SizedBox.shrink();
                }
                final r = state.report;
                if (r.students.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No data',
                    subtitle:
                        'No student performance for this section/week.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _WeekHeader(report: r),
                      const SizedBox(height: 12),
                      for (final s in r.students)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StudentCard(student: s),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekOf ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _weekOf = picked);
  }

  void _load() {
    final id = int.tryParse(_sectionCtrl.text.trim());
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid section ID.')),
      );
      return;
    }
    context.read<TeacherPerformanceCubit>().load(
          sectionId: id,
          weekOf: _weekOf == null
              ? null
              : DateFormat('yyyy-MM-dd').format(_weekOf!),
        );
  }
}

// ── Filters bar ───────────────────────────────────────────────────────────────

class _Filters extends StatelessWidget {
  final TextEditingController sectionCtrl;
  final DateTime? weekOf;
  final VoidCallback onWeekTap;
  final VoidCallback onLoad;
  const _Filters({
    required this.sectionCtrl,
    required this.weekOf,
    required this.onWeekTap,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: TextField(
              controller: sectionCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Section ID',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: onWeekTap,
              borderRadius: Radii.mdRadius,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Week of',
                  isDense: true,
                  prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                ),
                child: Text(
                  weekOf == null
                      ? 'Current'
                      : DateFormat('d MMM y').format(weekOf!),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AppButton.primary(
            label: 'Load',
            size: AppButtonSize.sm,
            onPressed: onLoad,
          ),
        ],
      ),
    );
  }
}

// ── Week header ───────────────────────────────────────────────────────────────

class _WeekHeader extends StatelessWidget {
  final PerformanceReportModel report;
  const _WeekHeader({required this.report});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard.filled(
      color: cs.primaryContainer,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Icon(Icons.date_range_rounded, color: cs.onPrimaryContainer),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Week ${report.weekStart} → ${report.weekEnd}',
                style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
              Text(
                '${report.totalSessions} sessions • ${report.students.length} students',
                style: TextStyle(
                    color: cs.onPrimaryContainer.withValues(alpha: 0.85),
                    fontSize: 11),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Student card ──────────────────────────────────────────────────────────────

class _StudentCard extends StatelessWidget {
  final StudentPerformanceModel student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard.surface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primaryContainer,
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(student.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _Metric(
              icon: Icons.fact_check_rounded,
              label: 'Attendance',
              value: student.attendancePercentage == null
                  ? '—'
                  : '${student.attendancePercentage!.toStringAsFixed(0)}%',
              color: const Color(0xFF10B981),
            ),
            const SizedBox(width: 8),
            _Metric(
              icon: Icons.grade_rounded,
              label: 'Avg Score',
              value: student.averageScore == null
                  ? '—'
                  : student.averageScore!.toStringAsFixed(1),
              color: cs.primary,
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _BehaviorPill(label: '+${student.positiveBehaviors}',
                color: const Color(0xFF10B981)),
            const SizedBox(width: 6),
            _BehaviorPill(label: '−${student.negativeBehaviors}',
                color: const Color(0xFFE11D48)),
            const SizedBox(width: 6),
            _BehaviorPill(label: '○${student.neutralBehaviors}',
                color: const Color(0xFF6B7280)),
            const Spacer(),
            Text('${student.assessments.length} assessments',
                style: TextStyle(
                    fontSize: 11, color: cs.onSurfaceVariant)),
          ]),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Metric(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: AppCard.filled(
          color: color.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(fontSize: 10, color: color)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ],
              ),
            ),
          ]),
        ),
      );
}

class _BehaviorPill extends StatelessWidget {
  final String label;
  final Color color;
  const _BehaviorPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: Radii.smRadius,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w700)),
      );
}
