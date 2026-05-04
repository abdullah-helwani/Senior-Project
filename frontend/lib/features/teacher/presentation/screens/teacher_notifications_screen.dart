import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_notifications_cubit.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_notifications_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Dedicated full-screen notifications view for teachers. Reachable from
/// the bell icon on TeacherHomeScreen — same cubit instance flows through
/// via BlocProvider.value.
class TeacherNotificationsScreen extends StatelessWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          BlocBuilder<TeacherNotificationsCubit, TeacherNotificationsState>(
            builder: (context, state) {
              final hasUnread = state is TeacherNotificationsLoaded &&
                  state.unreadCount > 0;
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _markAllRead(context, state),
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Mark all'),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TeacherNotificationsCubit, TeacherNotificationsState>(
        builder: (context, state) {
          if (state is TeacherNotificationsLoading ||
              state is TeacherNotificationsInitial) {
            return const CardListSkeleton(showFilter: true);
          }
          if (state is! TeacherNotificationsLoaded) {
            return const SizedBox.shrink();
          }
          if (state.notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<TeacherNotificationsCubit>().load(),
              child: ListView(
                children: [
                  const SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'No notifications',
                    subtitle: 'Pull to refresh.',
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                context.read<TeacherNotificationsCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _NotifTile(notif: state.notifications[i]),
            ),
          );
        },
      ),
    );
  }

  void _markAllRead(BuildContext context, TeacherNotificationsState state) {
    if (state is! TeacherNotificationsLoaded) return;
    final cubit = context.read<TeacherNotificationsCubit>();
    for (final n in state.notifications.where((n) => !n.isRead)) {
      cubit.markRead(n.id);
    }
  }
}

class _NotifTile extends StatelessWidget {
  final TeacherNotificationModel notif;
  const _NotifTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Unread notifications use a tinted filled card; read ones use surface.
    final card = notif.isRead
        ? AppCard.surface(
            padding: const EdgeInsets.all(14),
            child: _body(context, cs),
          )
        : AppCard.filled(
            color: cs.primaryContainer.withValues(alpha: 0.45),
            padding: const EdgeInsets.all(14),
            onTap: () => context
                .read<TeacherNotificationsCubit>()
                .markRead(notif.id),
            child: _body(context, cs),
          );

    return card;
  }

  Widget _body(BuildContext context, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: notif.isRead
                ? cs.surfaceContainerHighest
                : cs.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_rounded,
            color:
                notif.isRead ? cs.onSurfaceVariant : cs.onPrimaryContainer,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notif.title,
                style: TextStyle(
                  fontWeight:
                      notif.isRead ? FontWeight.w600 : FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              if (notif.body != null) ...[
                const SizedBox(height: 3),
                Text(
                  notif.body!,
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _relTime(notif.createdAt),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (!notif.isRead)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, left: 6),
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  String _relTime(String iso) {
    try {
      final d = DateTime.parse(iso);
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('d MMM y').format(d);
    } catch (_) {
      return iso;
    }
  }
}
