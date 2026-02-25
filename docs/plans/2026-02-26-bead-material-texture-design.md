# Bead Material Texture Design

**Date**: 2026-02-26
**Status**: Approved

## Problem

1. **Bug**: `PracticeView` never reads `UserSettings.currentBeadStyle` and never sets `sceneManager.materialType` — material switching has no effect
2. **Visual**: All 5 materials are solid colors only (no texture images), making them hard to distinguish

## Solution

### Part 1: Bug Fix

- Add computed property in `PracticeView` to read `currentBeadStyle` from `allSettings`
- Set `sceneManager.materialType` and `verticalSceneManager.materialType` in `.onAppear` and `.onChange`
- Files changed: `PracticeView.swift` only

### Part 2: Texture System

- Add diffuse + normal map textures for each of the 5 materials
- Resolution: 1024x1024, JPG format
- Source: ambientCG.com (CC0 license, free for commercial use)
- Fallback: if texture image missing, use existing solid color

#### Asset Catalog Structure

```
Assets.xcassets/
  Textures/
    zitan_diffuse.imageset/
    zitan_normal.imageset/
    bodhi_diffuse.imageset/
    bodhi_normal.imageset/
    starMoonBodhi_diffuse.imageset/
    starMoonBodhi_normal.imageset/
    huanghuali_diffuse.imageset/
    huanghuali_normal.imageset/
    amber_diffuse.imageset/
    amber_normal.imageset/
```

#### Code Changes (`BeadMaterials.swift`)

- Add `diffuseTextureName` and `normalTextureName` computed properties to `BeadMaterialType`
- Modify `applyTo()` to load texture images with fallback to solid colors
- Add `PlatformImage` typealias for cross-platform image loading

### Part 3: Texture Acquisition

- Use Playwright to browse ambientCG.com
- Download 1K texture packages for each material
- Extract `_Color` (diffuse) and `_NormalGL` (normal) files from ZIP
- Resize to 1024x1024 and import into Asset Catalog

#### Search Keywords

| Material | Search Terms |
|---|---|
| 小葉紫檀 (zitan) | wood dark / rosewood |
| 菩提子 (bodhi) | wood rough / bark |
| 星月菩提 (starMoonBodhi) | bone / ivory |
| 黃花梨 (huanghuali) | wood / oak golden |
| 琥珀蜜蠟 (amber) | amber / resin |

## Approach

- **Method**: Static textures in Asset Catalog (Option 1)
- **Texture detail**: Diffuse + Normal map (Option B)
- **Source**: CC0 downloads from ambientCG (Option B)
- **Download**: Automated via Playwright

## Non-Goals

- No roughness/metalness texture maps (overkill for small spheres)
- No on-demand downloading or cloud storage
- No Metal shader generation
- No custom material creation by users
