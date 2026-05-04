import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/teacher/data/models/teacher_extra_models.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_availability_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _days = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class TeacherAvailabilityScreen extends StatefulWidget {
  const TeacherAvailabilityScreen({super.key});

  @override
  State<TeacherAvailabilityScreen> createState() =>
      _TeacherAvailabilityScreenState();
}

class _TeacherAvailabilityScreenState
    extends State<TeacherAvailabilityScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TeacherAvailabilityCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEdit(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Slot'),
      ),
      body: BlocBuilder<TeacherAvailabilityCubit, TeacherAvailabilityState>(
        builder: (context, state) {
          if (state is TeacherAvailabilityLoading ||
              state is TeacherAvailabilityInitial) {
            return const CardListSkeleton();
          }
          if (state is TeacherAvailabilityError) {
            return ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<TeacherAvailabilityCubit>().load(),
            );
          }
          if (state is! TeacherAvailabilityLoaded) {
            return const SizedBox.shrink();
          }
          if (state.slots.isEmpty) {
            return const EmptyState(
              icon: Icons.schedule_rounded,
              title: 'No availability slots',
              subtitle:
                  'Tap "Add Slot" to define your weekly availability.',
            );
          }
          // Group by day
          final grouped = <String, List<TeacherAvailabilityModel>>{
            for (final d in _days) d: []
          };
          for (final s in state.slots) {
            grouped.putIfAbsent(s.dayOfWeek, () => []).add(s);
          }
          for (final list in grouped.values) {
            list.sort((a, b) => a.startTime.compareTo(b.startTime));
          }
          return RefreshIndicator(
            onRefresh: () =>
                context.read<TeacherAvailabilityCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final d in _days)
                  if ((grouped[d] ?? []).isNotEmpty) ...[
                    _DayHeader(day: d),
                    const SizedBox(height: 6),
                    for (final slot in grouped[d]!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SlotTile(
                            slot: slot,
                            onTap: () => _showEdit(context, slot)),
                      ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEdit(BuildContext context, TeacherAvailabilityModel? slot) {
    final cubit = context.read<TeacherAvailabilityCubit>();
    showAppBottomSheet<void>(
      context: context,
      title: slot == null ? 'New Slot' : 'Edit Slot',
      subtitle: slot == null
          ? 'Define your availability for a specific day.'
          : '${slot.dayOfWeek} · ${slot.startTime} → ${slot.endTime}',
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: _SlotSheet(slot: slot),
      ),
    );
  }
}

// ── Day header ────────────────────────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  final String day;
  const _DayHeader({required this.day});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(day,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
      );
}

// ── Slot tile ─────────────────────────────────────────────────────────────────

class _SlotTile extends StatelessWidget {
  final TeacherAvailabilityModel slot;
  final VoidCallback onTap;
  const _SlotTile({required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (slot.type) {
      'available' => const Color(0xFF10B981),
      'preferred' => cs.primary,
      'unavailable' => const Color(0xFFE11D48),
      _ => cs.onSurfaceVariant,
    };

    return AppCard.surface(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        // Accent bar
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
              color: color, borderRadius: Radii.xsRadius),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${slot.startTime} → ${slot.endTime}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                slot.type.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
            ],
          ),
        ),
        Icon(Icons.edit_rounded, size: 16, color: cs.onSurfaceVariant),
      ]),
    );
  }
}

// ── Slot sheet ────────────────────────────────────────────────────────────────

class _SlotSheet extends StatefulWidget {
  final TeacherAvailabilityModel? slot;
  const _SlotSheet({required this.slot});

  @override
  State<_SlotSheet> createState() => _SlotSheetState();
}

class _SlotSheetState extends State<_SlotSheet> {
  late String _day;
  late String _type;
  TimeOfDay? _start;
  TimeOfDay? _end;

  @override
  void initState() {
    super.initState();
    _day = widget.slot?.dayOfWeek ?? 'Monday';
    _type = widget.slot?.type ?? 'available';
    if (widget.slot != null) {
      _start = _parse(widget.slot!.startTime);
      _end = _parse(widget.slot!.endTime);
    }
  }

  TimeOfDay? _parse(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmt(TimeOfDay? t) => t == null
      ? '—'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.slot != null;
    return BlocBuilder<TeacherAvailabilityCubit, TeacherAvailabilityState>(
      builder: (context, state) {
        final working =
            state is TeacherAvailabilityLoaded && state.working;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _day,
                decoration: const InputDecoration(
                  labelText: 'Day of week',
                  prefixIcon: Icon(Icons.calendar_view_week_rounded),
                ),
                items: [
                  for (final d in _days)
                    DropdownMenuItem(value: d, child: Text(d)),
                ],
                onChanged: (v) => setState(() => _day = v ?? _day),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(true),
                    borderRadius: Radii.mdRadius,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'Start',
                          prefixIcon:
                              Icon(Icons.access_time_rounded, size: 18)),
                      child: Text(_fmt(_start)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(false),
                    borderRadius: Radii.mdRadius,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'End',
                          prefixIcon:
                              Icon(Icons.access_time_filled_rounded, size: 18)),
                      child: Text(_fmt(_end)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'available', label: Text('Available')),
                  ButtonSegment(
                      value: 'preferred', label: Text('Preferred')),
                  ButtonSegment(
                      value: 'unavailable', label: Text('Unavailable')),
                ],
                selected: {_type},
                onSelectionChanged: (s) =>
                    setState(() => _type = s.first),
              ),
              const SizedBox(height: 20),
              Row(children: [
                if (isEdit) ...[
                  Expanded(
                    child: AppButton.danger(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      fullWidth: true,
                      onPressed: working ? null : () => _delete(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: AppButton.primary(
                    label: 'Save',
                    icon: Icons.save_rounded,
                    fullWidth: true,
                    size: AppButtonSize.lg,
                    loading: working,
                    onPressed: working ? null : () => _submit(context),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? _start : _end) ?? const TimeOfDay(hour: 9, minute: 0),
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
        const SnackBar(content: Text('Pick both start and end times.')),
      );
      return;
    }
    final cubit = context.read<TeacherAvailabilityCubit>();
    final start = _fmt(_start);
    final end = _fmt(_end);
    final ok = widget.slot == null
        ? await cubit.add(
            dayOfWeek: _day,
            startTime: start,
            endTime: end,
            type: _type,
          )
        : await cubit.update(
            widget.slot!.id,
            dayOfWeek: _day,
            startTime: start,
            endTime: end,
            type: _type,
          );
    if (!context.mounted) return;
    if (ok) Navigator.pop(context);
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<TeacherAvailabilityCubit>();
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete slot?',
      message: 'This will permanently remove this availability slot.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      final removed = await cubit.remove(widget.slot!.id);
      if (removed && context.mounted) Navigator.pop(context);
    }
  }
}
