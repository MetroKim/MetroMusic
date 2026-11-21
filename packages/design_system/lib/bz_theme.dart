import 'package:material_ui/material_ui.dart';

import 'src/tokens.dart';

export 'src/tokens.dart';

/// Breezze theme — builds light/dark [ThemeData] purely from semantic
/// tokens (§21.1). Components consume [BzThemeExt] for material classes.
extension BzThemeExt on ThemeData {
  bool get isDark => brightness == Brightness.dark;
  Color get bzBackground => isDark ? BzColorsDark.background : BzColorsLight.background;
  Color get bzSurface1 => isDark ? BzColorsDark.surfacePrimary : BzColorsLight.surfacePrimary;
  Color get bzSurface2 => isDark ? BzColorsDark.surfaceSecondary : BzColorsLight.surfaceSecondary;
  Color get bzSurfaceElevated => isDark ? BzColorsDark.surfaceElevated : BzColorsLight.surfaceElevated;
  Color get bzText1 => isDark ? BzColorsDark.textPrimary : BzColorsLight.textPrimary;
  Color get bzText2 => isDark ? BzColorsDark.textSecondary : BzColorsLight.textSecondary;
  Color get bzSeparator => isDark ? BzColorsDark.separator : BzColorsLight.separator;
  Color get bzAccent => isDark ? BzColorsDark.accent : BzColorsLight.accent;
  Color get bzSuccess => isDark ? BzColorsDark.success : BzColorsLight.success;
  Color get bzWarning => isDark ? BzColorsDark.warning : BzColorsLight.warning;
  Color get bzError => isDark ? BzColorsDark.error : BzColorsLight.error;
  Color get bzAtmoRegular => isDark ? BzColorsDark.atmoRegular : BzColorsLightAtmo.atmoRegular;
  Color get bzAtmoClear => isDark ? BzColorsDark.atmoClear : BzColorsLightAtmo.atmoClear;
  Color get bzSoftDiffuse => isDark ? BzColorsDark.softDiffuse : BzColorsLightAtmo.softDiffuse;
}

/// Builds the Breezze light theme from tokens.
ThemeData bzLightTheme() => _bzTheme(Brightness.light);

/// Builds the Breezze dark theme from tokens.
ThemeData bzDarkTheme() => _bzTheme(Brightness.dark);

ThemeData _bzTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final text1 = isDark ? BzColorsDark.textPrimary : BzColorsLight.textPrimary;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: text1,
    onPrimary: isDark ? BzColorsDark.background : BzColorsLight.background,
    secondary: isDark ? BzColorsDark.accent : BzColorsLight.accent,
    onSecondary: isDark ? BzColorsDark.background : BzColorsLight.background,
    surface: isDark ? BzColorsDark.surfacePrimary : BzColorsLight.surfacePrimary,
    onSurface: text1,
    surfaceContainerHighest:
        isDark ? BzColorsDark.surfaceSecondary : BzColorsLight.surfaceSecondary,
    error: isDark ? BzColorsDark.error : BzColorsLight.error,
    onError: isDark ? BzColorsDark.background : BzColorsLight.background,
    outline: isDark ? BzColorsDark.separator : BzColorsLight.separator,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        isDark ? BzColorsDark.background : BzColorsLight.background,
    textTheme: _bzTextTheme(text1),
    splashFactory: InkSparkle.splashFactory,
  );
}

TextTheme _bzTextTheme(Color color) {
  return TextTheme(
    displayLarge: TextStyle(fontSize: BzType.display, fontWeight: FontWeight.w700, color: color),
    displayMedium: TextStyle(fontSize: BzType.largeTitle, fontWeight: FontWeight.w700, color: color),
    headlineMedium: TextStyle(fontSize: BzType.title1, fontWeight: FontWeight.w700, color: color),
    headlineSmall: TextStyle(fontSize: BzType.title2, fontWeight: FontWeight.w600, color: color),
    titleLarge: TextStyle(fontSize: BzType.title3, fontWeight: FontWeight.w600, color: color),
    titleMedium: TextStyle(fontSize: BzType.headline, fontWeight: FontWeight.w600, color: color),
    bodyLarge: TextStyle(fontSize: BzType.body, color: color),
    bodyMedium: TextStyle(fontSize: BzType.subheadline, color: color),
    bodySmall: TextStyle(fontSize: BzType.footnote, color: color),
    labelSmall: TextStyle(fontSize: BzType.caption, color: color),
  );
}
