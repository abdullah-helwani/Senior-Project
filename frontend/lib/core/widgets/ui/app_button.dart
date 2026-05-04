import 'package:first_try/core/theme/app_motion.dart';
import 'package:first_try/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

/// Unified button wrappers with consistent sizing, icon placement, and a
/// built-in busy state. Five variants:
///
/// - `AppButton.primary(...)` — filled, high-emphasis (FilledButton).
/// - `AppButton.secondary(...)` — tonal (FilledButton.tonal).
/// - `AppButton.outlined(...)` — outline, medium emphasis.
/// - `AppButton.ghost(...)` — text-only, lowest emphasis.
/// - `AppButton.danger(...)` — destructive, error-toned filled button.
///
/// All accept `loading: true` to show a spinner and disable the button.
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final AppButtonSize size;
  final bool fullWidth;
  final _AppButtonStyle _style;

  const AppButton.primary({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.loading = false,
    this.size = AppButtonSize.md,
    this.fullWidth = false,
  }) : _style = _AppButtonStyle.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.loading = false,
    this.size = AppButtonSize.md,
    this.fullWidth = false,
  }) : _style = _AppButtonStyle.secondary;

  const AppButton.outlined({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.loading = false,
    this.size = AppButtonSize.md,
    this.fullWidth = false,
  }) : _style = _AppButtonStyle.outlined;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.loading = false,
    this.size = AppButtonSize.md,
    this.fullWidth = false,
  }) : _style = _AppButtonStyle.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.loading = false,
    this.size = AppButtonSize.md,
    this.fullWidth = false,
  }) : _style = _AppButtonStyle.danger;

  double get _height => switch (size) {
        AppButtonSize.sm => 36,
        AppButtonSize.md => 48,
        AppButtonSize.lg => 56,
      };

  EdgeInsetsGeometry get _padding => switch (size) {
        AppButtonSize.sm => const EdgeInsets.symmetric(horizontal: 14),
        AppButtonSize.md => const EdgeInsets.symmetric(horizontal: 20),
        AppButtonSize.lg => const EdgeInsets.symmetric(horizontal: 24),
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onPressed == null || loading;

    final child = AnimatedSwitcher(
      duration: Motion.fast,
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: _foregroundFor(cs),
              ),
            )
          : _LabelRow(
              key: const ValueKey('label'),
              label: label,
              icon: icon,
              size: size,
            ),
    );

    final shape = const RoundedRectangleBorder(borderRadius: Radii.mdRadius);
    final commonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, _height)),
      padding: WidgetStatePropertyAll(_padding),
      shape: WidgetStatePropertyAll(shape),
      animationDuration: Motion.fast,
    );

    Widget button;
    switch (_style) {
      case _AppButtonStyle.primary:
        button = FilledButton(
          style: commonStyle,
          onPressed: disabled ? null : onPressed,
          child: child,
        );
        break;
      case _AppButtonStyle.secondary:
        button = FilledButton.tonal(
          style: commonStyle,
          onPressed: disabled ? null : onPressed,
          child: child,
        );
        break;
      case _AppButtonStyle.outlined:
        button = OutlinedButton(
          style: commonStyle,
          onPressed: disabled ? null : onPressed,
          child: child,
        );
        break;
      case _AppButtonStyle.ghost:
        button = TextButton(
          style: commonStyle,
          onPressed: disabled ? null : onPressed,
          child: child,
        );
        break;
      case _AppButtonStyle.danger:
        button = FilledButton(
          style: commonStyle.merge(
            ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(cs.error),
              foregroundColor: WidgetStatePropertyAll(cs.onError),
            ),
          ),
          onPressed: disabled ? null : onPressed,
          child: child,
        );
        break;
    }

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Color _foregroundFor(ColorScheme cs) => switch (_style) {
        _AppButtonStyle.primary => cs.onPrimary,
        _AppButtonStyle.secondary => cs.onSecondaryContainer,
        _AppButtonStyle.outlined => cs.onSurface,
        _AppButtonStyle.ghost => cs.primary,
        _AppButtonStyle.danger => cs.onError,
      };
}

class _LabelRow extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppButtonSize size;
  const _LabelRow({super.key, required this.label, this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    final iconSize = switch (size) {
      AppButtonSize.sm => 16.0,
      AppButtonSize.md => 18.0,
      AppButtonSize.lg => 20.0,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

enum _AppButtonStyle { primary, secondary, outlined, ghost, danger }
