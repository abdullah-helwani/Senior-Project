import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_homework_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_homework_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TeacherHomeworkScreen extends StatelessWidget {
  const TeacherHomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<TeacherHomeworkCubit, TeacherHomeworkState>(
        builder: (context, state) {
          if (state is TeacherHomeworkLoading || state is TeacherHomeworkInitial) {
            return const LoadingView();
          }
          if (state is TeacherHomeworkError) {
            return ErrorView(message: state.message, onRetry: () => context.read<TeacherHomeworkCubit>().load());
          }
          if (state is! TeacherHomeworkLoaded) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () => context.read<TeacherHomeworkCubit>().load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.homework.length,
              itemBuilder: (context, i) => _HomeworkCard(hw: state.homework[i]),
            ),
          );
        },
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final TeacherHomeworkModel hw;
  const _HomeworkCard({required this.hw});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDraft = hw.status == 'draft';
    final statusColor = isDraft ? Colors.grey.shade600 : Colors.green.shade600;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openSubmissions(context, hw),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(hw.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(isDraft ? 'Draft' : 'Published',
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Tag(label: hw.className, color: cs.primary),
                  const SizedBox(width: 6),
                  _Tag(label: hw.subject, color: cs.secondary),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('Due ${_fmtDate(hw.dueDate)}',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const Spacer(),
                  Icon(Icons.upload_rounded, size: 14, color: cs.primary),
                  const SizedBox(width: 4),
                  Text('${hw.submissionCount}/${hw.totalStudents} submitted',
                      style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
                ],
              ),
              if (!isDraft) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: hw.totalStudents > 0 ? hw.submissionCount / hw.totalStudents : 0,
                    minHeight: 5,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openSubmissions(BuildContext context, TeacherHomeworkModel hw) {
    context.read<TeacherHomeworkCubit>().loadSubmissions(hw.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => BlocProvider.value(
        value: context.read<TeacherHomeworkCubit>(),
        child: _SubmissionsSheet(hw: hw),
      ),
    );
  }

  String _fmtDate(String iso) {
    try { return DateFormat('d MMM y').format(DateTime.parse(iso)); }
    catch (_) { return iso; }
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

// ── Submissions Sheet ─────────────────────────────────────────────────────────

class _SubmissionsSheet extends StatelessWidget {
  final TeacherHomeworkModel hw;
  const _SubmissionsSheet({required this.hw});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, ctrl) => BlocBuilder<TeacherHomeworkCubit, TeacherHomeworkState>(
        builder: (context, state) {
          final subs = state is TeacherHomeworkLoaded
              ? (state.submissions[hw.id] ?? [])
              : <HomeworkSubmissionModel>[];
          final isLoading = state is TeacherHomeworkLoaded &&
              state.loadingSubmissions.contains(hw.id);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    Text(hw.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text('${hw.className} • ${hw.subject}',
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    const Divider(),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const LoadingView()
                    : subs.isEmpty
                        ? Center(child: Text('No submissions yet.', style: TextStyle(color: cs.onSurfaceVariant)))
                        : ListView.builder(
                            controller: ctrl,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: subs.length,
                            itemBuilder: (context, i) => _SubmissionTile(
                              sub: subs[i],
                              hwId: hw.id,
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final HomeworkSubmissionModel sub;
  final int hwId;
  const _SubmissionTile({required this.sub, required this.hwId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color statusColor;
    String statusLabel;
    switch (sub.status) {
      case 'graded':   statusColor = Colors.green.shade600;  statusLabel = 'Graded'; break;
      case 'submitted': statusColor = Colors.blue.shade600;  statusLabel = 'Submitted'; break;
      case 'late':     statusColor = Colors.orange.shade600; statusLabel = 'Late'; break;
      default:         statusColor = Colors.grey.shade500;   statusLabel = 'Pending';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primaryContainer,
                  child: Text(sub.studentName[0],
                      style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(sub.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            if (sub.content != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(sub.content!, style: const TextStyle(fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
            ],
            if (sub.grade != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 16),
                  const SizedBox(width: 4),
                  Text('${sub.grade!.toStringAsFixed(0)}/20',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (sub.feedback != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(sub.feedback!,
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ],
              ),
            ],
            if (sub.status == 'submitted' || sub.status == 'late') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.grading_rounded, size: 16),
                  label: const Text('Grade'),
                  onPressed: () => _showGradeDialog(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showGradeDialog(BuildContext context) {
    final gradeCtrl = TextEditingController();
    final feedbackCtrl = TextEditingController();
    final cubit = context.read<TeacherHomeworkCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Grade — ${sub.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Grade (out of 20)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Feedback (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final g = double.tryParse(gradeCtrl.text.trim());
              if (g != null && g >= 0 && g <= 20) {
                cubit.gradeSubmission(
                  hwId: hwId,
                  submissionId: sub.id,
                  grade: g,
                  feedback: feedbackCtrl.text.trim().isNotEmpty ? feedbackCtrl.text.trim() : null,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }
}
