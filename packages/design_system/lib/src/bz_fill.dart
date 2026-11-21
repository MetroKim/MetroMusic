import 'package:flutter/material.dart';

import 'tokens.dart';

/// BzFill tokens exposed on the theme — one accessor, both themes.
extension BzFillThemeX on ThemeData {
  bool get bzIsDark => brightness == Brightness.dark;

  /// Quiet fills inside a surface. Theme-inverted alphas.
  Color get bzFillSubtle =>
      bzIsDark ? BzFillDark.subtle : BzFillLight.subtle;
  Color get bzFillBase => bzIsDark ? BzFillDark.base : BzFillLight.base;
  Color get bzFillHover =>
      bzIsDark ? BzFillDark.hover : BzFillLight.hover;
  Color get bzFillStrong =>
      bzIsDark ? BzFillDark.strong : BzFillLight.strong;
}
