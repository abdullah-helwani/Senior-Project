import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/teacher/data/models/teacher_extra_models.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_behavior_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TeacherBehaviorScreen extends StatefulWidget {
  const TeacherBehaviorScreen({super.key});

  @override
  State<TeacherBehaviorScreen> createState() => _TeacherBehaviorScreenState();
}

class _TeacherBehaviorScreenState extends State<TeacherBehaviorScreen> {
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    context.read<TeacherBehaviorCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavior Logs',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Entry'),
      ),
      body: Column(
        children: [
          // ── Type filter ─────────────────────────────────────────────────
          _TypeFilterBar(
            current: _typeFilter,
            onChanged: (v) {
              setState(() => _typeFilter = v);
              context.read<TeacherBehaviorCubit>().load(type: v);
            },
          ),
          const Divider(height: 1),
          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<TeacherBehaviorCubit, TeacherBehaviorState>(
              builder: (context, state) {
                if (state is TeacherBehaviorLoading ||
                    state is TeacherBehaviorInitial) {
                  return const CardListSkeleton();
                }
                if (state is TeacherBehaviorError) {
                  return ErrorView(
                    message: state.message,
                    onRetry: () => context
                        .read<TeacherBehaviorCubit>()
                        .load(type: _typeFilter),
                  );
                }
                if (state is! TeacherBehaviorLoaded) {
                  return const SizedBox.shrink();
                }
                if (state.logs.isEmpty) {
                  return const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No behavior logs',
                    subtitle: 'Tap "Log Entry" to record one.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => context
                      .read<TeacherBehaviorCubit>()
                      .load(type: _typeFilter),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _LogCard(log: state.logs[i]),
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
    final cubit = context.read<TeacherBehaviorCubit>();
    showAppBottomSheet<void>(
      context: context,
      title: 'Log Behavior',
      subtitle: 'Record a student behavior observation.',
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: const _CreateBehaviorSheet(),
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _TypeFilterBar extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;
  const _TypeFilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = <(String?, String)>[
      (null, 'All'),
      ('positive', 'Positive'),
      ('negative', 'Negative'),
      ('neutral', 'Neutral'),
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

// ── Log card ──────────────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  final BehaviorLogModel log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (log.type) {
      'positive' => const Color(0xFF10B981),
      'negative' => const Color(0xFFE11D48),
      _ => cs.onSurfaceVariant,
    };
    final icon = switch (log.type) {
      'positive' => Icons.thumb_up_rounded,
      'negative' => Icons.warning_amber_rounded,
      _ => Icons.info_outline_rounded,
    };

    return AppCard.surface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon + title + date
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: Radii.smRadius,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                log.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(
              label: _typeLabel(log.type),
              tone: _tone(log.type),
              dense: true,
            ),
          ]),
          const SizedBox(height: 8),
          // Student / section meta
          Row(children: [
            Icon(Icons.person_rounded, size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              log.studentName ?? 'Student #${log.studentId}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            if (log.sectionName != null) ...[
              const SizedBox(width: 10),
              Icon(Icons.class_rounded,
                  size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                log.sectionName!,
                style:
                    TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
            const Spacer(),
            Text(
              _fmt(log.date),
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ]),
          if (log.description != null) ...[
            const SizedBox(height: 8),
            Text(log.description!, style: const TextStyle(fontSize: 13)),
          ],
          if (log.notifyParent) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.notifications_active_rounded,
                  size: 12, color: cs.primary),
              const SizedBox(width: 4),
              Text(
                'Parent notified',
                style: TextStyle(
                    fontSize: 11,
                    color: cs.primary,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  StatusTone _tone(String type) => switch (type) {
        'positive' => StatusTone.success,
        'negative' => StatusTone.error,
        _ => StatusTone.neutral,
      };

  String _typeLabel(String type) =>
      type[0].toUpperCase() + type.substring(1);

  String _fmt(String iso) {
    try {
      return DateFormat('d MMM').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Create sheet ──────────────────────────────────────────────────────────────

class _CreateBehaviorSheet extends StatefulWidget {
  const _CreateBehaviorSheet();

  @override
  State<_CreateBehaviorSheet> createState() => _CreateBehaviorSheetState();
}

class _CreateBehaviorSheetState extends State<_CreateBehaviorSheet> {
  final _studentCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'positive';
  DateTime _date = DateTime.now();
  bool _notify = false;

  @override
  void dispose() {
    _studentCtrl.dispose();
    _sectionCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeacherBehaviorCubit, TeacherBehaviorState>(
      builder: (context, state) {
        final submitting =
            state is TeacherBehaviorLoaded && state.submitting;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student + Section IDs
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _studentCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Student ID *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _sectionCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Section ID *',
                      prefixIcon: Icon(Icons.class_outlined),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              // Type selector
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'positive', label: Text('Positive')),
                  ButtonSegment(value: 'negative', label: Text('Negative')),
                  ButtonSegment(value: 'neutral', label: Text('Neutral')),
                ],
                selected: {_type},
                onSelectionChanged: (s) =>
                    setState(() => _type = s.first),
              ),
              const SizedBox(height: 14),
              // Title
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 14),
              // Description
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Date picker
              InkWell(
                onTap: _pickDate,
                borderRadius: Radii.mdRadius,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(DateFormat('d MMM y').format(_date)),
                ),
              ),
              const SizedBox(height: 4),
              // Notify parent toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notify parent'),
                subtitle: const Text('Send a notification to the parent'),
                value: _notify,
                onChanged: (v) => setState(() => _notify = v),
              ),
              const SizedBox(height: 16),
              // Submit
              AppButton.primary(
                label: 'Save Log',
                icon: Icons.save_rounded,
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit(BuildContext context) async {
    final studentId = int.tryParse(_studentCtrl.text.trim());
    final sectionId = int.tryParse(_sectionCtrl.text.trim());
    final title = _titleCtrl.text.trim();
    if (studentId == null || sectionId == null || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Student ID, section ID, and title are required.')),
      );
      return;
    }
    final ok = await context.read<TeacherBehaviorCubit>().create(
          studentId: studentId,
          sectionId: sectionId,
          type: _type,
          title: title,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          date: DateFormat('yyyy-MM-dd').format(_date),
          notifyParent: _notify,
        );
    if (!context.mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Behavior log saved.')),
      );
    }
  }
}
