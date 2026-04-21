import 'package:first_try/core/widgets/shared/change_password_modal.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_notifications_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_notifications_state.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_profile_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_profile_state.dart';
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
            title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
            bottom: TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: 'Notifications'),
              ],
            ),
          ),
          body: switch (state) {
            TeacherProfileLoading() || TeacherProfileInitial() => const LoadingView(),
            TeacherProfileError(:final message) => ErrorView(
                message: message,
                onRetry: () => context.read<TeacherProfileCubit>().load()),
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
        // Avatar
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: 12),
              Text(profile.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(profile.email, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              if (profile.subject != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(profile.subject!,
                      style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        _SectionCard(title: 'Work Info', children: [
          _InfoRow(icon: Icons.school_rounded,        label: 'Subject',       value: profile.subject ?? '—'),
          _InfoRow(icon: Icons.workspace_premium_rounded, label: 'Qualification', value: profile.qualification ?? '—'),
          _InfoRow(icon: Icons.calendar_month_rounded, label: 'School Year',  value: profile.schoolYear ?? '—'),
          _InfoRow(icon: Icons.class_rounded,          label: 'Classes',      value: profile.classCount != null ? '${profile.classCount} classes' : '—'),
        ]),
        const SizedBox(height: 12),

        _SectionCard(title: 'Contact', children: [
          _InfoRow(icon: Icons.email_outlined,  label: 'Email', value: profile.email),
          _InfoRow(icon: Icons.phone_rounded,   label: 'Phone', value: profile.phone ?? '—'),
        ]),
        const SizedBox(height: 24),

        OutlinedButton.icon(
          icon: const Icon(Icons.lock_outline_rounded),
          label: const Text('Change Password'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => showChangePasswordModal(context, onSubmit: (cur, next) async => null),
        ),
        const SizedBox(height: 12),

        FilledButton.icon(
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log Out'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _confirmLogout(context),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () { Navigator.pop(ctx); context.read<AuthCubit>().logout(); },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

// ── Notifications Tab ─────────────────────────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeacherNotificationsCubit, TeacherNotificationsState>(
      builder: (context, state) {
        if (state is TeacherNotificationsLoading || state is TeacherNotificationsInitial) {
          return const LoadingView();
        }
        if (state is! TeacherNotificationsLoaded) return const SizedBox.shrink();
        if (state.notifications.isEmpty) {
          return Center(child: Text('No notifications.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: state.notifications.length,
          separatorBuilder: (context, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final n = state.notifications[i];
            final cs = Theme.of(context).colorScheme;
            return InkWell(
              onTap: () {
                if (!n.isRead) context.read<TeacherNotificationsCubit>().markRead(n.id);
                if (n.body != null) _showDetail(context, n);
              },
              child: Container(
                color: n.isRead ? null : cs.primary.withValues(alpha: 0.06),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_rounded, color: cs.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(n.title,
                                    style: TextStyle(
                                      fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                      fontSize: 14,
                                    )),
                              ),
                              if (!n.isRead)
                                Container(width: 8, height: 8,
                                    decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
                            ],
                          ),
                          if (n.body != null) ...[
                            const SizedBox(height: 4),
                            Text(n.body!, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 4),
                          Text(_fmtTime(n.createdAt),
                              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDetail(BuildContext context, TeacherNotificationModel n) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(4)))),
            Text(n.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(n.body ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Text(_fmtTime(n.createdAt), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  String _fmtTime(String iso) {
    try { return DateFormat('d MMM y • HH:mm').format(DateTime.parse(iso).toLocal()); }
    catch (_) { return iso; }
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
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant, letterSpacing: 0.5)),
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
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
