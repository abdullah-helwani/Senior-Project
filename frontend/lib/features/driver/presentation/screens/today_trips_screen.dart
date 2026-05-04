import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/features/driver/data/models/driver_models.dart';
import 'package:first_try/features/driver/presentation/cubit/today_trips_cubit.dart';
import 'package:first_try/features/driver/presentation/cubit/today_trips_state.dart';
import 'package:first_try/features/driver/presentation/widgets/trip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TodayTripsScreen extends StatelessWidget {
  const TodayTripsScreen({super.key});

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Trips",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<TodayTripsCubit, TodayTripsState>(
                builder: (context, state) {
                  if (state is TodayTripsLoading || state is TodayTripsInitial) {
                    return const CardListSkeleton();
                  }
                  if (state is TodayTripsError) {
                    return ErrorView(
                      message: state.message,
                      onRetry: () =>
                          context.read<TodayTripsCubit>().loadTodayTrips(),
                    );
                  }
                  if (state is TodayTripsLoaded) {
                    if (state.trips.isEmpty) {
                      return const EmptyState(
                        icon: Icons.directions_bus_outlined,
                        title: 'No trips today',
                        subtitle: 'You have no scheduled trips for today.',
                      );
                    }
                    return _TripList(trips: state.trips);
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

class _TripList extends StatelessWidget {
  final List<TripSummaryModel> trips;
  const _TripList({required this.trips});

  @override
  Widget build(BuildContext context) {
    final morning   = trips.where((t) => t.period == 'morning').toList();
    final afternoon = trips.where((t) => t.period == 'afternoon').toList();

    return RefreshIndicator(
      onRefresh: () => context.read<TodayTripsCubit>().loadTodayTrips(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (morning.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.wb_sunny_rounded,
              label: 'Morning',
              color: Colors.orange.shade600,
            ),
            ...morning.map(
              (t) => TripCard(
                trip: t,
                onTap: () => context.push('/driver/trip/${t.id}'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (afternoon.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.wb_twilight_rounded,
              label: 'Afternoon',
              color: Colors.indigo.shade400,
            ),
            ...afternoon.map(
              (t) => TripCard(
                trip: t,
                onTap: () => context.push('/driver/trip/${t.id}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
