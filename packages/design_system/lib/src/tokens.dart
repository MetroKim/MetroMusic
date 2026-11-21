import 'package:flutter/material.dart';

/// Breezze design tokens — spec §21.1.
///
/// Semantic tokens only. No literal colors are allowed anywhere else in
/// the app; every surface, text, and control consumes these.
class BzColorsLight {
  static const background = Color(0xFFFFFFFF);
  static const surfacePrimary = Color(0xFFF4F5F7);
  static const surfaceSecondary = Color(0xFFEAEDF0);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111317);
  static const textSecondary = Color(0xFF626A73);
  static const separator = Color(0xFFE2E6EA);
  static const brandMonochrome = Color(0xFF111317);
  static const accent = Color(0xFF34465B);
  static const success = Color(0xFF237A4B);
  static const warning = Color(0xFF98620E);
  static const error = Color(0xFFB42332);
}

class BzColorsDark {
  /// True-black canvas for the premium OLED dark theme (design doc:
  /// "Glass, not boxes" — the canvas disappears, the cover leads).
  static const background = Color(0xFF000000);
  static const surfacePrimary = Color(0xFF0A0A0A);
  static const surfaceSecondary = Color(0xFF141414);
  static const surfaceElevated = Color(0xFF1A1A1A);
  static const textPrimary = Color(0xFFF5F7FA);
  static const textSecondary = Color(0xFFB3BAC4);
  static const separator = Color(0xFF23262C);
  static const brandOnDark = Color(0xFFF5F7FA);
  static const accent = Color(0xFFBCC9D8);
  static const success = Color(0xFF55C88A);
  static const warning = Color(0xFFEAB95C);
  static const error = Color(0xFFFF6574);

  // Atmosphere material overlays (§20.1)
  static const atmoRegular = Color(0xB80A0A0A); // 72% surface-1
  static const atmoClear = Color(0x2E000000); // 18% background
  static const softDiffuse = Color(0x800A0A0A); // 50% surface-1
}

class BzColorsLightAtmo {
  static const atmoRegular = Color(0xB8FFFFFF); // 72% white
  static const atmoClear = Color(0x2EFFFFFF); // 18% white
  static const softDiffuse = Color(0x80F4F5F7); // 50% surface-1
}

/// Fill scale — quiet fills sitting INSIDE a surface (fields, chips,
/// segmented controls, secondary buttons, list panels). Theme-inverted:
/// black alphas on light, white alphas on dark. One token covers both
/// themes; screens never hand-roll alpha overlays.
class BzFillLight {
  static const subtle = Color(0x08000000); // black 3%
  static const base = Color(0x0D000000); // black 5%
  static const hover = Color(0x14000000); // black 8%
  static const strong = Color(0x1A000000); // black 10%
}

class BzFillDark {
  static const subtle = Color(0x0AFFFFFF); // white 4%
  static const base = Color(0x12FFFFFF); // white 7%
  static const hover = Color(0x1AFFFFFF); // white 10%
  static const strong = Color(0x24FFFFFF); // white 14%
}

/// Spacing — 8pt grid, 4pt micro (§21.5).
class BzSpacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s64 = 64;
}

/// Radius (§21.6).
class BzRadius {
  static const double button = 8;
  static const double input = 10;
  static const double artwork = 12;
  static const double card = 18;
  static const double panel = 20;
  static const double sheet = 22;
  static const double modal = 28;
  static const double capsule = 999;
}

/// Elevation (§21.7).
class BzElevation {
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 2;
  static const double level3 = 3;
  static const double level4 = 4;
  static const double level5 = 5;
}

/// Motion (§20.7/§21.10).
///
/// One easing curve for the whole app; springs for things that "land";
/// idle loops (breathing artwork, ambient pulses) are slow and quiet.
class BzMotion {
  static const int instantMs = 100;
  static const int fastMs = 160;
  static const int navMs = 240;
  static const int artworkMs = 360;
  static const int expandMs = 420;
  static const int sheetMs = 320;
  static const int morphMs = 450;

  /// The single Breezze easing — enter and exit.
  static const Cubic standardCurve = Cubic(0.22, 1, 0.36, 1);

  /// Spring presets for components that land (sheets, hero buttons).
  static const double springStiffness = 300;
  static const double springDamping = 21;

  /// Idle loop range — breathing artwork, ambient glows. Slow, quiet.
  static const int idleLoopMinMs = 1800;
  static const int idleLoopMaxMs = 2400;
}

/// Type scale (§21.3).
class BzType {
  static const double display = 40;
  static const double largeTitle = 34;
  static const double title1 = 28;
  static const double title2 = 22;
  static const double title3 = 18;
  static const double headline = 17;
  static const double body = 16;
  static const double subheadline = 14;
  static const double footnote = 12;
  static const double caption = 11;
}
