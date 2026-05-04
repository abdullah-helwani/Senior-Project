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

  // ── Brand ────────────────────────────────────────────────────────────────
  // Indigo-violet: friendly but serious. Works for an education product.
  static const seed = Color(0xFF6366F1);          // indigo-500
  static const seedDark = Color(0xFF818CF8);      // indigo-400 (lighter for dark surfaces)

  // ── Light scheme ─────────────────────────────────────────────────────────
  static const lightPrimary       = Color(0xFF5B5FCF);
  static const lightOnPrimary     = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFE4E4FE);
  static const lightOnPrimaryContainer = Color(0xFF1E1B4B);

  static const lightSecondary     = Color(0xFFEC4899);   // pink-500
  static const lightOnSecondary   = Color(0xFFFFFFFF);
  static const lightSecondaryContainer = Color(0xFFFCE7F3);
  static const lightOnSecondaryContainer = Color(0xFF500724);

  static const lightTertiary      = Color(0xFF10B981);   // emerald-500
  static const lightOnTertiary    = Color(0xFFFFFFFF);
  static const lightTertiaryContainer = Color(0xFFD1FAE5);
  static const lightOnTertiaryContainer = Color(0xFF064E3B);

  static const lightError         = Color(0xFFE11D48);   // rose-600
  static const lightOnError       = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFE4E6);
  static const lightOnErrorContainer = Color(0xFF4C0519);

  static const lightSurface       = Color(0xFFFAFAFB);
  static const lightOnSurface     = Color(0xFF11131A);
  static const lightSurfaceDim    = Color(0xFFEDEDF2);
  static const lightSurfaceBright = Color(0xFFFFFFFF);
  static const lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const lightSurfaceContainerLow    = Color(0xFFF7F7FB);
  static const lightSurfaceContainer       = Color(0xFFF1F1F7);
  static const lightSurfaceContainerHigh   = Color(0xFFE9E9F1);
  static const lightSurfaceContainerHighest = Color(0xFFE2E2EC);
  static const lightOnSurfaceVariant = Color(0xFF565869);
  static const lightOutline        = Color(0xFFB6B7C6);
  static const lightOutlineVariant = Color(0xFFE3E3EC);

  // ── Dark scheme ──────────────────────────────────────────────────────────
  static const darkPrimary        = Color(0xFFA5A8FF);
  static const darkOnPrimary      = Color(0xFF1E1B4B);
  static const darkPrimaryContainer = Color(0xFF373BAB);
  static const darkOnPrimaryContainer = Color(0xFFE4E4FE);

  static const darkSecondary      = Color(0xFFF9A8D4);
  static const darkOnSecondary    = Color(0xFF500724);
  static const darkSecondaryContainer = Color(0xFFA61653);
  static const darkOnSecondaryContainer = Color(0xFFFCE7F3);

  static const darkTertiary       = Color(0xFF6EE7B7);
  static const darkOnTertiary     = Color(0xFF064E3B);
  static const darkTertiaryContainer = Color(0xFF047857);
  static const darkOnTertiaryContainer = Color(0xFFD1FAE5);

  static const darkError          = Color(0xFFFCA5A5);
  static const darkOnError        = Color(0xFF4C0519);
  static const darkErrorContainer = Color(0xFF9F1239);
  static const darkOnErrorContainer = Color(0xFFFFE4E6);

  static const darkSurface        = Color(0xFF0B0D14);
  static const darkOnSurface      = Color(0xFFE6E6F0);
  static const darkSurfaceDim     = Color(0xFF080A11);
  static const darkSurfaceBright  = Color(0xFF24262F);
  static const darkSurfaceContainerLowest = Color(0xFF06080F);
  static const darkSurfaceContainerLow    = Color(0xFF12141C);
  static const darkSurfaceContainer       = Color(0xFF181A23);
  static const darkSurfaceContainerHigh   = Color(0xFF22242E);
  static const darkSurfaceContainerHighest = Color(0xFF2D2F3A);
  static const darkOnSurfaceVariant = Color(0xFFA8AABB);
  static const darkOutline        = Color(0xFF6B6D7E);
  static const darkOutlineVariant = Color(0xFF353742);

  // ── Semantic accents (live on AppPalette extension) ──────────────────────
  static const successLight = Color(0xFF10B981);
  static const successDark  = Color(0xFF34D399);
  static const warningLight = Color(0xFFF59E0B);
  static const warningDark  = Color(0xFFFBBF24);
  static const infoLight    = Color(0xFF0EA5E9);
  static const infoDark     = Color(0xFF38BDF8);

  // ── Role colors (parent / teacher / student / driver dashboards) ─────────
  // Used for tinting role-specific home cards / role badges in the More grid.
  static const roleStudent  = Color(0xFF3B82F6); // blue-500
  static const roleTeacher  = Color(0xFF8B5CF6); // violet-500
  static const roleParent   = Color(0xFFEC4899); // pink-500
  static const roleDriver   = Color(0xFFF59E0B); // amber-500
  static const roleAdmin    = Color(0xFF14B8A6); // teal-500
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
    successContainer: Color(0xFFD1FAE5),
    onSuccessContainer: Color(0xFF064E3B),
    warning: AppColors.warningLight,
    onWarning: Colors.white,
    warningContainer: Color(0xFFFEF3C7),
    onWarningContainer: Color(0xFF78350F),
    info: AppColors.infoLight,
    onInfo: Colors.white,
    infoContainer: Color(0xFFE0F2FE),
    onInfoContainer: Color(0xFF0C4A6E),
    brandGradient: [Color(0xFF6366F1), Color(0xFFEC4899)],
  );

  static const dark = AppPalette(
    success: AppColors.successDark,
    onSuccess: Color(0xFF064E3B),
    successContainer: Color(0xFF047857),
    onSuccessContainer: Color(0xFFD1FAE5),
    warning: AppColors.warningDark,
    onWarning: Color(0xFF78350F),
    warningContainer: Color(0xFFB45309),
    onWarningContainer: Color(0xFFFEF3C7),
    info: AppColors.infoDark,
    onInfo: Color(0xFF0C4A6E),
    infoContainer: Color(0xFF0369A1),
    onInfoContainer: Color(0xFFE0F2FE),
    brandGradient: [Color(0xFF818CF8), Color(0xFFF472B6)],
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
