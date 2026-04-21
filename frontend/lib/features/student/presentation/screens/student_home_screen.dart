import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/features/student/data/models/student_models.dart';
import 'package:first_try/features/student/presentation/cubit/dashboard_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/dashboard_state.dart';
import 'package:first_try/features/student/presentation/cubit/homework_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/homework_state.dart';
import 'package:first_try/features/student/presentation/cubit/schedule_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/schedule_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<DashboardCubit>().load();
            context.read<ScheduleCubit>().load();
            context.read<HomeworkCubit>().load();
          },
          child: CustomScrollView(
            slivers: [
              // ── Greeting header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: BlocBuilder<DashboardCubit, DashboardState>(
                  builder: (context, state) {
                    final name = state is DashboardLoaded
                        ? state.dashboard.name.split(' ').first
                        : '';
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${_greeting()}'
                                  '${name.isNotEmpty ? ', $name' : ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEEE, d MMMM y')
                                      .format(DateTime.now()),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            radius: 22,
                            child: Icon(Icons.person_rounded,
                                color: cs.onPrimaryContainer),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Stats row ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: BlocBuilder<DashboardCubit, DashboardState>(
                  builder: (context, state) {
                    if (state is DashboardLoading ||
                        state is DashboardInitial) {
                      return const SizedBox(
                          height: 100, child: LoadingView());
                    }
                    if (state is! DashboardLoaded) {
                      return const SizedBox.shrink();
                    }
                    final d = state.dashboard;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _StatCard(
                            icon: Icons.class_rounded,
                            label: 'Classes\ntoday',
                            value: '${d.todayClassesCount}',
                            color: cs.primary,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            icon: Icons.assignment_rounded,
                            label: 'Pending\nhomework',
                            value: '${d.upcomingHomeworkCount}',
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            icon: Icons.bar_chart_rounded,
                            label: 'Attendance',
                            value:
                                '${d.attendancePercent.toStringAsFixed(0)}%',
                            color: Colors.green.shade600,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Today's classes ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionTitle(title: "Today's Classes"),
              ),
              SliverToBoxAdapter(
                child: BlocBuilder<ScheduleCubit, ScheduleState>(
                  builder: (context, state) {
                    if (state is! ScheduleLoaded) {
                      return const SizedBox(
                          height: 80, child: LoadingView());
                    }
                    final slots = state.slotsForDay;
                    if (slots.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'No classes today.',
                          style:
                              TextStyle(color: cs.onSurfaceVariant),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: slots.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, i) =>
                            _ClassCard(slot: slots[i]),
                      ),
                    );
                  },
                ),
              ),

              // ── Upcoming homework ────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionTitle(title: 'Upcoming Homework'),
              ),
              BlocBuilder<HomeworkCubit, HomeworkState>(
                builder: (context, state) {
                  if (state is! HomeworkLoaded) {
                    return const SliverToBoxAdapter(
                        child: SizedBox(
                            height: 60, child: LoadingView()));
                  }
                  final pending = state.homework
                      .where((h) =>
                          h.status == 'pending' || h.status == 'late')
                      .take(3)
                      .toList();
                  if (pending.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'No pending homework.',
                          style: TextStyle(
                              color: cs.onSurfaceVariant),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) =>
                          _HomeworkTile(hw: pending[i]),
                      childCount: pending.length,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
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
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ScheduleSlotModel slot;
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
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot.subject,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            slot.teacherName,
            style:
                TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 11, color: cs.primary),
              const SizedBox(width: 3),
              Text(
                slot.startTime,
                style: TextStyle(
                    fontSize: 11,
                    color: cs.primary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeworkTile extends StatelessWidget {
  final HomeworkModel hw;
  const _HomeworkTile({required this.hw});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLate = hw.status == 'late';
    final dueColor =
        isLate ? Colors.red.shade600 : cs.onSurfaceVariant;

    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isLate
                ? Colors.red.shade200
                : cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.assignment_rounded,
                color: cs.onPrimaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hw.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hw.subject,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Due',
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant)),
              Text(
                _fmtDate(hw.dueDate),
                style: TextStyle(
                    fontSize: 12,
                    color: dueColor,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
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
