import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
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
        title: const Text('My Classes', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<TeacherClassesCubit, TeacherClassesState>(
        builder: (context, state) {
          if (state is TeacherClassesLoading || state is TeacherClassesInitial) {
            return const LoadingView();
          }
          if (state is TeacherClassesError) {
            return ErrorView(message: state.message, onRetry: () => context.read<TeacherClassesCubit>().load());
          }
          if (state is! TeacherClassesLoaded) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () => context.read<TeacherClassesCubit>().load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.classes.length,
              itemBuilder: (context, i) => _ClassCard(classModel: state.classes[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final TeacherClassModel classModel;
  const _ClassCard({required this.classModel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showStudents(context, classModel),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.groups_rounded, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(classModel.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(classModel.subject, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${classModel.students.length}',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.primary)),
                      Text('students', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Average score bar
              Row(
                children: [
                  Text('Class avg:', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _avg(classModel.students) / 100,
                        minHeight: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${_avg(classModel.students).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _avg(List<ClassStudentModel> students) {
    if (students.isEmpty) return 0;
    final sum = students.fold<double>(0, (acc, s) => acc + (s.averageScore ?? 0));
    return sum / students.length;
  }

  void _showStudents(BuildContext context, TeacherClassModel classModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _StudentsSheet(classModel: classModel),
    );
  }
}

class _StudentsSheet extends StatelessWidget {
  final TeacherClassModel classModel;
  const _StudentsSheet({required this.classModel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                Row(
                  children: [
                    Text(classModel.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${classModel.students.length} students',
                          style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(classModel.subject, style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 12),
                const Divider(),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: classModel.students.length,
              itemBuilder: (context, i) {
                final s = classModel.students[i];
                final avg = s.averageScore ?? 0;
                final color = avg >= 85 ? Colors.green.shade600
                    : avg >= 70 ? Colors.orange.shade600
                    : Colors.red.shade600;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Text(s.name[0], style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: s.attendancePercent != null
                      ? Text('Attendance: ${s.attendancePercent!.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))
                      : null,
                  trailing: s.averageScore != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${avg.toStringAsFixed(0)}%',
                              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
