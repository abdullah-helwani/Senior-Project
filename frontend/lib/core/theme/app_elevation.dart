import 'package:flutter/material.dart';

/// Soft, layered shadow recipes. Material 3's default elevations are too dark
/// for our cool surfaces — these are tuned to read as "lifted" without looking
/// inky. Apply via `boxShadow: AppShadows.card`.
///
/// All shadows are intentionally cool-tinted (slight indigo) on light themes
/// to harmonize with the brand palette. Pass `dark: true` for dark-mode
/// variants.
class AppShadows {
  AppShadows._();

  // ── Light theme shadows ──────────────────────────────────────────────────
  /// Resting elevation for tiles and small cards.
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x10131A33), // ~6% indigo-tinted black
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0x08131A33),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Hovering elevation for hero / focused surfaces.
  static const hover = <BoxShadow>[
    BoxShadow(
      color: Color(0x18131A33),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
    BoxShadow(
      color: Color(0x0C131A33),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  /// For floating elements (FABs, dropdowns, popovers).
  static const popover = <BoxShadow>[
    BoxShadow(
      color: Color(0x22131A33),
      offset: Offset(0, 12),
      blurRadius: 32,
    ),
  ];

  // ── Dark theme shadows ───────────────────────────────────────────────────
  /// Subtler, mostly used for outline/luminance separation rather than depth.
  static const cardDark = <BoxShadow>[
    BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const hoverDark = <BoxShadow>[
    BoxShadow(
      color: Color(0x60000000),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  static const popoverDark = <BoxShadow>[
    BoxShadow(
      color: Color(0x80000000),
      offset: Offset(0, 12),
      blurRadius: 32,
    ),
  ];

  /// Picks the right shadow set for the current brightness.
  static List<BoxShadow> cardFor(Brightness b) =>
      b == Brightness.dark ? cardDark : card;
  static List<BoxShadow> hoverFor(Brightness b) =>
      b == Brightness.dark ? hoverDark : hover;
  static List<BoxShadow> popoverFor(Brightness b) =>
      b == Brightness.dark ? popoverDark : popover;
}
