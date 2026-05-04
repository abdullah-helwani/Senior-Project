import 'package:first_try/core/theme/app_motion.dart';
import 'package:first_try/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

/// Animated shimmer placeholder. Cheap to lay out and matches our radius
/// scale by default. Use these instead of plain spinners when you know the
/// shape of the content that's loading.
///
/// ```
/// Skeleton.box(width: 120, height: 16)
/// Skeleton.text(lines: 3)
/// Skeleton.circle(size: 44)
/// Skeleton.card(height: 80)
/// ```
class Skeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius radius;
  final ShapeBorder? shape;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.radius = Radii.smRadius,
    this.shape,
  });

  /// Rectangle, common for text-runs and inline placeholders.
  factory Skeleton.box({
    Key? key,
    double? width,
    double height = 14,
    BorderRadius radius = Radii.smRadius,
  }) =>
      Skeleton(key: key, width: width, height: height, radius: radius);

  factory Skeleton.circle({Key? key, double size = 44}) =>
      Skeleton(
        key: key,
        width: size,
        height: size,
        radius: Radii.pillRadius,
      );

  /// Card-sized placeholder that matches `AppCard.surface` dimensions.
  factory Skeleton.card({Key? key, double height = 80}) =>
      Skeleton(
        key: key,
        height: height,
        radius: Radii.lgRadius,
      );

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (context, _) {
          // Sweep a brighter band across a darker base for the shimmer effect.
          return DecoratedBox(
            decoration: ShapeDecoration(
              shape: widget.shape ??
                  RoundedRectangleBorder(borderRadius: widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1.0 + (_ctl.value * 2.4), 0),
                end: Alignment(1.0 + (_ctl.value * 2.4), 0),
                colors: [
                  cs.surfaceContainerHigh,
                  cs.surfaceContainerHighest,
                  cs.surfaceContainerHigh,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Multi-line text skeleton. Use when you don't know the exact wrap point.
class TextSkeleton extends StatelessWidget {
  final int lines;
  final double height;
  final double spacing;

  /// 0..1 — last line is rendered at this fraction of full width to mimic
  /// natural text wrapping.
  final double lastLineRatio;

  const TextSkeleton({
    super.key,
    this.lines = 3,
    this.height = 12,
    this.spacing = 8,
    this.lastLineRatio = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (i) {
        final isLast = i == lines - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: isLast ? lastLineRatio : 1,
            child: Skeleton.box(height: height),
          ),
        );
      }),
    );
  }
}

/// Standard tile skeleton for list rows: circle avatar + 2 lines of text.
class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Skeleton.circle(size: 44),
          const SizedBox(width: 12),
          const Expanded(
            child: TextSkeleton(lines: 2, lastLineRatio: 0.4),
          ),
        ],
      ),
    );
  }
}

/// Convenience animated fade between a skeleton and the real content.
/// Wrap your loading branch in this for graceful transitions.
class SkeletonSwitcher extends StatelessWidget {
  final bool isLoading;
  final Widget skeleton;
  final Widget child;

  const SkeletonSwitcher({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.medium,
      switchInCurve: Motion.standard,
      switchOutCurve: Motion.standard,
      child: isLoading
          ? KeyedSubtree(key: const ValueKey('skel'), child: skeleton)
          : KeyedSubtree(key: const ValueKey('content'), child: child),
    );
  }
}
