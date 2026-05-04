import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
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
        title: const Text('Homework',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<TeacherHomeworkCubit, TeacherHomeworkState>(
        builder: (context, state) {
          if (state is TeacherHomeworkLoading ||
              state is TeacherHomeworkInitial) {
            return const CardListSkeleton();
          }
          if (state is TeacherHomeworkError) {
            return ErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<TeacherHomeworkCubit>().load());
          }
          if (state is! TeacherHomeworkLoaded) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () => context.read<TeacherHomeworkCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.homework.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _HomeworkCard(hw: state.homework[i]),
            ),
          );
        },
      ),
    );
  }
}

// ── Homework card ─────────────────────────────────────────────────────────────

class _HomeworkCard extends StatelessWidget {
  final TeacherHomeworkModel hw;
  const _HomeworkCard({required this.hw});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDraft = hw.status == 'draft';

    return AppCard.surface(
      onTap: () => _openSubmissions(context, hw),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(hw.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              StatusPill(
                label: isDraft ? 'Draft' : 'Published',
                tone: isDraft ? StatusTone.neutral : StatusTone.success,
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
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Due ${_fmtDate(hw.dueDate)}',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant)),
              const Spacer(),
              Icon(Icons.upload_rounded, size: 14, color: cs.primary),
              const SizedBox(width: 4),
              Text('${hw.submissionCount}/${hw.totalStudents} submitted',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          if (!isDraft) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: Radii.xsRadius,
              child: LinearProgressIndicator(
                value: hw.totalStudents > 0
                    ? hw.submissionCount / hw.totalStudents
                    : 0,
                minHeight: 5,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openSubmissions(BuildContext context, TeacherHomeworkModel hw) {
    context.read<TeacherHomeworkCubit>().loadSubmissions(hw.id);
    final cubit = context.read<TeacherHomeworkCubit>();
    showAppBottomSheet<void>(
      context: context,
      title: hw.title,
      subtitle: '${hw.className} • ${hw.subject}',
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: _SubmissionsContent(hw: hw),
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

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: Radii.smRadius),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600)),
      );
}

// ── Submissions sheet content ─────────────────────────────────────────────────

class _SubmissionsContent extends StatelessWidget {
  final TeacherHomeworkModel hw;
  const _SubmissionsContent({required this.hw});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<TeacherHomeworkCubit, TeacherHomeworkState>(
      builder: (context, state) {
        final subs = state is TeacherHomeworkLoaded
            ? (state.submissions[hw.id] ?? [])
            : <HomeworkSubmissionModel>[];
        final isLoading = state is TeacherHomeworkLoaded &&
            state.loadingSubmissions.contains(hw.id);

        if (isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (subs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No submissions yet.',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: subs
                .map((sub) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SubmissionTile(sub: sub, hwId: hw.id),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

// ── Submission tile ───────────────────────────────────────────────────────────

class _SubmissionTile extends StatelessWidget {
  final HomeworkSubmissionModel sub;
  final int hwId;
  const _SubmissionTile({required this.sub, required this.hwId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (statusTone, statusLabel) = switch (sub.status) {
      'graded' => (StatusTone.success, 'Graded'),
      'submitted' => (StatusTone.info, 'Submitted'),
      'late' => (StatusTone.warning, 'Late'),
      _ => (StatusTone.neutral, 'Pending'),
    };

    return AppCard.surface(
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
                    style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(sub.studentName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              StatusPill(label: statusLabel, tone: statusTone),
            ],
          ),
          if (sub.content != null) ...[
            const SizedBox(height: 8),
            AppCard.filled(
              color: cs.surfaceContainerHighest,
              padding: const EdgeInsets.all(10),
              child: Text(sub.content!,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
          if (sub.grade != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star_rounded,
                    color: const Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 4),
                Text('${sub.grade!.toStringAsFixed(0)}/20',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (sub.feedback != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(sub.feedback!,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
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
              child: AppButton.primary(
                label: 'Grade',
                icon: Icons.grading_rounded,
                size: AppButtonSize.sm,
                onPressed: () => _showGradeSheet(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showGradeSheet(BuildContext context) {
    final cubit = context.read<TeacherHomeworkCubit>();
    showAppBottomSheet<void>(
      context: context,
      title: 'Grade — ${sub.studentName}',
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: _GradeSheetContent(sub: sub, hwId: hwId),
      ),
    );
  }
}

// ── Grade sheet content ───────────────────────────────────────────────────────

class _GradeSheetContent extends StatefulWidget {
  final HomeworkSubmissionModel sub;
  final int hwId;
  const _GradeSheetContent({required this.sub, required this.hwId});

  @override
  State<_GradeSheetContent> createState() => _GradeSheetContentState();
}

class _GradeSheetContentState extends State<_GradeSheetContent> {
  final _gradeCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();

  @override
  void dispose() {
    _gradeCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _gradeCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Grade (out of 20)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feedbackCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Feedback (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              label: 'Save Grade',
              onPressed: () {
                final g = double.tryParse(_gradeCtrl.text.trim());
                if (g != null && g >= 0 && g <= 20) {
                  context.read<TeacherHomeworkCubit>().gradeSubmission(
                        hwId: widget.hwId,
                        submissionId: widget.sub.id,
                        grade: g,
                        feedback: _feedbackCtrl.text.trim().isNotEmpty
                            ? _feedbackCtrl.text.trim()
                            : null,
                      );
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
