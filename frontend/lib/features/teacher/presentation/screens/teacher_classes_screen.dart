import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_classes_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_classes_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherClassesScreen extends StatelessWidget {
  const TeacherClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<TeacherClassesCubit, TeacherClassesState>(
        builder: (context, state) {
          if (state is TeacherClassesLoading ||
              state is TeacherClassesInitial) {
            return const CardListSkeleton();
          }
          if (state is TeacherClassesError) {
            return ErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<TeacherClassesCubit>().load());
          }
          if (state is! TeacherClassesLoaded) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () => context.read<TeacherClassesCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.classes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _ClassCard(classModel: state.classes[i]),
            ),
          );
        },
      ),
    );
  }
}

// ── Class card ────────────────────────────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  final TeacherClassModel classModel;
  const _ClassCard({required this.classModel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppCard.surface(
      onTap: () => _showStudents(context, classModel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: Radii.smRadius,
                ),
                child:
                    Icon(Icons.groups_rounded, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(classModel.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(classModel.subject,
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${classModel.students.length}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: cs.primary)),
                  Text('students',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Class avg:',
                  style:
                      TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: Radii.xsRadius,
                  child: LinearProgressIndicator(
                    value: _avg(classModel.students) / 100,
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                  '${_avg(classModel.students).toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.primary)),
            ],
          ),
        ],
      ),
    );
  }

  double _avg(List<ClassStudentModel> students) {
    if (students.isEmpty) return 0;
    final sum = students.fold<double>(
        0, (acc, s) => acc + (s.averageScore ?? 0));
    return sum / students.length;
  }

  void _showStudents(BuildContext context, TeacherClassModel classModel) {
    showAppBottomSheet<void>(
      context: context,
      title: classModel.name,
      subtitle: classModel.subject,
      builder: (_) => _StudentsContent(classModel: classModel),
    );
  }
}

// ── Students sheet content ────────────────────────────────────────────────────

class _StudentsContent extends StatelessWidget {
  final TeacherClassModel classModel;
  const _StudentsContent({required this.classModel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: Radii.pillRadius,
              ),
              child: Text('${classModel.students.length} students',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          ...classModel.students.map((s) {
            final avg = s.averageScore ?? 0;
            final color = avg >= 85
                ? const Color(0xFF10B981)
                : avg >= 70
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFE11D48);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Text(s.name[0],
                        style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        if (s.attendancePercent != null)
                          Text(
                              'Attendance: ${s.attendancePercent!.toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (s.averageScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: Radii.pillRadius,
                      ),
                      child: Text('${avg.toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
