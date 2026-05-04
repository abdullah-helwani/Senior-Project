import 'package:first_try/core/theme/app_radius.dart';
import 'package:first_try/core/widgets/ui/skeleton.dart';
import 'package:flutter/material.dart';

// ── Dashboard / home skeleton ─────────────────────────────────────────────────

/// Hero card + stat row + section header + list of card rows.
/// Used by student / teacher / parent home screens.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Hero glass card
        Skeleton.card(height: 148),
        const SizedBox(height: 16),
        // Quick-stat row (3 tiles)
        Row(children: [
          Expanded(child: Skeleton.card(height: 84)),
          const SizedBox(width: 12),
          Expanded(child: Skeleton.card(height: 84)),
          const SizedBox(width: 12),
          Expanded(child: Skeleton.card(height: 84)),
        ]),
        const SizedBox(height: 20),
        // Section title
        Skeleton.box(width: 120, height: 14),
        const SizedBox(height: 12),
        // Card list
        Skeleton.card(height: 76),
        const SizedBox(height: 10),
        Skeleton.card(height: 76),
        const SizedBox(height: 10),
        Skeleton.card(height: 76),
        const SizedBox(height: 20),
        // Second section
        Skeleton.box(width: 100, height: 14),
        const SizedBox(height: 12),
        Skeleton.card(height: 76),
        const SizedBox(height: 10),
        Skeleton.card(height: 76),
      ],
    );
  }
}

// ── Card-list skeleton ────────────────────────────────────────────────────────

/// Optional filter pill row + N card rows.
/// Used by notifications, homework, attendance, classes, complaints, payments.
class CardListSkeleton extends StatelessWidget {
  final int count;
  final bool showFilter;
  final bool showHeader;
  final double cardHeight;

  const CardListSkeleton({
    super.key,
    this.count = 5,
    this.showFilter = false,
    this.showHeader = false,
    this.cardHeight = 88,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (showHeader) ...[
          Skeleton.box(width: 140, height: 16),
          const SizedBox(height: 12),
        ],
        if (showFilter) ...[
          Row(children: [
            Skeleton.box(width: 72, height: 32, radius: Radii.pillRadius),
            const SizedBox(width: 8),
            Skeleton.box(width: 72, height: 32, radius: Radii.pillRadius),
            const SizedBox(width: 8),
            Skeleton.box(width: 72, height: 32, radius: Radii.pillRadius),
          ]),
          const SizedBox(height: 16),
        ],
        for (var i = 0; i < count; i++) ...[
          Skeleton.card(height: cardHeight),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// ── Profile skeleton ──────────────────────────────────────────────────────────

/// Avatar + name + info section cards + action buttons.
/// Used by student / teacher / driver profile screens.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Avatar + name
        Center(
          child: Column(children: [
            Skeleton.circle(size: 88),
            const SizedBox(height: 12),
            Skeleton.box(width: 160, height: 18),
            const SizedBox(height: 8),
            Skeleton.box(width: 110, height: 13),
            const SizedBox(height: 8),
            Skeleton.box(width: 90, height: 28, radius: Radii.pillRadius),
          ]),
        ),
        const SizedBox(height: 28),
        // Info section 1
        Skeleton.card(height: 170),
        const SizedBox(height: 12),
        // Info section 2
        Skeleton.card(height: 100),
        const SizedBox(height: 24),
        // Action buttons
        Skeleton.box(height: 48, radius: Radii.mdRadius),
        const SizedBox(height: 12),
        Skeleton.box(height: 48, radius: Radii.mdRadius),
      ],
    );
  }
}

// ── Tab-body skeleton ─────────────────────────────────────────────────────────

/// Used inside a tab screen as the loading placeholder for each tab.
class TabBodySkeleton extends StatelessWidget {
  const TabBodySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const CardListSkeleton(count: 4, cardHeight: 80);
  }
}
