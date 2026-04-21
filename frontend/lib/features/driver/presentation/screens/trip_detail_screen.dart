import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/features/driver/data/models/driver_models.dart';
import 'package:first_try/features/driver/presentation/cubit/trip_detail_cubit.dart';
import 'package:first_try/features/driver/presentation/cubit/trip_detail_state.dart';
import 'package:first_try/features/driver/presentation/widgets/student_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  // Per-student loading state for optimistic updates
  final Set<int> _loadingStudents = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripDetailCubit, TripDetailState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            title: Text(
              state is TripDetailLoaded ? state.trip.routeName : 'Trip Detail',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (state is TripDetailLoaded)
                _GpsButton(
                  isActive: state.isGpsActive,
                  lastPing: state.lastPingAt,
                  onToggle: () {
                    final cubit = context.read<TripDetailCubit>();
                    if (state.isGpsActive) {
                      cubit.stopGpsPings();
                    } else {
                      cubit.startGpsPings();
                    }
                  },
                ),
              const SizedBox(width: 8),
            ],
            bottom: state is TripDetailLoaded
                ? TabBar(
                    controller: _tabCtrl,
                    tabs: [
                      Tab(
                        text:
                            'Students (${state.trip.students.length})',
                      ),
                      Tab(text: 'Stops (${state.trip.stops.length})'),
                    ],
                  )
                : null,
          ),
          body: switch (state) {
            TripDetailLoading() || TripDetailInitial() =>
              const LoadingView(),
            TripDetailError(message: final msg) => ErrorView(
                message: msg,
                onRetry: () =>
                    context.read<TripDetailCubit>().loadTrip(),
              ),
            TripDetailLoaded() => Column(
                children: [
                  _TripInfoBanner(trip: state.trip),
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _StudentsTab(
                          students: state.trip.students,
                          loadingStudents: _loadingStudents,
                          onBoarded: (s) => _handleBoarded(context, s),
                          onDropped: (s) => _handleDropped(context, s),
                        ),
                        _StopsTab(stops: state.trip.stops),
                      ],
                    ),
                  ),
                ],
              ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  void _handleBoarded(BuildContext context, StudentTripModel student) {
    setState(() => _loadingStudents.add(student.id));
    context
        .read<TripDetailCubit>()
        .markBoarded(studentId: student.id, stopId: student.stopId)
        .whenComplete(
          () => setState(() => _loadingStudents.remove(student.id)),
        );
  }

  void _handleDropped(BuildContext context, StudentTripModel student) {
    setState(() => _loadingStudents.add(student.id));
    context
        .read<TripDetailCubit>()
        .markDropped(studentId: student.id, stopId: student.stopId)
        .whenComplete(
          () => setState(() => _loadingStudents.remove(student.id)),
        );
  }
}

// ─── Banner ───────────────────────────────────────────────────────────────────

class _TripInfoBanner extends StatelessWidget {
  final TripDetailModel trip;
  const _TripInfoBanner({required this.trip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isMorning = trip.period == 'morning';
    final periodColor =
        isMorning ? Colors.orange.shade600 : Colors.indigo.shade400;
    final periodIcon =
        isMorning ? Icons.wb_sunny_rounded : Icons.wb_twilight_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: cs.surface,
      child: Row(
        children: [
          _Chip(
            icon: Icons.directions_bus_rounded,
            label: trip.busPlate,
            color: cs.primary,
          ),
          const SizedBox(width: 8),
          _Chip(
            icon: periodIcon,
            label: isMorning ? 'Morning' : 'Afternoon',
            color: periodColor,
          ),
          const Spacer(),
          Text(
            DateFormat('d MMM').format(trip.date),
            style: TextStyle(fontSize: 13, color: cs.outline),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── GPS toggle button ────────────────────────────────────────────────────────

class _GpsButton extends StatelessWidget {
  final bool isActive;
  final DateTime? lastPing;
  final VoidCallback onToggle;

  const _GpsButton(
      {required this.isActive,
      required this.lastPing,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isActive
          ? 'GPS active — pinging every 10s'
          : 'GPS inactive — tap to start',
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.shade50
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive
                    ? Icons.gps_fixed_rounded
                    : Icons.gps_not_fixed_rounded,
                size: 16,
                color: isActive
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                isActive ? 'GPS ON' : 'GPS OFF',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Students tab ─────────────────────────────────────────────────────────────

class _StudentsTab extends StatelessWidget {
  final List<StudentTripModel> students;
  final Set<int> loadingStudents;
  final void Function(StudentTripModel) onBoarded;
  final void Function(StudentTripModel) onDropped;

  const _StudentsTab({
    required this.students,
    required this.loadingStudents,
    required this.onBoarded,
    required this.onDropped,
  });

  @override
  Widget build(BuildContext context) {
    // Group students by stop
    final byStop = <String, List<StudentTripModel>>{};
    for (final s in students) {
      byStop.putIfAbsent(s.stopName, () => []).add(s);
    }

    return ListView(
      children: [
        for (final entry in byStop.entries) ...[
          _StopGroupHeader(stopName: entry.key),
          ...entry.value.map(
            (s) => StudentRowWidget(
              student: s,
              isLoading: loadingStudents.contains(s.id),
              onBoarded: () => onBoarded(s),
              onDropped: () => onDropped(s),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StopGroupHeader extends StatelessWidget {
  final String stopName;
  const _StopGroupHeader({required this.stopName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            stopName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stops tab ────────────────────────────────────────────────────────────────

class _StopsTab extends StatelessWidget {
  final List<StopModel> stops;
  const _StopsTab({required this.stops});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: stops.length,
      separatorBuilder: (context, _) => const SizedBox(height: 0),
      itemBuilder: (context, i) {
        final stop = stops[i];
        final isLast = i == stops.length - 1;

        return Row(
          children: [
            // Timeline indicator
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLast
                          ? cs.primary
                          : cs.primaryContainer,
                      border: Border.all(color: cs.primary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${stop.order}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isLast
                              ? cs.onPrimary
                              : cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(width: 2, height: 40, color: cs.primaryContainer),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Stop info
            Expanded(
              child: Container(
                height: isLast ? 60 : 60,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.name,
                      style: TextStyle(
                        fontWeight: isLast
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 14,
                        color: isLast ? cs.primary : cs.onSurface,
                      ),
                    ),
                    if (isLast)
                      Text(
                        'Final stop',
                        style: TextStyle(fontSize: 12, color: cs.primary),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
