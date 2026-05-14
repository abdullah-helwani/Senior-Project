import 'package:flutter/material.dart';

/// Semantic color tokens for the app. All consumed via [ThemeData.colorScheme]
/// or the [AppPalette] theme extension below — never reach into these constants
/// directly from screens. That way swapping the palette only requires editing
/// this file.
///
/// The accent ramps (`brand`, `success`, `warning`, `info`) are *not* part of
/// Material's `ColorScheme` because M3 only has primary/secondary/tertiary/error.
/// They live on the [AppPalette] extension and are accessed via
/// `Theme.of(context).extension<AppPalette>()!`.
class AppColors {
  AppColors._();

  // ── Brand — Polaris indigo-violet ────────────────────────────────────────
  static const seed = Color(0xFF6366F1);          // indigo-500
  static const seedDark = Color(0xFF818CF8);      // indigo-400 (lighter for dark surfaces)

  // ── Light scheme ─────────────────────────────────────────────────────────
  static const lightPrimary       = Color(0xFF4F46E5);   // Polaris --brand-primary
  static const lightOnPrimary     = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFEEF2FF); // Polaris --brand-primary-soft
  static const lightOnPrimaryContainer = Color(0xFF1E1B4B);

  static const lightSecondary     = Color(0xFF8B5CF6);   // violet-500 (Polaris role-teacher)
  static const lightOnSecondary   = Color(0xFFFFFFFF);
  static const lightSecondaryContainer = Color(0xFFF5F3FF);
  static const lightOnSecondaryContainer = Color(0xFF3B0764);

  static const lightTertiary      = Color(0xFF16A34A);   // Polaris --color-success
  static const lightOnTertiary    = Color(0xFFFFFFFF);
  static const lightTertiaryContainer = Color(0xFFDCFCE7); // Polaris --color-success-soft
  static const lightOnTertiaryContainer = Color(0xFF14532D);

  static const lightError         = Color(0xFFDC2626);   // Polaris --color-danger
  static const lightOnError       = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFEE2E2);  // Polaris --color-danger-soft
  static const lightOnErrorContainer = Color(0xFF7F1D1D);

  static const lightSurface       = Color(0xFFF5F7FB);   // Polaris --bg
  static const lightOnSurface     = Color(0xFF0F172A);   // Polaris --fg
  static const lightSurfaceDim    = Color(0xFFEEF0F4);   // Polaris --surface-sunken
  static const lightSurfaceBright = Color(0xFFFFFFFF);
  static const lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const lightSurfaceContainerLow    = Color(0xFFF7F7FB); // Polaris --surface-soft
  static const lightSurfaceContainer       = Color(0xFFF1F1F7);
  static const lightSurfaceContainerHigh   = Color(0xFFE9E9F1);
  static const lightSurfaceContainerHighest = Color(0xFFE3E3EC); // Polaris --outline
  static const lightOnSurfaceVariant = Color(0xFF475569);        // Polaris --fg-muted
  static const lightOutline        = Color(0xFFCBD5E1);          // Polaris --outline-strong
  static const lightOutlineVariant = Color(0xFFEEF0F4);          // Polaris --divider

  // ── Dark scheme — Polaris dark tokens ────────────────────────────────────
  static const darkPrimary        = Color(0xFF818CF8);   // Polaris dark --brand-primary
  static const darkOnPrimary      = Color(0xFF1E1B4B);
  static const darkPrimaryContainer = Color(0xFF373BAB);
  static const darkOnPrimaryContainer = Color(0xFFE4E4FE);

  static const darkSecondary      = Color(0xFFA78BFA);   // violet-400
  static const darkOnSecondary    = Color(0xFF3B0764);
  static const darkSecondaryContainer = Color(0xFF5B21B6);
  static const darkOnSecondaryContainer = Color(0xFFF5F3FF);

  static const darkTertiary       = Color(0xFF22C55E);   // Polaris dark --color-success
  static const darkOnTertiary     = Color(0xFF14532D);
  static const darkTertiaryContainer = Color(0xFF166534);
  static const darkOnTertiaryContainer = Color(0xFFDCFCE7);

  static const darkError          = Color(0xFFF87171);   // Polaris dark --color-danger
  static const darkOnError        = Color(0xFF7F1D1D);
  static const darkErrorContainer = Color(0xFF991B1B);
  static const darkOnErrorContainer = Color(0xFFFEE2E2);

  static const darkSurface        = Color(0xFF0F172A);   // Polaris --bg dark
  static const darkOnSurface      = Color(0xFFE2E8F0);   // Polaris dark --fg
  static const darkSurfaceDim     = Color(0xFF0B1324);   // Polaris --surface-sunken dark
  static const darkSurfaceBright  = Color(0xFF1E293B);
  static const darkSurfaceContainerLowest = Color(0xFF06080F);
  static const darkSurfaceContainerLow    = Color(0xFF12141C); // Polaris --surface-soft dark
  static const darkSurfaceContainer       = Color(0xFF1E293B); // Polaris --surface dark
  static const darkSurfaceContainerHigh   = Color(0xFF22242E);
  static const darkSurfaceContainerHighest = Color(0xFF334155); // Polaris dark --outline
  static const darkOnSurfaceVariant = Color(0xFF94A3B8);        // Polaris dark --fg-muted
  static const darkOutline        = Color(0xFF475569);          // Polaris dark --fg-subtle
  static const darkOutlineVariant = Color(0xFF334155);          // Polaris dark --divider

  // ── Semantic accents — Polaris tokens ────────────────────────────────────
  static const successLight = Color(0xFF16A34A);  // Polaris --color-success
  static const successDark  = Color(0xFF22C55E);  // Polaris dark --color-success
  static const warningLight = Color(0xFFF59E0B);  // Polaris --color-warning
  static const warningDark  = Color(0xFFFBBF24);  // Polaris dark --color-warning
  static const infoLight    = Color(0xFF0EA5E9);  // Polaris --color-info
  static const infoDark     = Color(0xFF38BDF8);  // Polaris dark --color-info

  // ── Role colors — Polaris role tokens ────────────────────────────────────
  static const roleStudent  = Color(0xFF3B82F6); // Polaris --role-student-start (blue-500)
  static const roleTeacher  = Color(0xFF8B5CF6); // Polaris --role-teacher-start (violet-500)
  static const roleParent   = Color(0xFF059669); // Polaris --role-parent-start (emerald-600)
  static const roleDriver   = Color(0xFFF59E0B); // Polaris --role-driver-start (amber-500)
  static const roleAdmin    = Color(0xFF4F46E5); // Polaris --brand-primary (indigo-600)
}

