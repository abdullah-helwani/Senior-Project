import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
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
          title: const Text('Alerts',
              style: TextStyle(fontWeight: FontWeight.w700)),
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
                  isWarning: false,
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

  void _showDetail(BuildContext context, ParentNotificationModel n,
      {bool isWarning = false}) {
    final cs = Theme.of(context).colorScheme;
    final accent = isWarning ? const Color(0xFFF59E0B) : cs.primary;
    showAppBottomSheet<void>(
      context: context,
      title: n.title,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: Radii.smRadius,
                ),
                child: Icon(
                  isWarning
                      ? Icons.warning_rounded
                      : Icons.notifications_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _fmtDate(n.createdAt),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ]),
            const SizedBox(height: 16),
            Text(
              n.body ?? '',
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ],
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

// ── Notification list ─────────────────────────────────────────────────────────

class _NotificationList extends StatelessWidget {
  final List<ParentNotificationModel> items;
  final bool isWarning;
  final void Function(ParentNotificationModel) onTap;

  const _NotificationList({
    required this.items,
    required this.isWarning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<ParentCubit>().load(),
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
              itemBuilder: (context, i) => _NotificationTile(
                item: items[i],
                isWarning: isWarning,
                onTap: () => onTap(items[i]),
              ),
            ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

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
    final accent = isWarning ? const Color(0xFFF59E0B) : cs.primary;
    final unread = !item.isRead;

    final content = Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: unread ? accent.withValues(alpha: 0.15) : cs.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isWarning ? Icons.warning_rounded : Icons.notifications_rounded,
          size: 20,
          color: unread ? accent : cs.onSurfaceVariant,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            item.title,
            style: TextStyle(
              fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if ((item.body ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.body!,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _fmtDate(item.createdAt),
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ]),
      ),
      if (unread)
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
    ]);

    return unread
        ? AppCard.filled(
            color: accent.withValues(alpha: 0.08),
            padding: const EdgeInsets.all(14),
            onTap: onTap,
            child: content,
          )
        : AppCard.surface(
            padding: const EdgeInsets.all(14),
            onTap: onTap,
            child: content,
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
