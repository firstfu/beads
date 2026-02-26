# Fix AR Camera Feed - Design Document

## Problem

AR mode shows a black screen instead of camera feed. The `RealityView` used in `ARBeadView` does not start an AR camera session on iOS — it's a pure 3D rendering container.

## Root Cause

`RealityView` on iOS does not automatically enable AR camera passthrough. To display camera feed with plane detection on iOS, you need `ARView` (a UIKit component from RealityKit).

## Solution

Replace `RealityView` in `ARBeadView.swift` with `ARView` wrapped in `UIViewRepresentable`.

### Architecture

```
ARBeadView (SwiftUI View)
├── ARViewContainer (UIViewRepresentable)
│   ├── ARView — camera feed + 3D rendering
│   │   ├── ARWorldTrackingConfiguration — horizontal plane detection
│   │   └── AnchorEntity(.plane) — bead anchor
│   │       ├── beadRingEntity (from ARBeadSceneManager)
│   │       └── PointLight
│   └── Coordinator — UIKit gesture handling
│       ├── UITapGestureRecognizer → advance bead
│       └── UIPanGestureRecognizer → drag/fast-scroll
└── Instruction text overlay (shown until plane detected)
```

### Changes

| File | Change | Scope |
|------|--------|-------|
| `ARBeadView.swift` | Rewrite: RealityView → ARView + UIViewRepresentable | Major |
| `ARBeadSceneManager.swift` | No change | None |
| `ARSessionService.swift` | No change | None |
| `PracticeView.swift` | Already fixed (conditional ZenBackgroundView) | Done |

### Key Implementation Details

1. **ARView config**: `ARWorldTrackingConfiguration` with `.horizontal` plane detection, `.environmentTexturing = .automatic`
2. **Anchor**: `AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: [0.1, 0.1]))`
3. **Gestures**: UIKit gesture recognizers via Coordinator (tap + pan), same logic as current SwiftUI gestures
4. **Lifecycle**: Start AR session in `makeUIView`, pause in `dismantleUIView`
5. **Instruction overlay**: Retained as SwiftUI overlay, auto-hides after 3 seconds

### Compatibility

- `ARBeadSceneManager.beadRingEntity` and all `ModelEntity` instances are native RealityKit types, fully compatible with `ARView.scene`
- No changes needed to entity management or material system
