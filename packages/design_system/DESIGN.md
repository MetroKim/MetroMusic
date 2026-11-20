# Breezze Design System — Premium Glass Edition

Design language inspired by Liner's principles (content is the colour,
glass not boxes, calm motion) — adapted into Breezze's own monochrome
identity. No Liner assets, code, fonts, or trade dress copied.

## Core principles (adapted, our own execution)

1. **Content is the colour.** The playing artwork drives an ambient
   backdrop behind Now Playing and the mini-player. Chrome stays
   monochrome.
2. **Glass, not boxes.** Floating surfaces (mini-player, tab bar,
   sheets, overlays) use translucent tint + blur, never opaque grey
   panels. Opaque fallback when reduced transparency is on.
3. **Calm motion.** One easing curve `Cubic(0.22, 1, 0.36, 1)`. Fades
   100–200ms. Springs only for things that "land" (stiffness ~300,
   damping ~22). Idle breathing loops 1.8–2.4s, small amplitude.
4. **Hairline borders.** `separator` at 14%/33% alpha — quiet edges.
5. **Artwork forward.** 150px cards, 12px radius, breathing scale
   0.96→1.0 when playing.

## Motion tokens

```dart
class BzMotion {
  static const int instantMs = 100;
  static const int fastMs = 160;
  static const int navMs = 240;
  static const int artworkMs = 360;
  static const int expandMs = 420;
  static const int sheetMs = 320;
  static const int morphMs = 450;
  static const int breathMs = 2000; // idle loop, ease in-out
}
```

## Glass recipe (dark theme reference)

- Mini-player: fill `atmoRegular` (72% surface-1), blur 24px, hairline
  `separator` border, radius 999 (capsule).
- Tab bar: same fill, blur 16px, active pill `text1`, inactive `text2`.
- Sheets: `atmoClear` fill, blur 32px, radius 22.
- Dialogs: `surfaceElevated` solid (never glass) for accessibility.

## Where each material is used

| Surface | Material | Blur |
|---|---|---|
| Mini-player capsule | atmoRegular | 24 |
| Tab bar capsule | atmoRegular | 16 |
| Now Playing backdrop | artwork-derived ambient | 60 |
| Sheets / queue | atmoClear | 32 |
| Settings rows | surface1 solid | 0 |
| Dialogs | surfaceElevated solid | 0 |

## Figma handoff

This document is the token + material source of truth. Figma variables
should be created 1:1 from BzColorsLight/Dark, BzType, BzRadius,
BzSpacing, BzMotion. Components: BzTabBar, BzMiniPlayer,
BzGlassContainer, BzArtworkCard, BzLyricLine, BzSongRow.