/// Theme extension that exposes the semantic accents not present on
/// [ColorScheme]. Read with `Theme.of(context).extension<AppPalette>()!`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Subtle gradient pair for hero cards / login background. `[start, end]`.
  final List<Color> brandGradient;

  const AppPalette({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.brandGradient,
  });

  static const light = AppPalette(
    success: AppColors.successLight,
    onSuccess: Colors.white,
    successContainer: Color(0xFFDCFCE7),  // Polaris --color-success-soft
    onSuccessContainer: Color(0xFF14532D),
    warning: AppColors.warningLight,
    onWarning: Colors.white,
    warningContainer: Color(0xFFFEF3C7),  // Polaris --color-warning-soft
    onWarningContainer: Color(0xFF78350F),
    info: AppColors.infoLight,
    onInfo: Colors.white,
    infoContainer: Color(0xFFE0F2FE),     // Polaris --color-info-soft
    onInfoContainer: Color(0xFF0C4A6E),
    brandGradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Polaris --brand-gradient
  );

  static const dark = AppPalette(
    success: AppColors.successDark,
    onSuccess: Color(0xFF14532D),
    successContainer: Color(0xFF166534),
    onSuccessContainer: Color(0xFFDCFCE7),
    warning: AppColors.warningDark,
    onWarning: Color(0xFF78350F),
    warningContainer: Color(0xFFB45309),
    onWarningContainer: Color(0xFFFEF3C7),
    info: AppColors.infoDark,
    onInfo: Color(0xFF0C4A6E),
    infoContainer: Color(0xFF0369A1),
    onInfoContainer: Color(0xFFE0F2FE),
    brandGradient: [Color(0xFF818CF8), Color(0xFFA5B4FC)], // Polaris dark brand gradient
  );

  @override
  AppPalette copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    List<Color>? brandGradient,
  }) =>
      AppPalette(
        success: success ?? this.success,
        onSuccess: onSuccess ?? this.onSuccess,
        successContainer: successContainer ?? this.successContainer,
        onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
        warning: warning ?? this.warning,
        onWarning: onWarning ?? this.onWarning,
        warningContainer: warningContainer ?? this.warningContainer,
        onWarningContainer: onWarningContainer ?? this.onWarningContainer,
        info: info ?? this.info,
        onInfo: onInfo ?? this.onInfo,
        infoContainer: infoContainer ?? this.infoContainer,
        onInfoContainer: onInfoContainer ?? this.onInfoContainer,
        brandGradient: brandGradient ?? this.brandGradient,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      brandGradient: [
        Color.lerp(brandGradient[0], other.brandGradient[0], t)!,
        Color.lerp(brandGradient[1], other.brandGradient[1], t)!,
      ],
    );
  }
}

/// Convenience extension so screens can write `context.palette.success`
/// instead of the verbose `Theme.of(context).extension<AppPalette>()!.success`.
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
