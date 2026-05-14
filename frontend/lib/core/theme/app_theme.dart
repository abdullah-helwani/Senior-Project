import 'package:first_try/core/theme/app_colors.dart';
import 'package:first_try/core/theme/app_motion.dart';
import 'package:first_try/core/theme/app_radius.dart';
import 'package:first_try/core/theme/app_typography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized [ThemeData] builder. Returns one for light, one for dark.
/// Both are kept in sync — when you tweak component theming, do it once here.
///
/// Convention: every screen reads colors from `Theme.of(context).colorScheme`
/// (or `context.palette` for our extension). No hex literals on screens.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(_lightScheme(), Brightness.light);
  static ThemeData dark()  => _build(_darkScheme(), Brightness.dark);

  // ── Color schemes ────────────────────────────────────────────────────────

  static ColorScheme _lightScheme() => const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        primaryContainer: AppColors.lightPrimaryContainer,
        onPrimaryContainer: AppColors.lightOnPrimaryContainer,
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightOnSecondary,
        secondaryContainer: AppColors.lightSecondaryContainer,
        onSecondaryContainer: AppColors.lightOnSecondaryContainer,
        tertiary: AppColors.lightTertiary,
        onTertiary: AppColors.lightOnTertiary,
        tertiaryContainer: AppColors.lightTertiaryContainer,
        onTertiaryContainer: AppColors.lightOnTertiaryContainer,
        error: AppColors.lightError,
        onError: AppColors.lightOnError,
        errorContainer: AppColors.lightErrorContainer,
        onErrorContainer: AppColors.lightOnErrorContainer,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        surfaceDim: AppColors.lightSurfaceDim,
        surfaceBright: AppColors.lightSurfaceBright,
        surfaceContainerLowest: AppColors.lightSurfaceContainerLowest,
        surfaceContainerLow: AppColors.lightSurfaceContainerLow,
        surfaceContainer: AppColors.lightSurfaceContainer,
        surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
        surfaceContainerHighest: AppColors.lightSurfaceContainerHighest,
        onSurfaceVariant: AppColors.lightOnSurfaceVariant,
        outline: AppColors.lightOutline,
        outlineVariant: AppColors.lightOutlineVariant,
        inverseSurface: AppColors.darkSurface,
        onInverseSurface: AppColors.darkOnSurface,
        inversePrimary: AppColors.darkPrimary,
        scrim: Colors.black54,
        shadow: Colors.black,
      );

  static ColorScheme _darkScheme() => const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        primaryContainer: AppColors.darkPrimaryContainer,
        onPrimaryContainer: AppColors.darkOnPrimaryContainer,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkOnSecondary,
        secondaryContainer: AppColors.darkSecondaryContainer,
        onSecondaryContainer: AppColors.darkOnSecondaryContainer,
        tertiary: AppColors.darkTertiary,
        onTertiary: AppColors.darkOnTertiary,
        tertiaryContainer: AppColors.darkTertiaryContainer,
        onTertiaryContainer: AppColors.darkOnTertiaryContainer,
        error: AppColors.darkError,
        onError: AppColors.darkOnError,
        errorContainer: AppColors.darkErrorContainer,
        onErrorContainer: AppColors.darkOnErrorContainer,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        surfaceDim: AppColors.darkSurfaceDim,
        surfaceBright: AppColors.darkSurfaceBright,
        surfaceContainerLowest: AppColors.darkSurfaceContainerLowest,
        surfaceContainerLow: AppColors.darkSurfaceContainerLow,
        surfaceContainer: AppColors.darkSurfaceContainer,
        surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
        surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        outline: AppColors.darkOutline,
        outlineVariant: AppColors.darkOutlineVariant,
        inverseSurface: AppColors.lightSurface,
        onInverseSurface: AppColors.lightOnSurface,
        inversePrimary: AppColors.lightPrimary,
        scrim: Colors.black87,
        shadow: Colors.black,
      );

  // ── Builder ──────────────────────────────────────────────────────────────

  static ThemeData _build(ColorScheme cs, Brightness brightness) {
    final baseTheme = ThemeData(brightness: brightness);
    final tt = AppTypography.googleFontsTextTheme(baseTheme.textTheme).copyWith(
      displayLarge:  AppTypography.googleFontsTextTheme(baseTheme.textTheme).displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
      displayMedium: AppTypography.googleFontsTextTheme(baseTheme.textTheme).displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
      displaySmall:  AppTypography.googleFontsTextTheme(baseTheme.textTheme).displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
      headlineLarge:  AppTypography.googleFontsTextTheme(baseTheme.textTheme).headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
      headlineMedium: AppTypography.googleFontsTextTheme(baseTheme.textTheme).headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      headlineSmall:  AppTypography.googleFontsTextTheme(baseTheme.textTheme).headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge:  AppTypography.googleFontsTextTheme(baseTheme.textTheme).titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: AppTypography.googleFontsTextTheme(baseTheme.textTheme).titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall:  AppTypography.googleFontsTextTheme(baseTheme.textTheme).titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge:   AppTypography.googleFontsTextTheme(baseTheme.textTheme).bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium:  AppTypography.googleFontsTextTheme(baseTheme.textTheme).bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      bodySmall:   AppTypography.googleFontsTextTheme(baseTheme.textTheme).bodySmall?.copyWith(fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
      labelLarge:  AppTypography.googleFontsTextTheme(baseTheme.textTheme).labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: AppTypography.googleFontsTextTheme(baseTheme.textTheme).labelMedium?.copyWith(fontWeight: FontWeight.w700),
      labelSmall:  AppTypography.googleFontsTextTheme(baseTheme.textTheme).labelSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant),
    ).apply(bodyColor: cs.onSurface, displayColor: cs.onSurface);
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      canvasColor: cs.surface,
      textTheme: tt,
      primaryTextTheme: tt,
      fontFamily: AppTypography.fontFamily,
      splashFactory:
          kIsWeb ? InkRipple.splashFactory : InkSparkle.splashFactory,
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        TargetPlatform.android: kIsWeb
            ? const ZoomPageTransitionsBuilder()
            : const PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: const ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: const ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: const ZoomPageTransitionsBuilder(),
      }),
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // ── App bar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // ── Cards ──────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: cs.surfaceContainerLow,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgRadius,
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),

      // ── Dividers ───────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── Buttons ────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: const RoundedRectangleBorder(borderRadius: Radii.mdRadius),
          textStyle: tt.labelLarge,
          animationDuration: Motion.fast,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: const RoundedRectangleBorder(borderRadius: Radii.mdRadius),
          textStyle: tt.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: const RoundedRectangleBorder(borderRadius: Radii.mdRadius),
          textStyle: tt.labelLarge,
          side: BorderSide(color: cs.outline),
          foregroundColor: cs.onSurface,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: tt.labelLarge,
          foregroundColor: cs.primary,
        ),
      ),

      // ── Inputs ─────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: Radii.mdRadius,
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.mdRadius,
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.mdRadius,
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.mdRadius,
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.mdRadius,
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        labelStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        prefixIconColor: cs.onSurfaceVariant,
        suffixIconColor: cs.onSurfaceVariant,
      ),

      // ── Chips ──────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        selectedColor: cs.primaryContainer,
        labelStyle: tt.labelMedium,
        secondaryLabelStyle: tt.labelMedium?.copyWith(color: cs.onPrimaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const RoundedRectangleBorder(borderRadius: Radii.pillRadius),
        side: BorderSide(color: cs.outlineVariant),
        showCheckmark: false,
      ),

      // ── Navigation bar (bottom) ────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tt.labelMedium?.copyWith(color: cs.onPrimaryContainer)
              : tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? IconThemeData(color: cs.onPrimaryContainer, size: 24)
              : IconThemeData(color: cs.onSurfaceVariant, size: 24),
        ),
      ),

      // ── Floating action button ─────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: Radii.lgRadius),
      ),

      // ── Bottom sheets ──────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.sheetTopRadius),
        showDragHandle: true,
      ),

      // ── Dialogs ────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.lgRadius),
        titleTextStyle: tt.titleLarge,
        contentTextStyle: tt.bodyMedium,
      ),

      // ── Snackbars ──────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.inverseSurface,
        contentTextStyle: tt.bodyMedium?.copyWith(color: cs.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.mdRadius),
        elevation: 4,
      ),

      // ── Tab bar ────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: tt.labelLarge,
        unselectedLabelStyle: tt.labelLarge,
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: cs.outlineVariant,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Switch / Checkbox / Radio ──────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.onPrimary : cs.outline),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? cs.primary
                : cs.surfaceContainerHigh),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(borderRadius: Radii.xsRadius),
        side: BorderSide(color: cs.outline, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.primary : cs.outline),
      ),

      // ── Progress indicators ────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        circularTrackColor: cs.surfaceContainerHigh,
        linearTrackColor: cs.surfaceContainerHigh,
      ),

      // ── List tile ──────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurfaceVariant,
        textColor: cs.onSurface,
        titleTextStyle: tt.titleSmall,
        subtitleTextStyle: tt.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── Extensions ─────────────────────────────────────────────────────
      extensions: <ThemeExtension<dynamic>>[
        isDark ? AppPalette.dark : AppPalette.light,
      ],
    );
  }
}
