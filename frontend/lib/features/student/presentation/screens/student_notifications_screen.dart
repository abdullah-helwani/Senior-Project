import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
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
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final unread = state is NotificationsLoaded ? state.unreadCount : 0;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('Notifications',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
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
                    onMarkRead: (id) => context
                        .read<NotificationsCubit>()
                        .markRead(id),
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
    if (items.isEmpty) {
      return Center(
        child: Text(
          isWarning ? 'No warnings.' : 'No notifications.',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _NotifTile(
        item: items[i],
        isWarning: isWarning,
        onMarkRead: onMarkRead,
      ),
    );
  }
}

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
        isWarning ? Colors.orange.shade600 : cs.primary;

    return InkWell(
      onTap: () {
        if (!item.isRead) onMarkRead(item.id);
        if (item.body != null) {
          _showDetail(context, item, accent);
        }
      },
      child: Container(
        color:
            item.isRead ? null : accent.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if (item.body != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.body!,
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _fmtTime(item.createdAt),
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(
      BuildContext context, NotificationModel item, Color accent) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    isWarning
                        ? Icons.warning_amber_rounded
                        : Icons.notifications_rounded,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(item.body ?? '',
                  style: TextStyle(
                      fontSize: 14, color: cs.onSurface)),
              const SizedBox(height: 12),
              Text(
                _fmtTime(item.createdAt),
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
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
