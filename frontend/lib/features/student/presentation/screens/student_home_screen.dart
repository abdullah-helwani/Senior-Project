import 'package:dio/dio.dart';
import 'package:first_try/core/api/dio_consumer.dart';
import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/calendar/assessment_calendar_screen.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/auth/current_user.dart';
import 'package:first_try/features/student/data/repos/student_repo.dart';
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

// Student role gradient: blue → indigo
const _kHeroGradient = [Color(0xFF3B82F6), Color(0xFF6366F1)];

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<DashboardCubit>().load();
          context.read<ScheduleCubit>().load();
          context.read<HomeworkCubit>().load();
        },
        child: CustomScrollView(
          slivers: [
            // ── Gradient hero ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: BlocBuilder<DashboardCubit, DashboardState>(
                builder: (context, state) {
                  final name = state is DashboardLoaded
                      ? state.dashboard.name.split(' ').first
                      : '';
                  return GradientHero(
                    greeting:
                        'Good ${_greeting()}${name.isNotEmpty ? ', $name' : ''}',
                    subtitle:
                        DateFormat('EEEE, d MMMM').format(DateTime.now()),
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
                      child: const Icon(Icons.school_rounded,
                          color: Colors.white, size: 22),
                    ),
                  );
                },
              ),
            ),

            // ── Stat cards ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: BlocBuilder<DashboardCubit, DashboardState>(
                builder: (context, state) {
                  final loaded = state is DashboardLoaded;
                  return Padding(
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
                                icon: Icons.class_rounded,
                                label: 'Classes\ntoday',
                                value:
                                    '${state.dashboard.todayClassesCount}',
                                color: const Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                icon: Icons.assignment_rounded,
                                label: 'Pending\nhomework',
                                value:
                                    '${state.dashboard.upcomingHomeworkCount}',
                                color: const Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                icon: Icons.event_available_rounded,
                                label: 'Attendance',
                                value:
                                    '${state.dashboard.attendancePercent.toStringAsFixed(0)}%',
                                color: const Color(0xFF10B981),
                              ),
                            ])
                          : const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ),

            // ── Today's classes ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(title: "Today's Classes"),
            ),
            SliverToBoxAdapter(
              child: BlocBuilder<ScheduleCubit, ScheduleState>(
                builder: (context, state) {
                  if (state is! ScheduleLoaded) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(children: [
                        ListTileSkeleton(),
                        ListTileSkeleton(),
                      ]),
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
                      separatorBuilder: (_, _2) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _ClassCard(slot: slots[i]),
                    ),
                  );
                },
              ),
            ),

            // ── Upcoming homework ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(title: 'Upcoming Homework'),
            ),
            BlocBuilder<HomeworkCubit, HomeworkState>(
              builder: (context, state) {
                if (state is! HomeworkLoaded) {
                  return const SliverToBoxAdapter(
                    child: Column(
                        children: [ListTileSkeleton(), ListTileSkeleton()]),
                  );
                }
                final pending = state.homework
                    .where((h) => h.status == 'pending' || h.status == 'late')
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
              },
            ),

            // ── Calendar shortcut ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _CalendarTile(),
              ),
            ),

            // ── Bottom safe-area spacer ───────────────────────────────────
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) => SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 24,
                ),
              ),
            ),
          ],
        ),
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
  final ScheduleSlotModel slot;
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
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
              const Icon(Icons.access_time_rounded,
                  size: 11, color: Color(0xFF3B82F6)),
              const SizedBox(width: 3),
              Text(
                slot.startTime,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF3B82F6),
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
  final HomeworkModel hw;
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
            color:
                isLate ? Colors.red.shade50 : cs.primaryContainer,
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
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
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

class _CalendarTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF3B82F6);
    return AppCard.filled(
      color: color.withValues(alpha: 0.08),
      onTap: () {
        final studentId = context.currentRoleId;
        final repo =
            StudentRepo(api: DioConsumer(dio: Dio()), studentId: studentId);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssessmentCalendarScreen(
              title: 'Assessment Calendar',
              fetcher: repo.getAssessmentCalendar,
            ),
          ),
        );
      },
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: Radii.smRadius,
          ),
          child: const Icon(Icons.event_note_rounded, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Assessment Calendar',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14, color: color),
            ),
            Text(
              'Upcoming exams, quizzes & homework',
              style: TextStyle(
                  fontSize: 12, color: color.withValues(alpha: 0.80)),
            ),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded, color: color),
      ]),
    );
  }
}
