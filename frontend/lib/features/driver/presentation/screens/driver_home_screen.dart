import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// Driver role gradient: amber → orange
const _kHeroGradient = [Color(0xFFF59E0B), Color(0xFFEF4444)];

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // ── Gradient hero ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: GradientHero(
              greeting: 'Good ${_greeting()}, Driver',
              subtitle: DateFormat('EEEE, d MMMM').format(DateTime.now()),
              colors: _kHeroGradient,
              trailing: GestureDetector(
                onTap: () => context.read<AuthCubit>().logout(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: Radii.mdRadius,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30), width: 1),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),

          // ── Status card ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: AppCard.glass(
                gradient: _kHeroGradient,
                opacity: 0.90,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: Radii.lgRadius,
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ready for today's route",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your route details will appear here.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Coming soon section ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: SectionHeader(title: 'Features'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _FeatureTile(
                  icon: Icons.map_rounded,
                  label: 'Route Map',
                  color: const Color(0xFFF59E0B),
                  subtitle: 'Coming soon',
                ),
                _FeatureTile(
                  icon: Icons.people_rounded,
                  label: 'Students',
                  color: const Color(0xFFEF4444),
                  subtitle: 'Coming soon',
                ),
                _FeatureTile(
                  icon: Icons.notifications_rounded,
                  label: 'Alerts',
                  color: const Color(0xFF3B82F6),
                  subtitle: 'Coming soon',
                ),
                _FeatureTile(
                  icon: Icons.history_rounded,
                  label: 'Trip History',
                  color: const Color(0xFF10B981),
                  subtitle: 'Coming soon',
                ),
              ],
            ),
          ),

          // ── Bottom safe-area spacer ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) => SizedBox(
                height: MediaQuery.of(context).padding.bottom + 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard.filled(
      color: color.withValues(alpha: 0.10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: Radii.smRadius,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color.withValues(alpha: 0.70),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
