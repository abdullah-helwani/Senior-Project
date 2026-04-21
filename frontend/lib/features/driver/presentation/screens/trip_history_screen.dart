import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/features/driver/data/models/driver_models.dart';
import 'package:first_try/features/driver/presentation/cubit/trip_history_cubit.dart';
import 'package:first_try/features/driver/presentation/cubit/trip_history_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Trip History',
                style:
                    Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
              ),
            ),

            // Filter chips
            const _PeriodFilter(),

            // List
            Expanded(
              child: BlocBuilder<TripHistoryCubit, TripHistoryState>(
                builder: (context, state) {
                  if (state is TripHistoryLoading ||
                      state is TripHistoryInitial) {
                    return const LoadingView();
                  }
                  if (state is TripHistoryError) {
                    return ErrorView(
                      message: state.message,
                      onRetry: () =>
                          context.read<TripHistoryCubit>().loadHistory(),
                    );
                  }
                  if (state is TripHistoryLoaded) {
                    if (state.trips.isEmpty) {
                      return const EmptyState(
                        icon: Icons.history_rounded,
                        title: 'No past trips',
                        subtitle:
                            'Completed trips will appear here.',
                      );
                    }
                    return _HistoryList(trips: state.trips);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Period filter chips ──────────────────────────────────────────────────────

class _PeriodFilter extends StatefulWidget {
  const _PeriodFilter();

  @override
  State<_PeriodFilter> createState() => _PeriodFilterState();
}

class _PeriodFilterState extends State<_PeriodFilter> {
  String? _selected; // null = all

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        children: [
          _FilterChip(
            label: 'All',
            selected: _selected == null,
            onTap: () => _apply(null),
          ),
          _FilterChip(
            label: 'Morning',
            icon: Icons.wb_sunny_rounded,
            color: Colors.orange.shade600,
            selected: _selected == 'morning',
            onTap: () => _apply('morning'),
          ),
          _FilterChip(
            label: 'Afternoon',
            icon: Icons.wb_twilight_rounded,
            color: Colors.indigo.shade400,
            selected: _selected == 'afternoon',
            onTap: () => _apply('afternoon'),
          ),
        ],
      ),
    );
  }

  void _apply(String? period) {
    setState(() => _selected = period);
    context.read<TripHistoryCubit>().loadHistory(period: period);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = color ?? cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : cs.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? activeColor : cs.outline),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History list ─────────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  final List<TripSummaryModel> trips;
  const _HistoryList({required this.trips});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<TripHistoryCubit>().loadHistory(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: trips.length,
        itemBuilder: (context, i) => _HistoryTile(trip: trips[i]),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TripSummaryModel trip;
  const _HistoryTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMorning = trip.period == 'morning';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isMorning
              ? Colors.orange.shade50
              : Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isMorning ? Icons.wb_sunny_rounded : Icons.wb_twilight_rounded,
          color: isMorning
              ? Colors.orange.shade600
              : Colors.indigo.shade400,
          size: 22,
        ),
      ),
      title: Text(
        trip.routeName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '${DateFormat('EEE, d MMM yyyy').format(trip.date)}  ·  ${trip.studentCount} students',
        style: TextStyle(fontSize: 12, color: cs.outline),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Done',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700,
          ),
        ),
      ),
    );
  }
}
