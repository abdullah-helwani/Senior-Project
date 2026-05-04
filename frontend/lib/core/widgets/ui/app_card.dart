import 'dart:ui';

import 'package:first_try/core/theme/app_colors.dart';
import 'package:first_try/core/theme/app_elevation.dart';
import 'package:first_try/core/theme/app_motion.dart';
import 'package:first_try/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

/// Three card variants share one widget so usage is uniform:
///
/// - `AppCard.surface(...)` — outlined, neutral background. Default everywhere.
/// - `AppCard.filled(...)` — tinted background, no outline. Use for groupings.
/// - `AppCard.glass(...)` — gradient + frosted blur. Save for hero / promo.
///
/// All variants animate press feedback and accept an `onTap` callback so a
/// caller can use them as buttons without wrapping in InkWell themselves.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final VoidCallback? onTap;

  /// Internal — chosen by the named constructors below.
  final _CardStyle _style;
  final Color? _customColor;
  final List<Color>? _gradient;
  final double _gradientOpacity;

  const AppCard.surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = Radii.lgRadius,
    this.onTap,
  })  : _style = _CardStyle.surface,
        _customColor = null,
        _gradient = null,
        _gradientOpacity = 1;

  const AppCard.filled({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = Radii.lgRadius,
    this.onTap,
    Color? color,
  })  : _style = _CardStyle.filled,
        _customColor = color,
        _gradient = null,
        _gradientOpacity = 1;

  /// `gradient` defaults to the brand gradient from [AppPalette].
  /// `opacity` controls how strong the gradient overlay reads (0..1).
  const AppCard.glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = Radii.xlRadius,
    this.onTap,
    List<Color>? gradient,
    double opacity = 0.85,
  })  : _style = _CardStyle.glass,
        _customColor = null,
        _gradient = gradient,
        _gradientOpacity = opacity;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    final BoxDecoration deco = switch (widget._style) {
      _CardStyle.surface => BoxDecoration(
          color: cs.surface,
          borderRadius: widget.radius,
          border: Border.all(color: cs.outlineVariant),
          boxShadow: AppShadows.cardFor(Theme.of(context).brightness),
        ),
      _CardStyle.filled => BoxDecoration(
          color: widget._customColor ?? cs.surfaceContainerLow,
          borderRadius: widget.radius,
        ),
      _CardStyle.glass => BoxDecoration(
          borderRadius: widget.radius,
          gradient: LinearGradient(
            colors: (widget._gradient ?? palette.brandGradient)
                .map((c) => c.withValues(alpha: widget._gradientOpacity))
                .toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: AppShadows.hoverFor(Theme.of(context).brightness),
        ),
    };

    Widget content = AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.standard,
      decoration: deco,
      transform: Matrix4.identity()
        ..scaleByDouble(
          _pressed ? 0.985 : 1.0,
          _pressed ? 0.985 : 1.0,
          1,
          1,
        ),
      transformAlignment: Alignment.center,
      child: ClipRRect(
        borderRadius: widget.radius,
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );

    if (widget._style == _CardStyle.glass) {
      // Frosted blur underneath the gradient overlay. Wrapped in BackdropFilter
      // for a subtle "glass" feel — works on web/mobile alike.
      content = ClipRRect(
        borderRadius: widget.radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: content,
        ),
      );
    }

    if (widget.onTap == null) return content;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

enum _CardStyle { surface, filled, glass }
