import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/calendar/assessment_calendar_screen.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/parent/data/models/parent_models.dart';
import 'package:first_try/features/parent/presentation/cubit/billing_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/complaints_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_state.dart';
import 'package:first_try/features/parent/presentation/screens/billing/parent_invoices_screen.dart';
import 'package:first_try/features/parent/presentation/screens/billing/parent_payments_screen.dart';
import 'package:first_try/features/parent/presentation/screens/parent_complaints_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// Parent role gradient: emerald → cyan
const _kHeroGradient = [Color(0xFF059669), Color(0xFF0891B2)];

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: BlocBuilder<ParentCubit, ParentState>(
        builder: (context, state) {
          // Show skeleton hero during initial load
          final loaded = state is ParentLoaded;

          return RefreshIndicator(
            onRefresh: () => context.read<ParentCubit>().load(),
            child: CustomScrollView(
              slivers: [
                // ── Gradient hero ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: GradientHero(
                    greeting: loaded
                        ? 'Good ${_greeting()}, ${state.profile.name.split(' ').first}'
                        : 'Good ${_greeting()}',
                    subtitle: DateFormat('EEEE, d MMMM').format(DateTime.now()),
                    colors: _kHeroGradient,
                    trailing: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: Radii.mdRadius,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.30),
                            width: 1),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),

                // ── Child selector ────────────────────────────────────────
                if (loaded)
                  SliverToBoxAdapter(
                    child: _ChildSelector(
                      children: state.profile.children,
                      selectedIndex: state.selectedChildIndex,
                      onSelect: (i) =>
                          context.read<ParentCubit>().selectChild(i),
                    ),
                  ),

                // ── Stat cards ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: SkeletonSwitcher(
                      isLoading: !loaded,
                      skeleton: Row(children: [
                        Expanded(child: Skeleton.card(height: 96)),
                        const SizedBox(width: 10),
                        Expanded(child: Skeleton.card(height: 96)),
                        const SizedBox(width: 10),
                        Expanded(child: Skeleton.card(height: 96)),
                      ]),
                      child: loaded
                          ? Row(children: [
                              _StatCard(
                                icon: Icons.bar_chart_rounded,
                                label: 'Avg\nScore',
                                value:
                                    '${state.selectedChild.averageScore.toStringAsFixed(0)}%',
                                color: const Color(0xFF059669),
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                icon: Icons.event_available_rounded,
                                label: 'Attendance',
                                value:
                                    '${state.selectedChild.attendancePercent.toStringAsFixed(0)}%',
                                color: const Color(0xFF0891B2),
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                icon: Icons.assignment_rounded,
                                label: 'Pending\nHW',
                                value:
                                    '${state.selectedChild.pendingHomeworkCount}',
                                color: const Color(0xFFF59E0B),
                              ),
                            ])
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),

                // ── Today's schedule ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: SectionHeader(title: "Today's Schedule"),
                ),
                SliverToBoxAdapter(
                  child: Builder(builder: (context) {
                    if (!loaded) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                            children: [ListTileSkeleton(), ListTileSkeleton()]),
                      );
                    }
                    final slots = state.slotsForDay;
                    if (slots.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Text(
                          'No classes scheduled today.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 118,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: slots.length,
                        separatorBuilder: (_, _2) =>
                            const SizedBox(width: 10),
                        itemBuilder: (_, i) => _ClassCard(slot: slots[i]),
                      ),
                    );
                  }),
                ),

                // ── Pending homework ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: SectionHeader(title: 'Pending Homework'),
                ),
                Builder(builder: (context) {
                  if (!loaded) {
                    return const SliverToBoxAdapter(
                      child: Column(children: [
                        ListTileSkeleton(),
                        ListTileSkeleton(),
                      ]),
                    );
                  }
                  final pending =
                      (state.homework[state.selectedChildId] ?? [])
                          .where(
                              (h) => h.status == 'pending' || h.status == 'late')
                          .take(3)
                          .toList();
                  if (pending.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Text(
                          'No pending homework — great job!',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _HomeworkTile(hw: pending[i]),
                      ),
                      childCount: pending.length,
                    ),
                  );
                }),

                // ── More grid ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: SectionHeader(title: 'More'),
                ),
                SliverToBoxAdapter(child: _MoreGrid()),

                // ── Bottom safe-area spacer ───────────────────────────────
                SliverToBoxAdapter(
                  child: Builder(
                    builder: (context) => SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 24,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _greeting() {
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
  const _ChildSelector(
      {required this.children,
      required this.selectedIndex,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: List.generate(children.length, (i) {
          final child = children[i];
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: Motion.fast,
                curve: Motion.standard,
                margin: EdgeInsets.only(right: i < children.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF059669)
                      : cs.surfaceContainerHighest,
                  borderRadius: Radii.lgRadius,
                  border: selected
                      ? null
                      : Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: selected
                          ? Colors.white.withValues(alpha: 0.25)
                          : cs.primaryContainer,
                      child: Text(
                        child.name[0],
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: selected
                              ? Colors.white
                              : cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name.split(' ').first,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: selected ? Colors.white : cs.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            child.className,
                            style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : cs.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard.filled(
        color: color.withValues(alpha: 0.10),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: Radii.smRadius,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.85),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ParentScheduleSlotModel slot;
  const _ClassCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard.surface(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slot.subject,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              slot.teacherName,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(children: [
              Icon(Icons.access_time_rounded,
                  size: 11, color: const Color(0xFF059669)),
              const SizedBox(width: 3),
              Text(
                slot.startTime,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ],
        ),
      ),
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
    return AppCard.surface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isLate
                ? Colors.red.shade50
                : cs.primaryContainer,
            borderRadius: Radii.smRadius,
          ),
          child: Icon(
            Icons.assignment_rounded,
            color: isLate ? Colors.red.shade600 : cs.onPrimaryContainer,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hw.title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                hw.subject,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Due',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          Text(
            _fmtDate(hw.dueDate),
            style: TextStyle(
              fontSize: 12,
              color: isLate ? Colors.red.shade600 : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      ]),
    );
  }

  String _fmtDate(String iso) {
    try {
      return DateFormat('d MMM').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

class _MoreGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <_MoreItem>[
      _MoreItem(
        icon: Icons.receipt_long_rounded,
        label: 'Invoices',
        color: const Color(0xFF059669),
        builder: (ctx) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: ctx.read<BillingCubit>()),
            BlocProvider.value(value: ctx.read<ParentCubit>()),
          ],
          child: const ParentInvoicesScreen(),
        ),
      ),
      _MoreItem(
        icon: Icons.payments_rounded,
        label: 'Payments',
        color: const Color(0xFF0891B2),
        builder: (ctx) => BlocProvider.value(
          value: ctx.read<BillingCubit>(),
          child: const ParentPaymentsScreen(),
        ),
      ),
      _MoreItem(
        icon: Icons.feedback_outlined,
        label: 'Complaints',
        color: const Color(0xFFF59E0B),
        builder: (ctx) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: ctx.read<ComplaintsCubit>()),
            BlocProvider.value(value: ctx.read<ParentCubit>()),
          ],
          child: const ParentComplaintsScreen(),
        ),
      ),
      _MoreItem(
        icon: Icons.event_note_rounded,
        label: 'Calendar',
        color: const Color(0xFFEC4899),
        builder: (ctx) {
          final cubit = ctx.read<ParentCubit>();
          final st = cubit.state;
          final childId = st is ParentLoaded ? st.selectedChildId : null;
          if (childId == null) {
            return const Scaffold(
                body: Center(child: Text('No child selected.')));
          }
          return AssessmentCalendarScreen(
            title: 'Assessment Calendar',
            fetcher: () => cubit.repo.getChildAssessmentCalendar(childId),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.0,
        children: [for (final item in items) _MoreTile(item: item)],
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final Color color;
  final WidgetBuilder builder;
  const _MoreItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.builder,
  });
}

class _MoreTile extends StatelessWidget {
  final _MoreItem item;
  const _MoreTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard.filled(
      color: item.color.withValues(alpha: 0.10),
      padding: const EdgeInsets.all(10),
      onTap: () {
        // Resolve cubits from outer context before pushing the new route.
        final screen = item.builder(context);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.18),
              borderRadius: Radii.smRadius,
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: item.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
