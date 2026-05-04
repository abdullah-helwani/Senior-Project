/// Fixed spacing scale. Use these instead of magic numbers like `16`, `12`, `8`.
///
/// Naming follows a t-shirt scale; values are tuned for mobile-first density.
/// Multiplying any of these gives you the next-bigger size, so
/// `Sp.md * 2 == Sp.xl`.
class Sp {
  Sp._();

  /// 2 — hairline gaps inside chips/pills.
  static const double xxs = 2;

  /// 4 — tight inline spacing.
  static const double xs = 4;

  /// 8 — default tight gap (icon ↔ label).
  static const double sm = 8;

  /// 12 — secondary gap between related items.
  static const double smPlus = 12;

  /// 16 — base gap between unrelated items / standard padding.
  static const double md = 16;

  /// 20 — comfortable padding inside cards.
  static const double mdPlus = 20;

  /// 24 — section break / page padding.
  static const double lg = 24;

  /// 32 — large section break.
  static const double xl = 32;

  /// 48 — hero / above-the-fold breaks.
  static const double xxl = 48;

  /// 64 — splash-style breathing room.
  static const double xxxl = 64;
}

/// Standard insets shorthand: `EdgeInsets.all(Sp.md)`,
/// `EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md)`, etc.
/// Re-exported here as a constant set for the most common cases.
class Insets {
  Insets._();

  // EdgeInsets.all
  static const allXs = _AllInset(Sp.xs);
  static const allSm = _AllInset(Sp.sm);
  static const allMd = _AllInset(Sp.md);
  static const allMdPlus = _AllInset(Sp.mdPlus);
  static const allLg = _AllInset(Sp.lg);
}

// Tiny helper so the const-ness reads nicely.
class _AllInset {
  final double value;
  const _AllInset(this.value);
}
