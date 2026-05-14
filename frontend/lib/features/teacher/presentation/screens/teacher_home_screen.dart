import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';
import 'package:first_try/features/teacher/presentation/screens/teacher_notifications_screen.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_dashboard_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_dashboard_state.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_notifications_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_notifications_state.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_schedule_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_schedule_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// Teacher role gradient: indigo → violet
const _kHeroGradient = [Color(0xFF6366F1), Color(0xFF8B5CF6)];

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      // No outer SafeArea — GradientHero handles its own top inset.
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<TeacherDashboardCubit>().load();
          context.read<TeacherScheduleCubit>().load();
          context.read<TeacherNotificationsCubit>().load();
        },
        child: CustomScrollView(
          slivers: [
            // ── Gradient hero ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: BlocBuilder<TeacherDashboardCubit, TeacherDashboardState>(
                builder: (context, dashState) {
                  final name = dashState is TeacherDashboardLoaded
                      ? dashState.dashboard.name.split(' ').first
                      : '';
                  return BlocBuilder<TeacherNotificationsCubit,
                      TeacherNotificationsState>(
                    builder: (context, notifState) {
                      final count = notifState is TeacherNotificationsLoaded
                          ? notifState.unreadCount
                          : 0;
                      final loaded = dashState is TeacherDashboardLoaded;
                      return GradientHero(
                        greeting:
                            'Good ${_greeting()}${name.isNotEmpty ? ', $name' : ''}',
                        subtitle: DateFormat('EEEE, d MMMM')
                            .format(DateTime.now()),
                        colors: _kHeroGradient,
                        stats: loaded
                            ? [
                                HeroStat(
                                  value: '${dashState.dashboard.todayClassesCount}',
                                  label: 'Classes today',
                                ),
                                HeroStat(
                                  value: '${dashState.dashboard.pendingGradingCount}',
                                  label: 'To grade',
                                ),
                                HeroStat(
                                  value: '$count',
                                  label: 'Alerts',
                                ),
                              ]
                            : null,
                        trailing: _NotifBell(
                          count: count,
                          onTap: () {
                            final cubit =
                                context.read<TeacherNotificationsCubit>();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: cubit,
                                  child: const TeacherNotificationsScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ── Stat cards ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: BlocBuilder<TeacherDashboardCubit, TeacherDashboardState>(
                builder: (context, state) {
                  final loaded = state is TeacherDashboardLoaded;
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
                                color: const Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                icon: Icons.grading_rounded,
                                label: 'Pending\ngrading',
                                value:
                                    '${state.dashboard.pendingGradingCount}',
                                color: const Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                icon: Icons.people_rounded,
                                label: 'Total\nstudents',
                                value: '${state.dashboard.totalStudents}',
                                color: const Color(0xFF10B981),
                              ),
                            ])
                          : const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ),

            // ── Today's schedule ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(title: "Today's Schedule"),
            ),
            SliverToBoxAdapter(
              child: BlocBuilder<TeacherScheduleCubit, TeacherScheduleState>(
                builder: (context, state) {
                  if (state is! TeacherScheduleLoaded) {
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: slots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _ScheduleTile(slot: slots[i]),
                  );
                },
              ),
            ),

            // ── Recent alerts ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(title: 'Recent Alerts'),
            ),
            BlocBuilder<TeacherNotificationsCubit, TeacherNotificationsState>(
              builder: (context, state) {
                if (state is! TeacherNotificationsLoaded) {
                  return const SliverToBoxAdapter(
                    child: Column(children: [
                      ListTileSkeleton(),
                      ListTileSkeleton(),
                    ]),
                  );
                }
                final unread = state.notifications
                    .where((n) => !n.isRead)
                    .take(3)
                    .toList();
                if (unread.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(
                        'All caught up! No unread notifications.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      child: _NotifTile(notification: unread[i]),
                    ),
                    childCount: unread.length,
                  ),
                );
              },
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

// ── Shared small widgets ───────────────────────────────────────────────────────

class _NotifBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NotifBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: Radii.mdRadius,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.30), width: 1),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.red.shade500,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
        ],
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
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: Radii.mdRadius,
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: Radii.smRadius,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final TeacherScheduleSlotModel slot;
  const _ScheduleTile({required this.slot});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard.surface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Accent bar
          Container(
            width: 3,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: Radii.pillRadius,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.className,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  slot.subject,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                slot.startTime,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.primary),
              ),
              Text(
                slot.endTime,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
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
    return AppCard.filled(
      color: cs.primaryContainer.withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_rounded, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

