import 'package:first_try/features/parent/data/models/parent_models.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ParentNotificationsScreen extends StatelessWidget {
  const ParentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alerts'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Notifications'),
              Tab(text: 'Warnings'),
            ],
          ),
        ),
        body: BlocBuilder<ParentCubit, ParentState>(
          builder: (context, state) {
            if (state is! ParentLoaded) return const SizedBox.shrink();
            return TabBarView(
              children: [
                _NotificationList(
                  items: state.notifications,
                  onTap: (n) {
                    context.read<ParentCubit>().markRead(n.id);
                    _showDetail(context, n);
                  },
                ),
                _NotificationList(
                  items: state.warnings,
                  isWarning: true,
                  onTap: (n) {
                    context.read<ParentCubit>().markRead(n.id, isWarning: true);
                    _showDetail(context, n, isWarning: true);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, ParentNotificationModel n, {bool isWarning = false}) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isWarning
                      ? Colors.orange.shade100
                      : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isWarning ? Icons.warning_rounded : Icons.notifications_rounded,
                  color: isWarning ? Colors.orange.shade700 : cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(_fmtDate(n.createdAt),
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            Text(n.body ?? '', style: const TextStyle(fontSize: 14, height: 1.6)),
          ]),
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      return DateFormat('d MMM y, h:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

class _NotificationList extends StatelessWidget {
  final List<ParentNotificationModel> items;
  final void Function(ParentNotificationModel) onTap;
  final bool isWarning;

  const _NotificationList({
    required this.items,
    required this.onTap,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text('No ${isWarning ? 'warnings' : 'notifications'}.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (context, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _NotificationTile(
        item: items[i],
        isWarning: isWarning,
        onTap: () => onTap(items[i]),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final ParentNotificationModel item;
  final bool isWarning;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.item,
    required this.isWarning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unread = !item.isRead;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: unread
              ? (isWarning
                  ? Colors.orange.shade50
                  : cs.primaryContainer.withValues(alpha: 0.3))
              : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unread
                ? (isWarning ? Colors.orange.shade200 : cs.primary.withValues(alpha: 0.3))
                : cs.outlineVariant,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isWarning ? Colors.orange.shade100 : cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isWarning ? Icons.warning_rounded : Icons.notifications_rounded,
              size: 20,
              color: isWarning ? Colors.orange.shade700 : cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(item.title,
                      style: TextStyle(
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis),
                ),
                if (unread)
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: isWarning ? Colors.orange.shade600 : cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ]),
              const SizedBox(height: 2),
              Text(item.body ?? '',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(_fmtDate(item.createdAt),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ]),
          ),
        ]),
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      return DateFormat('d MMM, h:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
