import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/calendar/assessment_calendar_screen.dart';
import 'package:first_try/core/widgets/shared/change_password_modal.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/shared/profile_avatar_picker.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_attendance_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_availability_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_behavior_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_dashboard_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_notifications_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_notifications_state.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_performance_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_profile_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_profile_state.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_salary_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_vacation_cubit.dart';
import 'package:first_try/features/teacher/presentation/screens/teacher_attendance_screen.dart';
import 'package:first_try/features/teacher/presentation/screens/teacher_availability_screen.dart';
import 'package:first_try/features/teacher/presentation/screens/teacher_behavior_screen.dart';
import 'package:first_try/features/teacher/presentation/screens/teacher_performance_screen.dart';
import 'package:first_try/features/teacher/presentation/screens/teacher_salary_screen.dart';
import 'package:first_try/features/teacher/presentation/screens/teacher_vacation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeacherProfileCubit, TeacherProfileState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile',
                style: TextStyle(fontWeight: FontWeight.w700)),
            bottom: TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: 'Notifications'),
              ],
            ),
          ),
          body: switch (state) {
            TeacherProfileLoading() ||
            TeacherProfileInitial() =>
              const ProfileSkeleton(),
            TeacherProfileError(:final message) => ErrorView(
                message: message,
                onRetry: () =>
                    context.read<TeacherProfileCubit>().load()),
            TeacherProfileLoaded(:final profile) => TabBarView(
                controller: _tab,
                children: [
                  _ProfileTab(profile: profile),
                  const _NotificationsTab(),
                ],
              ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

// ── Profile Tab ───────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final TeacherProfileModel profile;
  const _ProfileTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              ProfileAvatarPicker(displayName: profile.name),
              const SizedBox(height: 12),
              Text(profile.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(profile.email,
                  style:
                      TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              if (profile.subject != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: Radii.pillRadius,
                  ),
                  child: Text(profile.subject!,
                      style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        _SectionCard(title: 'Work Info', children: [
          _InfoRow(
              icon: Icons.school_rounded,
              label: 'Subject',
              value: profile.subject ?? '—'),
          _InfoRow(
              icon: Icons.workspace_premium_rounded,
              label: 'Qualification',
              value: profile.qualification ?? '—'),
          _InfoRow(
              icon: Icons.calendar_month_rounded,
              label: 'School Year',
              value: profile.schoolYear ?? '—'),
          _InfoRow(
              icon: Icons.class_rounded,
              label: 'Classes',
              value: profile.classCount != null
                  ? '${profile.classCount} classes'
                  : '—'),
        ]),
        const SizedBox(height: 12),

        _SectionCard(title: 'Contact', children: [
          _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: profile.email),
          _InfoRow(
              icon: Icons.phone_rounded,
              label: 'Phone',
              value: profile.phone ?? '—'),
        ]),
        const SizedBox(height: 12),

        _SectionCard(title: 'Quick Links', children: [
          _NavRow(
            icon: Icons.fact_check_rounded,
            label: 'Attendance',
            color: const Color(0xFF6366F1),
            onTap: (ctx) => BlocProvider.value(
              value: ctx.read<TeacherAttendanceCubit>(),
              child: const TeacherAttendanceScreen(),
            ),
          ),
          _NavRow(
            icon: Icons.assignment_outlined,
            label: 'Behavior',
            color: const Color(0xFFF59E0B),
            onTap: (ctx) => BlocProvider.value(
              value: ctx.read<TeacherBehaviorCubit>(),
              child: const TeacherBehaviorScreen(),
            ),
          ),
          _NavRow(
            icon: Icons.insights_rounded,
            label: 'Performance',
            color: const Color(0xFF10B981),
            onTap: (ctx) => BlocProvider.value(
              value: ctx.read<TeacherPerformanceCubit>(),
              child: const TeacherPerformanceScreen(),
            ),
          ),
          _NavRow(
            icon: Icons.payments_outlined,
            label: 'Salary',
            color: const Color(0xFF0891B2),
            onTap: (ctx) => BlocProvider.value(
              value: ctx.read<TeacherSalaryCubit>(),
              child: const TeacherSalaryScreen(),
            ),
          ),
          _NavRow(
            icon: Icons.beach_access_rounded,
            label: 'Vacation',
            color: const Color(0xFF8B5CF6),
            onTap: (ctx) => BlocProvider.value(
              value: ctx.read<TeacherVacationCubit>(),
              child: const TeacherVacationScreen(),
            ),
          ),
          _NavRow(
            icon: Icons.schedule_rounded,
            label: 'Availability',
            color: const Color(0xFF3B82F6),
            onTap: (ctx) => BlocProvider.value(
              value: ctx.read<TeacherAvailabilityCubit>(),
              child: const TeacherAvailabilityScreen(),
            ),
          ),
          _NavRow(
            icon: Icons.event_note_rounded,
            label: 'Assessment Calendar',
            color: const Color(0xFFEC4899),
            onTap: (ctx) {
              final repo = ctx.read<TeacherDashboardCubit>().repo;
              return AssessmentCalendarScreen(
                title: 'Assessment Calendar',
                fetcher: repo.getAssessmentCalendar,
              );
            },
          ),
        ]),
        const SizedBox(height: 24),

        OutlinedButton.icon(
          icon: const Icon(Icons.lock_outline_rounded),
          label: const Text('Change Password'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
                borderRadius: Radii.smRadius),
          ),
          onPressed: () => showChangePasswordModal(
            context,
            onSubmit: (current, next) async {
              try {
                await context.read<AuthCubit>().changePassword(
                      currentPassword: current,
                      newPassword: next,
                    );
                return null;
              } catch (e) {
                return e.toString();
              }
            },
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: AppButton.danger(
            label: 'Log Out',
            icon: Icons.logout_rounded,
            onPressed: () => _confirmLogout(context),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _confirmLogout(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<AuthCubit>().logout();
    }
  }
}

// ── Notifications Tab ─────────────────────────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeacherNotificationsCubit, TeacherNotificationsState>(
      builder: (context, state) {
        if (state is TeacherNotificationsLoading ||
            state is TeacherNotificationsInitial) {
          return const CardListSkeleton();
        }
        if (state is! TeacherNotificationsLoaded) {
          return const SizedBox.shrink();
        }
        if (state.notifications.isEmpty) {
          return Center(
              child: Text('No notifications.',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final n = state.notifications[i];
            final cs = Theme.of(context).colorScheme;
            final unread = !n.isRead;

            final content = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: unread
                        ? cs.primary.withValues(alpha: 0.15)
                        : cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_rounded,
                      color:
                          unread ? cs.primary : cs.onSurfaceVariant,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(n.title,
                              style: TextStyle(
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14,
                              )),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle),
                          ),
                      ]),
                      if (n.body != null) ...[
                        const SizedBox(height: 4),
                        Text(n.body!,
                            style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 4),
                      Text(_fmtTime(n.createdAt),
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            );

            return unread
                ? AppCard.filled(
                    color: cs.primary.withValues(alpha: 0.08),
                    padding: const EdgeInsets.all(14),
                    onTap: () {
                      context
                          .read<TeacherNotificationsCubit>()
                          .markRead(n.id);
                      if (n.body != null) _showDetail(context, n);
                    },
                    child: content,
                  )
                : AppCard.surface(
                    padding: const EdgeInsets.all(14),
                    onTap: n.body != null
                        ? () => _showDetail(context, n)
                        : null,
                    child: content,
                  );
          },
        );
      },
    );
  }

  void _showDetail(BuildContext context, TeacherNotificationModel n) {
    showAppBottomSheet<void>(
      context: context,
      title: n.title,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_fmtTime(n.createdAt),
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant)),
            const SizedBox(height: 12),
            Text(n.body ?? '',
                style: const TextStyle(fontSize: 14, height: 1.6)),
          ],
        ),
      ),
    );
  }

  String _fmtTime(String iso) {
    try {
      return DateFormat('d MMM y • HH:mm')
          .format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard.surface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5)),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget Function(BuildContext ctx) onTap;
  const _NavRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final screen = onTap(context);
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => screen));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
