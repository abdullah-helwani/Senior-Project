import 'package:first_try/features/parent/data/models/parent_models.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ParentBusScreen extends StatelessWidget {
  const ParentBusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus Tracking')),
      body: BlocBuilder<ParentCubit, ParentState>(
        builder: (context, state) {
          if (state is! ParentLoaded) return const SizedBox.shrink();

          final busData = state.bus[state.selectedChildId];
          final childName = state.selectedChild.name.split(' ').first;

          return RefreshIndicator(
            onRefresh: () => context.read<ParentCubit>().load(),
            child: CustomScrollView(
              slivers: [
                // Child selector tabs
                SliverToBoxAdapter(
                  child: _ChildTabBar(
                    children: state.profile.children,
                    selectedIndex: state.selectedChildIndex,
                    onSelect: (i) => context.read<ParentCubit>().selectChild(i),
                  ),
                ),

                if (busData == null) ...[
                  SliverFillRemaining(
                    child: Center(
                      child: Text('No bus assigned for $childName.',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                  ),
                ] else ...[
                  SliverToBoxAdapter(child: _BusStatusCard(bus: busData)),
                  SliverToBoxAdapter(child: _BusInfoSection(bus: busData, childName: childName)),
                  SliverToBoxAdapter(child: _BusMapPlaceholder(bus: busData)),
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

// ── Widgets ───────────────────────────────────────────────────────────────────

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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: List.generate(children.length, (i) {
          final child = children[i];
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                margin: EdgeInsets.only(right: i < children.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: selected ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  child.name.split(' ').first,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BusStatusCard extends StatelessWidget {
  final ParentBusModel bus;
  const _BusStatusCard({required this.bus});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: cs.onPrimary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.directions_bus_rounded, color: cs.onPrimary, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(bus.busPlate,
                style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text(bus.routeName,
                style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.85), fontSize: 13)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade400,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Container(
              width: 7, height: 7,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            const Text('Active', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

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
          color: Colors.green.shade600,
        ),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.person_rounded,
          label: 'Driver',
          value: bus.driverName ?? 'N/A',
          color: Colors.blue.shade600,
        ),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.child_care_rounded,
          label: 'Student',
          value: childName,
          color: Colors.purple.shade600,
        ),
        if (bus.updatedAt != null) ...[
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.update_rounded,
            label: 'Last Updated',
            value: _fmtDate(bus.updatedAt!),
            color: Colors.orange.shade600,
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

class _BusMapPlaceholder extends StatelessWidget {
  final ParentBusModel bus;
  const _BusMapPlaceholder({required this.bus});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Live Location',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Center(
            child: bus.hasLocation
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.location_on_rounded, size: 48, color: cs.primary),
                    const SizedBox(height: 8),
                    Text(
                      '${bus.latitude!.toStringAsFixed(4)}, ${bus.longitude!.toStringAsFixed(4)}',
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('Map integration not available in demo',
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ])
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.location_off_rounded, size: 48, color: cs.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text('Location unavailable',
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  ]),
          ),
        ),
      ]),
    );
  }
}
