import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/features/student/data/models/student_models.dart';
import 'package:first_try/features/student/presentation/cubit/bus_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/bus_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class StudentBusScreen extends StatefulWidget {
  const StudentBusScreen({super.key});

  @override
  State<StudentBusScreen> createState() => _StudentBusScreenState();
}

class _StudentBusScreenState extends State<StudentBusScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Assignment'),
            Tab(text: 'Live'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: BlocBuilder<BusCubit, BusState>(
        builder: (context, state) {
          if (state is BusLoading || state is BusInitial) {
            return const LoadingView();
          }
          if (state is BusError) {
            return ErrorView(
                message: state.message,
                onRetry: () => context.read<BusCubit>().load());
          }
          if (state is! BusLoaded) return const SizedBox.shrink();

          return TabBarView(
            controller: _tab,
            children: [
              _AssignmentTab(assignment: state.assignment),
              _LiveTab(location: state.liveLocation),
              _HistoryTab(events: state.events),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Assignment Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _AssignmentTab extends StatelessWidget {
  final BusAssignmentModel assignment;
  const _AssignmentTab({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bus info card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_bus_rounded,
                      color: cs.onPrimary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.busPlate,
                          style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800),
                        ),
                        Text(
                          assignment.routeName,
                          style: TextStyle(
                              color: cs.onPrimary
                                  .withValues(alpha: 0.85),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      color: cs.onPrimary.withValues(alpha: 0.8),
                      size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Your stop: ${assignment.pickupStopName}',
                    style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Route Stops',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        // Stops timeline
        ...List.generate(assignment.stops.length, (i) {
          final stop = assignment.stops[i];
          final isLast = i == assignment.stops.length - 1;
          final isMyStop = stop.name == assignment.pickupStopName;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isMyStop
                            ? cs.primary
                            : cs.primaryContainer,
                        border: Border.all(
                            color: cs.primary, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${stop.order}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isMyStop
                                ? cs.onPrimary
                                : cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                          width: 2,
                          height: 36,
                          color: cs.primaryContainer),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        stop.name,
                        style: TextStyle(
                          fontWeight: isMyStop
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                          color: isMyStop
                              ? cs.primary
                              : cs.onSurface,
                        ),
                      ),
                      if (isMyStop) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary
                                .withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Text('Your stop',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.primary,
                                  fontWeight:
                                      FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Live Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _LiveTab extends StatelessWidget {
  final BusLiveLocationModel? location;
  const _LiveTab({required this.location});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (location == null || !location!.hasLocation) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gps_off_rounded,
                size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Bus location not available',
                style: TextStyle(
                    fontSize: 16, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              onPressed: () =>
                  context.read<BusCubit>().refreshLive(),
            ),
          ],
        ),
      );
    }

    final loc = location!;
    return RefreshIndicator(
      onRefresh: () => context.read<BusCubit>().refreshLive(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Map placeholder (real map would use flutter_map / google_maps)
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_rounded,
                    size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 8),
                Text('Map view — integrate flutter_map',
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '${loc.latitude!.toStringAsFixed(4)}, ${loc.longitude!.toStringAsFixed(4)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'Driver',
                    value: loc.driverName ?? 'Unknown'),
                const Divider(height: 20),
                _InfoRow(
                    icon: Icons.route_rounded,
                    label: 'Route',
                    value: loc.routeName ?? 'Unknown'),
                const Divider(height: 20),
                _InfoRow(
                    icon: Icons.access_time_rounded,
                    label: 'Last updated',
                    value: loc.updatedAt != null
                        ? _fmtTime(loc.updatedAt!)
                        : 'Unknown'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.gps_fixed_rounded,
                    color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Live tracking active',
                  style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(String iso) {
    try {
      return DateFormat('d MMM • HH:mm')
          .format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontSize: 13, color: cs.onSurfaceVariant)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// History Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _HistoryTab extends StatelessWidget {
  final List<BusEventModel> events;
  const _HistoryTab({required this.events});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (events.isEmpty) {
      return Center(
        child: Text('No bus events yet.',
            style:
                TextStyle(color: cs.onSurfaceVariant)),
      );
    }

    // Group by date
    final grouped = <String, List<BusEventModel>>{};
    for (final e in events) {
      grouped.putIfAbsent(e.date, () => []).add(e);
    }
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final date in sortedDates) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              _fmtDate(date),
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: cs.onSurfaceVariant),
            ),
          ),
          ...grouped[date]!.map((e) => _EventTile(event: e)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  String _fmtDate(String iso) {
    try {
      return DateFormat('EEEE, d MMMM y')
          .format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

class _EventTile extends StatelessWidget {
  final BusEventModel event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isBoarded = event.eventType == 'boarded';
    final color =
        isBoarded ? Colors.green.shade600 : Colors.blue.shade600;
    final icon = isBoarded
        ? Icons.login_rounded
        : Icons.logout_rounded;
    final label = isBoarded ? 'Boarded' : 'Dropped off';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color)),
                Text(event.stopName,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            event.time,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
