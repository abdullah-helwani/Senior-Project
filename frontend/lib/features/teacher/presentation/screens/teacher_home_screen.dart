import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_dashboard_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_dashboard_state.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_notifications_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_notifications_state.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_schedule_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_schedule_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<TeacherDashboardCubit>().load();
            context.read<TeacherScheduleCubit>().load();
            context.read<TeacherNotificationsCubit>().load();
          },
          child: CustomScrollView(
            slivers: [
              // ── Header ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: BlocBuilder<TeacherDashboardCubit, TeacherDashboardState>(
                  builder: (context, state) {
                    final name = state is TeacherDashboardLoaded
                        ? state.dashboard.name.split(' ').last
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
                                  'Good ${_greeting()}${name.isNotEmpty ? ', $name' : ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          BlocBuilder<TeacherNotificationsCubit, TeacherNotificationsState>(
                            builder: (context, state) {
                              final count = state is TeacherNotificationsLoaded
                                  ? state.unreadCount : 0;
                              return Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: cs.primaryContainer,
                                    radius: 22,
                                    child: Icon(Icons.person_rounded, color: cs.onPrimaryContainer),
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      right: 0, top: 0,
                                      child: Container(
                                        width: 16, height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade600,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text('$count',
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Stats ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: BlocBuilder<TeacherDashboardCubit, TeacherDashboardState>(
                  builder: (context, state) {
                    if (state is! TeacherDashboardLoaded) {
                      return const SizedBox(height: 100, child: LoadingView());
                    }
                    final d = state.dashboard;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _StatCard(icon: Icons.class_rounded,      label: 'Classes\ntoday',    value: '${d.todayClassesCount}',    color: cs.primary),
                          const SizedBox(width: 10),
                          _StatCard(icon: Icons.grading_rounded,    label: 'Pending\ngrading',  value: '${d.pendingGradingCount}',  color: Colors.orange.shade600),
                          const SizedBox(width: 10),
                          _StatCard(icon: Icons.people_rounded,     label: 'Total\nstudents',   value: '${d.totalStudents}',        color: Colors.green.shade600),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Today's schedule ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionTitle(title: "Today's Schedule"),
              ),
              SliverToBoxAdapter(
                child: BlocBuilder<TeacherScheduleCubit, TeacherScheduleState>(
                  builder: (context, state) {
                    if (state is! TeacherScheduleLoaded) {
                      return const SizedBox(height: 80, child: LoadingView());
                    }
                    final slots = state.slotsForDay;
                    if (slots.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('No classes today.', style: TextStyle(color: cs.onSurfaceVariant)),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: slots.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _ScheduleTile(slot: slots[i]),
                    );
                  },
                ),
              ),

              // ── Notifications preview ────────────────────────────────────
              SliverToBoxAdapter(child: _SectionTitle(title: 'Recent Alerts')),
              BlocBuilder<TeacherNotificationsCubit, TeacherNotificationsState>(
                builder: (context, state) {
                  if (state is! TeacherNotificationsLoaded) {
                    return const SliverToBoxAdapter(child: SizedBox(height: 60, child: LoadingView()));
                  }
                  final unread = state.notifications.where((n) => !n.isRead).take(3).toList();
                  if (unread.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('All caught up!', style: TextStyle(color: cs.onSurfaceVariant)),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _NotifTile(notification: unread[i]),
                      childCount: unread.length,
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
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
            ],
          ),
        ),
      );
}

class _ScheduleTile extends StatelessWidget {
  final TeacherScheduleSlotModel slot;
  const _ScheduleTile({required this.slot});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 44, decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.className, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(slot.subject, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(slot.startTime, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.primary)),
              Text(slot.endTime, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final TeacherNotificationModel notification;
  const _NotifTile({required this.notification});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(notification.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
