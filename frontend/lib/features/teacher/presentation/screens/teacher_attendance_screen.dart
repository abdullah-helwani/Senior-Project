import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_attendance_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_attendance_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TeacherAttendanceScreen extends StatelessWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<TeacherAttendanceCubit, TeacherAttendanceState>(
        builder: (context, state) {
          if (state is TeacherAttendanceLoading ||
              state is TeacherAttendanceInitial) {
            return const CardListSkeleton();
          }
          if (state is TeacherAttendanceError) {
            return ErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<TeacherAttendanceCubit>().load());
          }
          if (state is! TeacherAttendanceLoaded) return const SizedBox.shrink();

          final pending =
              state.sessions.where((s) => s.status == 'pending').toList();
          final done =
              state.sessions.where((s) => s.status == 'submitted').toList();

          return RefreshIndicator(
            onRefresh: () => context.read<TeacherAttendanceCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pending.isNotEmpty) ...[
                  _SectionHeader(
                      title: 'Pending',
                      count: pending.length,
                      color: const Color(0xFFF59E0B)),
                  const SizedBox(height: 8),
                  ...pending.map((s) => _SessionCard(session: s, isPending: true)),
                  const SizedBox(height: 16),
                ],
                if (done.isNotEmpty) ...[
                  _SectionHeader(
                      title: 'Submitted',
                      count: done.length,
                      color: const Color(0xFF10B981)),
                  const SizedBox(height: 8),
                  ...done.map((s) => _SessionCard(session: s, isPending: false)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionHeader(
      {required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: color)),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: Radii.pillRadius,
            ),
            child: Text('$count',
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      );
}

// ── Session card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final TeacherAttendanceSessionModel session;
  final bool isPending;
  const _SessionCard({required this.session, required this.isPending});

  static const _pendingColor = Color(0xFFF59E0B);
  static const _doneColor = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isPending ? _pendingColor : _doneColor;
    final presentCount =
        session.entries.where((e) => e.status == 'present').length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard.surface(
        onTap: () => _openSession(context, session),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: Radii.smRadius,
              ),
              child: Icon(
                isPending
                    ? Icons.pending_actions_rounded
                    : Icons.check_circle_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.className,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(session.subject,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmtDate(session.date),
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text('$presentCount/${session.entries.length} present',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openSession(
      BuildContext context, TeacherAttendanceSessionModel session) {
    final cubit = context.read<TeacherAttendanceCubit>();
    showAppBottomSheet<void>(
      context: context,
      title: session.className,
      subtitle: session.subject,
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: _AttendanceContent(session: session, isPending: isPending),
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

// ── Attendance sheet content ───────────────────────────────────────────────────

class _AttendanceContent extends StatelessWidget {
  final TeacherAttendanceSessionModel session;
  final bool isPending;
  const _AttendanceContent(
      {required this.session, required this.isPending});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeacherAttendanceCubit, TeacherAttendanceState>(
      builder: (context, state) {
        final liveSession = state is TeacherAttendanceLoaded
            ? state.sessions.firstWhere((s) => s.id == session.id,
                orElse: () => session)
            : session;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...liveSession.entries.map((e) => _EntryRow(
                    entry: e,
                    sessionId: liveSession.id,
                    editable: isPending,
                  )),
              if (isPending) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    label: 'Submit Attendance',
                    icon: Icons.check_rounded,
                    onPressed: () {
                      context
                          .read<TeacherAttendanceCubit>()
                          .submitSession(session.id);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Entry row ─────────────────────────────────────────────────────────────────

class _EntryRow extends StatelessWidget {
  final AttendanceEntryModel entry;
  final int sessionId;
  final bool editable;
  const _EntryRow(
      {required this.entry, required this.sessionId, required this.editable});

  static const _statuses = ['present', 'absent', 'late', 'excused'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (statusColor, statusIcon) = switch (entry.status) {
      'absent' => (const Color(0xFFE11D48), Icons.cancel_rounded),
      'late' => (const Color(0xFFF59E0B), Icons.watch_later_rounded),
      'excused' => (const Color(0xFF3B82F6), Icons.info_rounded),
      _ => (const Color(0xFF10B981), Icons.check_circle_rounded),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer,
            child: Text(entry.studentName[0],
                style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(entry.studentName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (editable)
            DropdownButton<String>(
              value: entry.status,
              underline: const SizedBox.shrink(),
              isDense: true,
              items: _statuses
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                            s[0].toUpperCase() + s.substring(1),
                            style: TextStyle(
                                fontSize: 13,
                                color: _colorForStatus(s))),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  context.read<TeacherAttendanceCubit>().updateEntry(
                      sessionId, entry.studentId, val);
                }
              },
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 4),
                Text(
                  entry.status[0].toUpperCase() + entry.status.substring(1),
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _colorForStatus(String s) => switch (s) {
        'absent' => const Color(0xFFE11D48),
        'late' => const Color(0xFFF59E0B),
        'excused' => const Color(0xFF3B82F6),
        _ => const Color(0xFF10B981),
      };
}
