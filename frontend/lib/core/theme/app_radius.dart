import 'package:flutter/material.dart';

/// Corner radius scale. Use [Radii] constants instead of `BorderRadius.circular(16)`
/// scattered across the codebase.
///
/// Convention: `sm` for chips/pills, `md` for inputs/tiles, `lg` for cards,
/// `xl` for sheets and hero surfaces, `pill` for fully rounded.
/// Corner radius scale matching the Polaris School Design System.
/// xs=6, sm=8, md=10, lg=12, xl=20, xxl=28, pill=999
class Radii {
  Radii._();

  static const double xs   = 6;   // Polaris --radius-xs
  static const double sm   = 8;   // Polaris --radius-sm  (button, input)
  static const double md   = 10;  // Polaris --radius-md  (tile)
  static const double lg   = 12;  // Polaris --radius-lg  (card)
  static const double xl   = 20;  // Polaris --radius-xl
  static const double xxl  = 28;  // Polaris --radius-2xl (hero, sheet top)
  static const double pill = 999; // Polaris --radius-pill

  static const xsRadius   = BorderRadius.all(Radius.circular(xs));
  static const smRadius   = BorderRadius.all(Radius.circular(sm));
  static const mdRadius   = BorderRadius.all(Radius.circular(md));
  static const lgRadius   = BorderRadius.all(Radius.circular(lg));
  static const xlRadius   = BorderRadius.all(Radius.circular(xl));
  static const xxlRadius  = BorderRadius.all(Radius.circular(xxl));
  static const pillRadius = BorderRadius.all(Radius.circular(pill));

  /// Top-only radius for bottom sheets.
  static const sheetTopRadius = BorderRadius.vertical(top: Radius.circular(xxl));
}
