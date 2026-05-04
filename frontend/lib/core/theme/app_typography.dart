import 'package:flutter/material.dart';

/// Typography scale — a refined Material 3 hierarchy with our preferred
/// weights, letter spacing and font family.
///
/// We use system sans-serif (`SF Pro` on iOS, `Roboto` on Android, system
/// default on web) by default to avoid a font-loading dependency. To swap to
/// a custom font (e.g. Plus Jakarta Sans via google_fonts), change [fontFamily]
/// to the family name and call `GoogleFonts.config.allowRuntimeFetching = true`
/// at app start.
class AppTypography {
  AppTypography._();

  /// `null` = use system default (Roboto / SF Pro). Set to a string like
  /// `'PlusJakartaSans'` after wiring google_fonts.
  static const String? fontFamily = null;

  /// Builds the [TextTheme] for a given color. `onSurface` is the default
  /// text color; helpers downstream override this for variants.
  static TextTheme build({required Color onSurface, required Color onSurfaceVariant}) {
    TextStyle base(double size, FontWeight w, double lh, {double letterSpacing = 0, Color? color}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: w,
          height: lh / size,
          letterSpacing: letterSpacing,
          color: color ?? onSurface,
        );

    return TextTheme(
      // Display — splash, marketing-style headlines. Rare in-app.
      displayLarge:  base(48, FontWeight.w800, 56, letterSpacing: -0.8),
      displayMedium: base(40, FontWeight.w800, 48, letterSpacing: -0.6),
      displaySmall:  base(32, FontWeight.w800, 40, letterSpacing: -0.4),

      // Headline — page titles, hero greetings.
      headlineLarge:  base(28, FontWeight.w800, 36, letterSpacing: -0.4),
      headlineMedium: base(24, FontWeight.w700, 32, letterSpacing: -0.2),
      headlineSmall:  base(20, FontWeight.w700, 28),

      // Title — card titles, section headers.
      titleLarge:  base(18, FontWeight.w700, 24),
      titleMedium: base(16, FontWeight.w700, 22, letterSpacing: 0.1),
      titleSmall:  base(14, FontWeight.w600, 20, letterSpacing: 0.1),

      // Body — primary reading copy.
      bodyLarge:   base(16, FontWeight.w500, 24, letterSpacing: 0.15),
      bodyMedium:  base(14, FontWeight.w500, 20, letterSpacing: 0.15),
      bodySmall:   base(12, FontWeight.w500, 16, letterSpacing: 0.2, color: onSurfaceVariant),

      // Label — buttons, chips, captions, tab labels.
      labelLarge:  base(14, FontWeight.w700, 20, letterSpacing: 0.4),
      labelMedium: base(12, FontWeight.w700, 16, letterSpacing: 0.5),
      labelSmall:  base(11, FontWeight.w700, 14, letterSpacing: 0.6, color: onSurfaceVariant),
    );
  }
}

/// Convenience accessors for common one-off styles. Prefer the textTheme
/// (`Theme.of(context).textTheme.titleMedium`) when possible — these helpers
/// are for very specific UI bits.
extension TextStyleHelpers on BuildContext {
  TextStyle? get heroGreeting =>
      Theme.of(this).textTheme.headlineLarge?.copyWith(letterSpacing: -0.5);

  TextStyle? get heroSubtitle =>
      Theme.of(this).textTheme.bodyMedium?.copyWith(
            color: Theme.of(this).colorScheme.onSurfaceVariant,
          );

  TextStyle? get statValue =>
      Theme.of(this).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800);

  TextStyle? get statLabel =>
      Theme.of(this).textTheme.labelMedium?.copyWith(
            color: Theme.of(this).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          );
}
