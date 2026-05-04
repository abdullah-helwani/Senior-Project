import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/teacher/data/models/teacher_extra_models.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_vacation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TeacherVacationScreen extends StatefulWidget {
  const TeacherVacationScreen({super.key});

  @override
  State<TeacherVacationScreen> createState() => _TeacherVacationScreenState();
}

class _TeacherVacationScreenState extends State<TeacherVacationScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    context.read<TeacherVacationCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacation Requests',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Request'),
      ),
      body: Column(
        children: [
          // ── Status filter ───────────────────────────────────────────────
          _StatusFilterBar(
            current: _statusFilter,
            onChanged: (v) {
              setState(() => _statusFilter = v);
              context.read<TeacherVacationCubit>().load(status: v);
            },
          ),
          const Divider(height: 1),
          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<TeacherVacationCubit, TeacherVacationState>(
              builder: (context, state) {
                if (state is TeacherVacationLoading ||
                    state is TeacherVacationInitial) {
                  return const CardListSkeleton();
                }
                if (state is TeacherVacationError) {
                  return ErrorView(
                    message: state.message,
                    onRetry: () => context
                        .read<TeacherVacationCubit>()
                        .load(status: _statusFilter),
                  );
                }
                if (state is! TeacherVacationLoaded) {
                  return const SizedBox.shrink();
                }
                if (state.requests.isEmpty) {
                  return const EmptyState(
                    icon: Icons.beach_access_rounded,
                    title: 'No requests',
                    subtitle: 'Tap "New Request" to submit one.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => context
                      .read<TeacherVacationCubit>()
                      .load(status: _statusFilter),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _RequestCard(request: state.requests[i]),
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
    final cubit = context.read<TeacherVacationCubit>();
    showAppBottomSheet<void>(
      context: context,
      title: 'New Vacation Request',
      subtitle: 'Select your leave dates below.',
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: const _CreateVacationSheet(),
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _StatusFilterBar extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;
  const _StatusFilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = <(String?, String)>[
      (null, 'All'),
      ('pending', 'Pending'),
      ('approved', 'Approved'),
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

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final VacationRequestModel request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final days = _daysBetween(request.startDate, request.endDate);

    return AppCard.surface(
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
              child: Icon(Icons.event_rounded,
                  size: 16, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_fmt(request.startDate)} → ${_fmt(request.endDate)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            StatusPill(
              label: _statusLabel(request.status),
              tone: _tone(request.status),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            '$days day${days == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          if (request.canCancel) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton.danger(
                label: 'Cancel Request',
                icon: Icons.cancel_outlined,
                size: AppButtonSize.sm,
                onPressed: () => _confirmCancel(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context) async {
    final cubit = context.read<TeacherVacationCubit>();
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Cancel Request?',
      message: 'This will withdraw your pending vacation request.',
      confirmLabel: 'Cancel Request',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      cubit.cancel(request.id);
    }
  }

  StatusTone _tone(String status) => switch (status) {
        'approved' => StatusTone.success,
        'rejected' => StatusTone.error,
        _ => StatusTone.warning,
      };

  String _statusLabel(String s) =>
      s[0].toUpperCase() + s.substring(1);

  String _fmt(String iso) {
    try {
      return DateFormat('d MMM y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  int _daysBetween(String start, String end) {
    try {
      return DateTime.parse(end).difference(DateTime.parse(start)).inDays + 1;
    } catch (_) {
      return 0;
    }
  }
}

// ── Create sheet ──────────────────────────────────────────────────────────────

class _CreateVacationSheet extends StatefulWidget {
  const _CreateVacationSheet();

  @override
  State<_CreateVacationSheet> createState() => _CreateVacationSheetState();
}

class _CreateVacationSheetState extends State<_CreateVacationSheet> {
  DateTime? _start;
  DateTime? _end;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeacherVacationCubit, TeacherVacationState>(
      builder: (context, state) {
        final submitting =
            state is TeacherVacationLoaded && state.submitting;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DateField(
                label: 'Start date *',
                value: _start,
                onTap: () => _pickDate(true),
              ),
              const SizedBox(height: 12),
              _DateField(
                label: 'End date *',
                value: _end,
                onTap: () => _pickDate(false),
              ),
              const SizedBox(height: 20),
              AppButton.primary(
                label: 'Submit Request',
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

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _start : _end) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _submit(BuildContext context) async {
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick both start and end dates.')),
      );
      return;
    }
    if (_end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('End date must be on or after start.')),
      );
      return;
    }
    final ok = await context.read<TeacherVacationCubit>().submit(
          startDate: DateFormat('yyyy-MM-dd').format(_start!),
          endDate: DateFormat('yyyy-MM-dd').format(_end!),
        );
    if (!context.mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vacation request submitted.')),
      );
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateField(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.mdRadius,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(
          value == null
              ? 'Select…'
              : DateFormat('d MMM y').format(value!),
        ),
      ),
    );
  }
}
