# Bracelet Vertical 3D Effect Design

## Problem

The current bracelet mode tilts the bead ring forward (-70° X-axis) to simulate a "bracelet lying on a table viewed from above." The reference app shows a fundamentally different approach: the bracelet hangs **vertically** with the camera looking at it from the front, producing strong perspective where front beads are very large and back beads are small.

## Solution: Upright Ring + Front Camera (Plan B)

Keep the bead ring in the XY plane (no tilt), place the camera very close in front, and enlarge the beads.

### Scene Geometry

| Parameter | Before | After |
|-----------|--------|-------|
| Circle radius | 2.0 | 2.5 |
| Bead radius | 0.18 | 0.40 |
| Bead gap | 0.06 | 0.10 |
| tiltAngle | -70° (X-axis) | 0° (removed) |
| Y-axis tilt | none | ~10° (subtle depth) |

### Camera

| Parameter | Before | After |
|-----------|--------|-------|
| FOV | 75° | 85° |
| Position | (0, 4.5, 5.5) | (0.3, 0.2, 4.0) |
| Euler angles | (-36°, 0, 0) | (0, 0, 0) |

Perspective ratio: front beads at z=1.5 vs back beads at z=6.5 gives ~4.3x size difference.

### Lighting

- Ambient: 400 (unchanged)
- Key light: 1000, from upper-left (-45°, 45°, 0)
- Fill light: 200, from right side
- Rim light: 150, from behind — outlines front beads

### String (Torus)

- Stays inside beadRingNode (previous fix maintained)
- ringRadius: 2.5 (matches circle)
- pipeRadius: 0.018 (proportional to larger beads)
- eulerAngles: (π/2, 0, 0) in local coords

### Rotation & Interaction

- Ring rotates around Z-axis: `beadRingNode.eulerAngles = SCNVector3(0, yTilt, panRotation)`
- yTilt = 10° ≈ 0.175 rad (fixed, adds subtle 3D depth)
- Up/down swipe gesture maps to Z-axis rotation (beads cycle vertically around ring)
- `rotateRing`, `snapToNearestBead`, `animateBeadForward` simplified — no more tiltAngle in euler angles

### Background

- `isCircularLayout = false` for bracelet mode (lotus in corner, not center)

## Files to Modify

| File | Changes |
|------|---------|
| `beads/Scene/BraceletBeadSceneManager.swift` | Ring geometry, camera, lighting, rotation logic |
| `beads/Views/PracticeView.swift` | Already fixed (isCircularLayout) |

## Verification

1. Build succeeds
2. Bracelet mode shows vertical oval with large front beads, small back beads
3. String aligned with beads
4. Swipe up/down rotates beads along ring
5. Tap advances one bead
6. All three display modes switch correctly
