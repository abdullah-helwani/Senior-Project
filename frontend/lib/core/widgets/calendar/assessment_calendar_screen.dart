import 'package:first_try/core/models/assessment_event_model.dart';
import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Role-agnostic assessment calendar screen.
///
/// The four roles (admin/teacher/student/parent) hit different endpoints but
/// all return the same payload shape. So this screen just takes a
/// [fetcher] callback and renders consistently.
///
/// Example usage in a More-grid tile:
///
/// ```dart
/// AssessmentCalendarScreen(
///   title: 'Upcoming Assessments',
///   fetcher: () => repo.getAssessmentCalendar(),
/// );
/// ```
class AssessmentCalendarScreen extends StatefulWidget {
  final String title;
  final Future<List<AssessmentEventModel>> Function() fetcher;

  const AssessmentCalendarScreen({
    super.key,
    required this.fetcher,
    this.title = 'Assessment Calendar',
  });

  @override
  State<AssessmentCalendarScreen> createState() =>
      _AssessmentCalendarScreenState();
}

class _AssessmentCalendarScreenState extends State<AssessmentCalendarScreen> {
  late Future<List<AssessmentEventModel>> _future;
  String? _typeFilter;
  bool _onlyUpcoming = true;

  @override
  void initState() {
    super.initState();
    _future = widget.fetcher();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.fetcher();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<List<AssessmentEventModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorView(
              message: snap.error.toString(),
              onRetry: _refresh,
            );
          }
          final all = snap.data ?? const <AssessmentEventModel>[];
          final filtered = _applyFilters(all);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                _Filters(
                  type: _typeFilter,
                  onTypeChanged: (t) => setState(() => _typeFilter = t),
                  onlyUpcoming: _onlyUpcoming,
                  onUpcomingChanged: (v) =>
                      setState(() => _onlyUpcoming = v),
                  knownTypes: _typesIn(all),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filtered.isEmpty
                      ? ListView(
                          // ListView so RefreshIndicator works on empty state.
                          children: const [
                            SizedBox(height: 80),
                            EmptyState(
                              icon: Icons.event_busy_rounded,
                              title: 'Nothing scheduled',
                              subtitle: 'Pull to refresh.',
                            ),
                          ],
                        )
                      : _GroupedList(events: filtered),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<AssessmentEventModel> _applyFilters(List<AssessmentEventModel> all) {
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day);
    var out = all;
    if (_typeFilter != null) {
      out = out.where((e) => e.type == _typeFilter).toList();
    }
    if (_onlyUpcoming) {
      out = out.where((e) {
        final d = DateTime.tryParse(e.date);
        return d != null && !d.isBefore(cutoff);
      }).toList();
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  List<String> _typesIn(List<AssessmentEventModel> all) {
    final s = <String>{};
    for (final e in all) {
      s.add(e.type);
    }
    return s.toList()..sort();
  }
}

class _Filters extends StatelessWidget {
  final String? type;
  final ValueChanged<String?> onTypeChanged;
  final bool onlyUpcoming;
  final ValueChanged<bool> onUpcomingChanged;
  final List<String> knownTypes;

  const _Filters({
    required this.type,
    required this.onTypeChanged,
    required this.onlyUpcoming,
    required this.onUpcomingChanged,
    required this.knownTypes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Upcoming only',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Switch(
                value: onlyUpcoming,
                onChanged: onUpcomingChanged,
              ),
            ],
          ),
          if (knownTypes.isNotEmpty) ...[
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: type == null,
                  onSelected: (_) => onTypeChanged(null),
                ),
                const SizedBox(width: 6),
                for (final t in knownTypes) ...[
                  ChoiceChip(
                    label: Text(_label(t)),
                    selected: type == t,
                    onSelected: (_) => onTypeChanged(t),
                  ),
                  const SizedBox(width: 6),
                ],
              ]),
            ),
          ],
        ],
      ),
    );
  }

  String _label(String t) => t.isEmpty
      ? t
      : t[0].toUpperCase() + t.substring(1).replaceAll('_', ' ');
}

class _GroupedList extends StatelessWidget {
  final List<AssessmentEventModel> events;
  const _GroupedList({required this.events});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<AssessmentEventModel>>{};
    for (final e in events) {
      final d = DateTime.tryParse(e.date);
      final key =
          d != null ? DateFormat('MMMM y').format(d) : 'Unscheduled';
      groups.putIfAbsent(key, () => []).add(e);
    }

    final entries = groups.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: entries.length,
      itemBuilder: (context, gi) {
        final g = entries[gi];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(g.key,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            for (final e in g.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EventCard(event: e),
              ),
          ],
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final AssessmentEventModel event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _typeColor(event.type);
    final d = DateTime.tryParse(event.date);
    final dayLabel = d != null ? DateFormat('d').format(d) : '–';
    final dowLabel = d != null ? DateFormat('EEE').format(d) : '';
    final dueLabel = d != null
        ? DateFormat('d MMM y').format(d)
        : event.date;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Date block
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(dayLabel,
                    style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                Text(dowLabel.toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        event.type.toUpperCase(),
                        style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    if (event.subject != null)
                      _MetaPill(
                          icon: Icons.menu_book_rounded, text: event.subject!),
                    if (event.section != null)
                      _MetaPill(
                          icon: Icons.group_rounded, text: event.section!),
                    if (event.maxScore != null)
                      _MetaPill(
                          icon: Icons.grade_rounded,
                          text: '/ ${event.maxScore}'),
                    _MetaPill(
                        icon: Icons.calendar_today_rounded, text: dueLabel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String t) => switch (t) {
        'exam' => Colors.red.shade600,
        'quiz' => Colors.orange.shade700,
        'homework' => Colors.blue.shade600,
        'project' => Colors.purple.shade600,
        _ => Colors.teal.shade600,
      };
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: cs.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }
}
