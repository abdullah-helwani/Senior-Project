import 'package:first_try/core/theme/app_colors.dart';
import 'package:first_try/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

/// Small "pill"-shaped tag for status, labels, or read-only badges.
///
/// Pass a tone (`StatusTone.success`/`warning`/`error`/`info`/`neutral`) for a
/// pre-themed look, or a custom `color` for one-offs.
enum StatusTone { primary, success, warning, error, info, neutral }

class StatusPill extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;
  final Color? color; // Override tone with a custom hue.
  final bool dense;

  const StatusPill({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.color,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    final base = color ?? switch (tone) {
      StatusTone.primary => cs.primary,
      StatusTone.success => palette.success,
      StatusTone.warning => palette.warning,
      StatusTone.error   => cs.error,
      StatusTone.info    => palette.info,
      StatusTone.neutral => cs.onSurfaceVariant,
    };

    final padH = dense ? 8.0 : 10.0;
    final padV = dense ? 3.0 : 5.0;
    final iconSize = dense ? 11.0 : 13.0;
    final fontSize = dense ? 10.0 : 11.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.12),
        borderRadius: Radii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: base),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: base,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable filter chip — wraps Material's [ChoiceChip] with our pill shape.
/// Use in horizontal-scrolling filter rows.
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;

  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

/// Avatar-sized circular badge for role labels (parent / teacher / student /
/// driver / admin). Uses [AppColors.role*] tones from the design system.
class RoleBadge extends StatelessWidget {
  final String role;
  final double size;

  const RoleBadge({super.key, required this.role, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(role);
    final initial = role.isNotEmpty ? role[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _colorFor(String role) => switch (role.toLowerCase()) {
        'student' => AppColors.roleStudent,
        'teacher' => AppColors.roleTeacher,
        'parent'  => AppColors.roleParent,
        'driver'  => AppColors.roleDriver,
        'admin'   => AppColors.roleAdmin,
        _         => Colors.grey,
      };
}
