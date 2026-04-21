import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/features/parent/data/models/parent_models.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: BlocBuilder<ParentCubit, ParentState>(
          builder: (context, state) {
            if (state is ParentLoading || state is ParentInitial) return const LoadingView();
            if (state is! ParentLoaded) return const SizedBox.shrink();

            return RefreshIndicator(
              onRefresh: () => context.read<ParentCubit>().load(),
              child: CustomScrollView(
                slivers: [
                  // ── Header ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${_greeting()}, ${state.profile.name.split(' ').first}',
                                  style: Theme.of(context).textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            radius: 22,
                            child: Icon(Icons.person_rounded, color: cs.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Child selector ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _ChildSelector(
                      children: state.profile.children,
                      selectedIndex: state.selectedChildIndex,
                      onSelect: (i) => context.read<ParentCubit>().selectChild(i),
                    ),
                  ),

                  // ── Stats cards ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _StatCard(
                            icon: Icons.bar_chart_rounded,
                            label: 'Avg Score',
                            value: '${state.selectedChild.averageScore.toStringAsFixed(0)}%',
                            color: cs.primary,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            icon: Icons.event_available_rounded,
                            label: 'Attendance',
                            value: '${state.selectedChild.attendancePercent.toStringAsFixed(0)}%',
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            icon: Icons.assignment_rounded,
                            label: 'Pending HW',
                            value: '${state.selectedChild.pendingHomeworkCount}',
                            color: Colors.orange.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Today's schedule ───────────────────────────────────
                  SliverToBoxAdapter(
                    child: _SectionTitle(title: "Today's Schedule"),
                  ),
                  SliverToBoxAdapter(
                    child: Builder(builder: (context) {
                      final slots = state.slotsForDay;
                      if (slots.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('No classes today.',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                        );
                      }
                      return SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: slots.length,
                          separatorBuilder: (context, _) => const SizedBox(width: 10),
                          itemBuilder: (context, i) => _ClassCard(slot: slots[i]),
                        ),
                      );
                    }),
                  ),

                  // ── Pending homework ───────────────────────────────────
                  SliverToBoxAdapter(child: _SectionTitle(title: 'Pending Homework')),
                  Builder(builder: (context) {
                    final pending = (state.homework[state.selectedChildId] ?? [])
                        .where((h) => h.status == 'pending' || h.status == 'late')
                        .take(3)
                        .toList();
                    if (pending.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('No pending homework.',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _HomeworkTile(hw: pending[i]),
                        childCount: pending.length,
                      ),
                    );
                  }),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _ChildSelector extends StatelessWidget {
  final List<ChildSummaryModel> children;
  final int selectedIndex;
  final void Function(int) onSelect;
  const _ChildSelector({required this.children, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(children.length, (i) {
          final child = children[i];
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                margin: EdgeInsets.only(right: i < children.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                decoration: BoxDecoration(
                  color: selected ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: selected
                          ? cs.onPrimary.withValues(alpha: 0.2)
                          : cs.primaryContainer,
                      child: Text(child.name[0],
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: selected ? cs.onPrimary : cs.onPrimaryContainer)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(child.name.split(' ').first,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: selected ? cs.onPrimary : cs.onSurface),
                              overflow: TextOverflow.ellipsis),
                          Text(child.className,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: selected
                                      ? cs.onPrimary.withValues(alpha: 0.75)
                                      : cs.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text(title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
          ]),
        ),
      );
}

class _ClassCard extends StatelessWidget {
  final ParentScheduleSlotModel slot;
  const _ClassCard({required this.slot});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(slot.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(slot.teacherName, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis),
        const Spacer(),
        Row(children: [
          Icon(Icons.access_time_rounded, size: 11, color: cs.primary),
          const SizedBox(width: 3),
          Text(slot.startTime, style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _HomeworkTile extends StatelessWidget {
  final ParentHomeworkModel hw;
  const _HomeworkTile({required this.hw});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLate = hw.status == 'late';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isLate ? Colors.red.shade200 : cs.outlineVariant),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.assignment_rounded, color: cs.onPrimaryContainer, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(hw.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
          Text(hw.subject, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Due', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          Text(_fmtDate(hw.dueDate),
              style: TextStyle(fontSize: 12,
                  color: isLate ? Colors.red.shade600 : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  String _fmtDate(String iso) {
    try { return DateFormat('d MMM').format(DateTime.parse(iso)); }
    catch (_) { return iso; }
  }
}
