import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/parent/data/models/parent_extra_models.dart';
import 'package:first_try/features/parent/presentation/cubit/complaints_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ParentComplaintsScreen extends StatefulWidget {
  const ParentComplaintsScreen({super.key});

  @override
  State<ParentComplaintsScreen> createState() => _ParentComplaintsScreenState();
}

class _ParentComplaintsScreenState extends State<ParentComplaintsScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    context.read<ComplaintsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New'),
      ),
      body: Column(
        children: [
          // ── Status filter ───────────────────────────────────────────────
          _StatusFilter(
            current: _statusFilter,
            onChanged: (v) {
              setState(() => _statusFilter = v);
              context.read<ComplaintsCubit>().load(status: v);
            },
          ),
          const Divider(height: 1),
          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<ComplaintsCubit, ComplaintsState>(
              builder: (context, state) {
                if (state is ComplaintsLoading ||
                    state is ComplaintsInitial) {
                  return const CardListSkeleton(showFilter: true);
                }
                if (state is ComplaintsError) {
                  return ErrorView(
                    message: state.message,
                    onRetry: () => context
                        .read<ComplaintsCubit>()
                        .load(status: _statusFilter),
                  );
                }
                if (state is! ComplaintsLoaded) {
                  return const SizedBox.shrink();
                }
                if (state.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.feedback_outlined,
                    title: 'No complaints',
                    subtitle: 'Tap "New" to submit one.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => context
                      .read<ComplaintsCubit>()
                      .load(status: _statusFilter),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _ComplaintCard(complaint: state.items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreate(BuildContext context) {
    final complaintsCubit = context.read<ComplaintsCubit>();
    final parentCubit = context.read<ParentCubit>();
    showAppBottomSheet<void>(
      context: context,
      title: 'New Complaint',
      subtitle: 'Submit a complaint or concern.',
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: complaintsCubit),
          BlocProvider.value(value: parentCubit),
        ],
        child: const _CreateComplaintSheet(),
      ),
    );
  }
}

// ── Status filter ─────────────────────────────────────────────────────────────

class _StatusFilter extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;
  const _StatusFilter({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = <(String?, String)>[
      (null, 'All'),
      ('pending', 'Pending'),
      ('in_review', 'In Review'),
      ('resolved', 'Resolved'),
      ('rejected', 'Rejected'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          for (final e in entries) ...[
            FilterPill(
              label: e.$2,
              selected: current == e.$1,
              onSelected: (_) => onChanged(e.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ── Complaint card ────────────────────────────────────────────────────────────

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppCard.surface(
      onTap: () => _showDetail(context, complaint),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: Radii.smRadius,
              ),
              child: Icon(Icons.feedback_outlined,
                  size: 16, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                complaint.subject,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(
              label: _statusLabel(complaint.status),
              tone: _statusTone(complaint.status),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            complaint.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(children: [
            if (complaint.studentName != null) ...[
              Icon(Icons.person_outline_rounded,
                  size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(complaint.studentName!,
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(width: 10),
            ],
            Icon(Icons.access_time_rounded,
                size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(_fmt(complaint.createdAt),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: cs.onSurfaceVariant),
          ]),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, ComplaintModel c) {
    showAppBottomSheet<void>(
      context: context,
      title: c.subject,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusPill(
              label: _statusLabel(c.status),
              tone: _statusTone(c.status),
            ),
            const SizedBox(height: 16),
            Text(c.body,
                style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 16),
            Text(
              'Submitted ${_fmt(c.createdAt)}',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String s) => switch (s) {
        'in_review' => 'In Review',
        _ => s[0].toUpperCase() + s.substring(1),
      };

  StatusTone _statusTone(String s) => switch (s) {
        'resolved' => StatusTone.success,
        'rejected' => StatusTone.error,
        'in_review' => StatusTone.info,
        _ => StatusTone.warning,
      };

  String _fmt(String iso) {
    try {
      return DateFormat('d MMM y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Create sheet ──────────────────────────────────────────────────────────────

class _CreateComplaintSheet extends StatefulWidget {
  const _CreateComplaintSheet();

  @override
  State<_CreateComplaintSheet> createState() => _CreateComplaintSheetState();
}

class _CreateComplaintSheetState extends State<_CreateComplaintSheet> {
  final _subjectCtl = TextEditingController();
  final _bodyCtl = TextEditingController();
  int? _studentId;

  @override
  void dispose() {
    _subjectCtl.dispose();
    _bodyCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ComplaintsCubit, ComplaintsState>(
      builder: (context, state) {
        final submitting = state is ComplaintsLoaded && state.submitting;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child selector (optional)
              BlocBuilder<ParentCubit, ParentState>(
                builder: (context, ps) {
                  if (ps is! ParentLoaded) return const SizedBox.shrink();
                  final children = ps.profile.children;
                  if (children.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: DropdownButtonFormField<int?>(
                      initialValue: _studentId,
                      decoration: const InputDecoration(
                        labelText: 'Child (optional)',
                        prefixIcon: Icon(Icons.child_care_rounded),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                            value: null, child: Text('— None —')),
                        for (final c in children)
                          DropdownMenuItem<int?>(
                              value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => setState(() => _studentId = v),
                    ),
                  );
                },
              ),
              TextField(
                controller: _subjectCtl,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  prefixIcon: Icon(Icons.subject_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _bodyCtl,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Details *',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppButton.primary(
                label: 'Submit',
                icon: Icons.send_rounded,
                fullWidth: true,
                size: AppButtonSize.lg,
                loading: submitting,
                onPressed: submitting ? null : () => _submit(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(BuildContext context) async {
    final subject = _subjectCtl.text.trim();
    final body = _bodyCtl.text.trim();
    if (subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject and details are required.')),
      );
      return;
    }
    final ok = await context.read<ComplaintsCubit>().submit(
          studentId: _studentId,
          subject: subject,
          body: body,
        );
    if (!context.mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted.')),
      );
    }
  }
}
