import 'package:material_ui/material_ui.dart';

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
  static const background = Color(0xFF08090B);
  static const surfacePrimary = Color(0xFF121417);
  static const surfaceSecondary = Color(0xFF1B1F24);
  static const surfaceElevated = Color(0xFF252A31);
  static const textPrimary = Color(0xFFF5F7FA);
  static const textSecondary = Color(0xFFA1A9B3);
  static const separator = Color(0xFF2C323A);
  static const brandOnDark = Color(0xFFF5F7FA);
  static const accent = Color(0xFFBCC9D8);
  static const success = Color(0xFF55C88A);
  static const warning = Color(0xFFEAB95C);
  static const error = Color(0xFFFF6574);

  // Atmosphere material overlays (§20.1)
  static const atmoRegular = Color(0xB8121417); // 72% surface-1
  static const atmoClear = Color(0x2E08090B); // 18% background
  static const softDiffuse = Color(0x80121417); // 50% surface-1
}

class BzColorsLightAtmo {
  static const atmoRegular = Color(0xB8FFFFFF); // 72% white
  static const atmoClear = Color(0x2EFFFFFF); // 18% white
  static const softDiffuse = Color(0x80F4F5F7); // 50% surface-1
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
class BzMotion {
  static const int instantMs = 100;
  static const int fastMs = 160;
  static const int navMs = 240;
  static const int artworkMs = 360;
  static const int expandMs = 420;
  static const int sheetMs = 320;
  static const int morphMs = 450;
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
