import 'package:flutter/animation.dart';

/// Standard motion tokens. Use these everywhere instead of inventing new
/// durations/curves per screen — consistent motion is a huge part of "feel."
class Motion {
  Motion._();

  // ── Durations ────────────────────────────────────────────────────────────
  /// Hover/press feedback. Should feel instant.
  static const Duration instant = Duration(milliseconds: 80);

  /// State changes inside the same surface (selection, badge update).
  static const Duration fast = Duration(milliseconds: 160);

  /// Default for most transitions (sheet, dialog, page change body).
  static const Duration medium = Duration(milliseconds: 240);

  /// Hero / shared-element transitions, splash → home.
  static const Duration slow = Duration(milliseconds: 360);

  /// Onboarding-style emphasis animations.
  static const Duration epic = Duration(milliseconds: 520);

  // ── Curves ───────────────────────────────────────────────────────────────
  /// Default ease for most things — gentle, no overshoot.
  static const Curve standard = Cubic(0.2, 0, 0, 1);

  /// Snappy enter (e.g. sheet sliding up).
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1);

  /// Quick exit (sheet dismissing).
  static const Curve emphasizedAccelerate = Cubic(0.3, 0, 0.8, 0.15);

  /// For positive/celebratory moments (success states).
  static const Curve playful = Curves.easeOutBack;
}
