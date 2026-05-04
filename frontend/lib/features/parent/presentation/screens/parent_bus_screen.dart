import 'dart:async';

import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/parent/data/models/parent_models.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class ParentBusScreen extends StatelessWidget {
  const ParentBusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Tracking',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<ParentCubit, ParentState>(
        builder: (context, state) {
          if (state is! ParentLoaded) return const SizedBox.shrink();

          final busData = state.bus[state.selectedChildId];
          final childName = state.selectedChild.name.split(' ').first;

          return RefreshIndicator(
            onRefresh: () => context.read<ParentCubit>().load(),
            child: CustomScrollView(
              slivers: [
                // Child selector
                SliverToBoxAdapter(
                  child: _ChildTabBar(
                    children: state.profile.children,
                    selectedIndex: state.selectedChildIndex,
                    onSelect: (i) =>
                        context.read<ParentCubit>().selectChild(i),
                  ),
                ),

                if (busData == null) ...[
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No bus assigned for $childName.',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                    ),
                  ),
                ] else ...[
                  SliverToBoxAdapter(
                      child: _BusStatusCard(bus: busData)),
                  SliverToBoxAdapter(
                      child: _BusInfoSection(
                          bus: busData, childName: childName)),
                  SliverToBoxAdapter(
                      child: _BusLiveMap(bus: busData)),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Child tab bar ─────────────────────────────────────────────────────────────

class _ChildTabBar extends StatelessWidget {
  final List<ChildSummaryModel> children;
  final int selectedIndex;
  final void Function(int) onSelect;

  const _ChildTabBar({
    required this.children,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: List.generate(children.length, (i) {
          final child = children[i];
          final selected = i == selectedIndex;
          return Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(right: i < children.length - 1 ? 8 : 0),
              child: FilterPill(
                label: child.name.split(' ').first,
                selected: selected,
                onSelected: (_) => onSelect(i),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Bus status card ───────────────────────────────────────────────────────────

class _BusStatusCard extends StatelessWidget {
  final ParentBusModel bus;
  const _BusStatusCard({required this.bus});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: AppCard.glass(
        gradient: palette.brandGradient,
        opacity: 0.92,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: Radii.smRadius,
            ),
            child: const Icon(Icons.directions_bus_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus.busPlate,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bus.routeName,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ]),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF34D399),
              borderRadius: Radii.pillRadius,
            ),
            child: Row(children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              const Text('Active',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Bus info section ──────────────────────────────────────────────────────────

class _BusInfoSection extends StatelessWidget {
  final ParentBusModel bus;
  final String childName;
  const _BusInfoSection({required this.bus, required this.childName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Route Details',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        _InfoRow(
          icon: Icons.place_rounded,
          label: 'Pickup Stop',
          value: bus.pickupStopName,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.person_rounded,
          label: 'Driver',
          value: bus.driverName ?? 'N/A',
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.child_care_rounded,
          label: 'Student',
          value: childName,
          color: const Color(0xFF8B5CF6),
        ),
        if (bus.updatedAt != null) ...[
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.update_rounded,
            label: 'Last Updated',
            value: _fmtDate(bus.updatedAt!),
            color: const Color(0xFFF59E0B),
          ),
        ],
      ]),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard.surface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: Radii.smRadius,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

// ── Live map ──────────────────────────────────────────────────────────────────

/// Wraps the map and drives a 15-second polling timer via [ParentCubit].
class _BusLiveMap extends StatefulWidget {
  final ParentBusModel bus;
  const _BusLiveMap({required this.bus});

  @override
  State<_BusLiveMap> createState() => _BusLiveMapState();
}

class _BusLiveMapState extends State<_BusLiveMap> {
  Timer? _timer;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Poll every 15 s so the dot updates without a manual pull-to-refresh.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) context.read<ParentCubit>().refreshBusLive();
    });
  }

  @override
  void didUpdateWidget(_BusLiveMap old) {
    super.didUpdateWidget(old);
    // Smoothly pan the camera when a new ping arrives.
    if (widget.bus.hasLocation &&
        (widget.bus.latitude != old.bus.latitude ||
            widget.bus.longitude != old.bus.longitude)) {
      _mapController.move(
        LatLng(widget.bus.latitude!, widget.bus.longitude!),
        15,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Live Location',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (widget.bus.hasLocation)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: Radii.pillRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Live',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AppCard.surface(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: Radii.mdRadius,
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: widget.bus.hasLocation
                    ? _MapView(bus: widget.bus, controller: _mapController)
                    : _NoLocation(cs: cs),
              ),
            ),
          ),
          if (widget.bus.hasLocation && widget.bus.updatedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Updated ${_relTime(widget.bus.updatedAt!)}  •  refreshes every 15 s',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  String _relTime(String iso) {
    try {
      final d = DateTime.parse(iso);
      final diff = DateTime.now().difference(d);
      if (diff.inSeconds < 60) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } catch (_) {
      return '';
    }
  }
}

// ── OpenStreetMap tile view with bus marker ───────────────────────────────────

class _MapView extends StatelessWidget {
  final ParentBusModel bus;
  final MapController controller;
  const _MapView({required this.bus, required this.controller});

  @override
  Widget build(BuildContext context) {
    final busPoint = LatLng(bus.latitude!, bus.longitude!);

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: busPoint,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        // OpenStreetMap tiles — free, no API key.
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.school.app',
          maxZoom: 19,
        ),

        // Bus marker
        MarkerLayer(
          markers: [
            Marker(
              point: busPoint,
              width: 48,
              height: 48,
              child: _BusMarker(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Animated pulsing bus marker.
class _BusMarker extends StatefulWidget {
  @override
  State<_BusMarker> createState() => _BusMarkerState();
}

class _BusMarkerState extends State<_BusMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _scale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple ring
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1)
                    .withValues(alpha: _opacity.value),
              ),
            ),
          ),
        ),
        // Solid bus pin
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }
}

// ── No-location state ─────────────────────────────────────────────────────────

class _NoLocation extends StatelessWidget {
  final ColorScheme cs;
  const _NoLocation({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_rounded, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            'Location unavailable',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'The driver may not have started the trip yet.',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
