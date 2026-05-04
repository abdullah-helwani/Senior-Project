import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/student/data/models/student_models.dart';
import 'package:first_try/features/student/presentation/cubit/notifications_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/notifications_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen>
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
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final unread = state is NotificationsLoaded ? state.unreadCount : 0;

        return Scaffold(
          appBar: AppBar(
            title: Row(children: [
              const Text('Notifications',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: Radii.pillRadius,
                  ),
                  child: Text(
                    '$unread',
                    style: TextStyle(
                        color: cs.onError,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ]),
            bottom: TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: 'Notifications'),
                Tab(text: 'Warnings'),
              ],
            ),
          ),
          body: switch (state) {
            NotificationsLoading() || NotificationsInitial() =>
              const LoadingView(),
            NotificationsError(:final message) => ErrorView(
                message: message,
                onRetry: () =>
                    context.read<NotificationsCubit>().load()),
            NotificationsLoaded() => TabBarView(
                controller: _tab,
                children: [
                  _NotifList(
                    items: state.notifications,
                    isWarning: false,
                    onMarkRead: (id) =>
                        context.read<NotificationsCubit>().markRead(id),
                  ),
                  _NotifList(
                    items: state.warnings,
                    isWarning: true,
                    onMarkRead: (id) => context
                        .read<NotificationsCubit>()
                        .markRead(id, isWarning: true),
                  ),
                ],
              ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

// ── Notification list ─────────────────────────────────────────────────────────

class _NotifList extends StatelessWidget {
  final List<NotificationModel> items;
  final bool isWarning;
  final void Function(int) onMarkRead;

  const _NotifList({
    required this.items,
    this.isWarning = false,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<NotificationsCubit>().load(),
      child: items.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 80),
                EmptyState(
                  icon: isWarning
                      ? Icons.warning_amber_outlined
                      : Icons.notifications_off_outlined,
                  title: isWarning ? 'No warnings' : 'No notifications',
                  subtitle: 'Pull to refresh.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _NotifTile(
                item: items[i],
                isWarning: isWarning,
                onMarkRead: onMarkRead,
              ),
            ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final NotificationModel item;
  final bool isWarning;
  final void Function(int) onMarkRead;

  const _NotifTile({
    required this.item,
    required this.isWarning,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent =
        isWarning ? const Color(0xFFF59E0B) : cs.primary;
    final unread = !item.isRead;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: unread
                ? accent.withValues(alpha: 0.15)
                : cs.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isWarning
                ? Icons.warning_amber_rounded
                : Icons.notifications_rounded,
            color: unread ? accent : cs.onSurfaceVariant,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight:
                          unread ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (unread)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                        color: accent, shape: BoxShape.circle),
                  ),
              ]),
              if (item.body != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.body!,
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _fmtTime(item.createdAt),
                style:
                    TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );

    return unread
        ? AppCard.filled(
            color: accent.withValues(alpha: 0.08),
            padding: const EdgeInsets.all(14),
            onTap: () {
              onMarkRead(item.id);
              if (item.body != null) _showDetail(context, item, accent);
            },
            child: content,
          )
        : AppCard.surface(
            padding: const EdgeInsets.all(14),
            onTap: item.body != null
                ? () => _showDetail(context, item, accent)
                : null,
            child: content,
          );
  }

  void _showDetail(
      BuildContext context, NotificationModel item, Color accent) {
    showAppBottomSheet<void>(
      context: context,
      title: item.title,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWarning
                      ? Icons.warning_amber_rounded
                      : Icons.notifications_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _fmtTime(item.createdAt),
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ]),
            const SizedBox(height: 16),
            Text(
              item.body ?? '',
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
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
