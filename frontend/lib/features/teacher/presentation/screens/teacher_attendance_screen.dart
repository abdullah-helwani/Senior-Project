import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
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
        title: const Text('Attendance', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<TeacherAttendanceCubit, TeacherAttendanceState>(
        builder: (context, state) {
          if (state is TeacherAttendanceLoading || state is TeacherAttendanceInitial) {
            return const LoadingView();
          }
          if (state is TeacherAttendanceError) {
            return ErrorView(
                message: state.message,
                onRetry: () => context.read<TeacherAttendanceCubit>().load());
          }
          if (state is! TeacherAttendanceLoaded) return const SizedBox.shrink();

          final pending = state.sessions.where((s) => s.status == 'pending').toList();
          final done = state.sessions.where((s) => s.status == 'submitted').toList();

          return RefreshIndicator(
            onRefresh: () => context.read<TeacherAttendanceCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pending.isNotEmpty) ...[
                  _SectionHeader(title: 'Pending', count: pending.length, color: Colors.orange.shade600),
                  const SizedBox(height: 8),
                  ...pending.map((s) => _SessionCard(session: s, isPending: true)),
                  const SizedBox(height: 16),
                ],
                if (done.isNotEmpty) ...[
                  _SectionHeader(title: 'Submitted', count: done.length, color: Colors.green.shade600),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionHeader({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      );
}

class _SessionCard extends StatelessWidget {
  final TeacherAttendanceSessionModel session;
  final bool isPending;
  const _SessionCard({required this.session, required this.isPending});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final presentCount = session.entries.where((e) => e.status == 'present').length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPending ? Colors.orange.shade200 : cs.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openSession(context, session),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPending ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                  color: isPending ? Colors.orange.shade600 : Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.className,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(session.subject,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtDate(session.date),
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text('$presentCount/${session.entries.length} present',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPending ? Colors.orange.shade600 : Colors.green.shade600,
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSession(BuildContext context, TeacherAttendanceSessionModel session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => BlocProvider.value(
        value: context.read<TeacherAttendanceCubit>(),
        child: _AttendanceSheet(session: session),
      ),
    );
  }

  String _fmtDate(String iso) {
    try { return DateFormat('d MMM y').format(DateTime.parse(iso)); }
    catch (_) { return iso; }
  }
}

// ── Attendance Sheet ──────────────────────────────────────────────────────────

class _AttendanceSheet extends StatelessWidget {
  final TeacherAttendanceSessionModel session;
  const _AttendanceSheet({required this.session});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPending = session.status == 'pending';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, ctrl) => BlocBuilder<TeacherAttendanceCubit, TeacherAttendanceState>(
        builder: (context, state) {
          // Always read live session from state
          final liveSession = state is TeacherAttendanceLoaded
              ? state.sessions.firstWhere((s) => s.id == session.id,
                  orElse: () => session)
              : session;

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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(liveSession.className,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                              Text(liveSession.subject, style: TextStyle(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        if (isPending)
                          FilledButton.icon(
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Submit'),
                            onPressed: () {
                              context.read<TeacherAttendanceCubit>().submitSession(session.id);
                              Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: liveSession.entries.length,
                  itemBuilder: (context, i) => _EntryRow(
                    entry: liveSession.entries[i],
                    sessionId: liveSession.id,
                    editable: isPending,
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

class _EntryRow extends StatelessWidget {
  final AttendanceEntryModel entry;
  final int sessionId;
  final bool editable;
  const _EntryRow({required this.entry, required this.sessionId, required this.editable});

  static const _statuses = ['present', 'absent', 'late', 'excused'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color statusColor;
    IconData statusIcon;
    switch (entry.status) {
      case 'absent':  statusColor = Colors.red.shade600;    statusIcon = Icons.cancel_rounded; break;
      case 'late':    statusColor = Colors.orange.shade600; statusIcon = Icons.watch_later_rounded; break;
      case 'excused': statusColor = Colors.blue.shade600;   statusIcon = Icons.info_rounded; break;
      default:        statusColor = Colors.green.shade600;  statusIcon = Icons.check_circle_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer,
            child: Text(entry.studentName[0],
                style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(entry.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (editable)
            DropdownButton<String>(
              value: entry.status,
              underline: const SizedBox.shrink(),
              isDense: true,
              items: _statuses.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s[0].toUpperCase() + s.substring(1),
                    style: TextStyle(fontSize: 13, color: _colorForStatus(s))),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  context.read<TeacherAttendanceCubit>()
                      .updateEntry(sessionId, entry.studentId, val);
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
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _colorForStatus(String s) {
    switch (s) {
      case 'absent':  return Colors.red.shade600;
      case 'late':    return Colors.orange.shade600;
      case 'excused': return Colors.blue.shade600;
      default:        return Colors.green.shade600;
    }
  }
}
