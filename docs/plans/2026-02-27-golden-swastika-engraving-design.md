# Design: Golden Line-Engraved Swastika on Guru Bead

## Problem

The current swastika rendering on the guru bead looks unnatural. The character is too large (35% of texture), the dark overlay creates an ugly rectangular patch, and the effect resembles a stamp rather than a natural engraving on wood.

## Solution

Replace the font-based mask-and-darken approach with geometric path drawing using fine golden strokes. This simulates the gold-filled engraving craft (金漆填刻) found on real high-end Buddhist beads.

## Design

### Swastika Geometry

The swastika is drawn as a CGPath with a central cross and four clockwise turn segments:

```
s = textureSize * 0.10  (half-arm length, ~20% total span)
t = s * 0.35            (turn segment length)
cx, cy = center of texture

Cross:
  horizontal: (cx-s, cy) → (cx+s, cy)
  vertical:   (cx, cy-s) → (cx, cy+s)

Turns (clockwise 卍):
  top    → right: (cx, cy+s) → (cx+t, cy+s)
  right  → down:  (cx+s, cy) → (cx+s, cy-t)
  bottom → left:  (cx, cy-s) → (cx-t, cy-s)
  left   → up:    (cx-s, cy) → (cx-s, cy+t)
```

### Rendering Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Texture size | 1024x1024 | Unchanged |
| Swastika span | ~20% of texture | Down from 35% |
| Stroke width | size * 0.012 (~12px) | Fine line |
| Gold color | rgba(0.85, 0.70, 0.30, 0.85) | Warm gold |
| Line cap | .round | Rounded endpoints |
| Glow | gold alpha 0.2, shadow blur ~3px | Subtle gold sheen |

### Compositing Pipeline

1. Draw base wood texture to RGBA CGContext
2. Set gold stroke color + round line cap + line width
3. Optional: set shadow for subtle golden glow
4. Add swastika CGPath, stroke it
5. Return composited image as guru bead diffuse texture

### Scope

Only `BeadMaterials.swift` / `BeadDecoration` changes:
- Remove `createSwastikaMask()` (no longer needed)
- Remove `maskCache` (no longer needed)
- Add `createSwastikaPath(center:armLength:)` returning CGPath
- Rewrite `createEngravedDiffuseTexture()` to use golden stroke instead of mask-and-darken

No changes to BeadSceneManager or VerticalBeadSceneManager (the `isGuruBead` plumbing from the previous iteration remains intact).

## Expected Result

- Fine golden lines on wood surface, like real gold-filled engraving
- Wood grain fully preserved, no darkening or masking
- Subtle gold glow adds premium feel
- Swastika rotates naturally with the bead sphere
