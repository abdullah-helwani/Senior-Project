import 'package:flutter/material.dart';

/// Corner radius scale. Use [Radii] constants instead of `BorderRadius.circular(16)`
/// scattered across the codebase.
///
/// Convention: `sm` for chips/pills, `md` for inputs/tiles, `lg` for cards,
/// `xl` for sheets and hero surfaces, `pill` for fully rounded.
class Radii {
  Radii._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static const xsRadius = BorderRadius.all(Radius.circular(xs));
  static const smRadius = BorderRadius.all(Radius.circular(sm));
  static const mdRadius = BorderRadius.all(Radius.circular(md));
  static const lgRadius = BorderRadius.all(Radius.circular(lg));
  static const xlRadius = BorderRadius.all(Radius.circular(xl));
  static const pillRadius = BorderRadius.all(Radius.circular(pill));

  /// Top-only radius for bottom sheets.
  static const sheetTopRadius = BorderRadius.vertical(top: Radius.circular(xl));
}
