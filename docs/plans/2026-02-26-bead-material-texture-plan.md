# Bead Material Texture Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix material switching bug and add real texture images (diffuse + normal map) for all 5 bead materials.

**Architecture:** Fix `PracticeView` to propagate `currentBeadStyle` to SceneManagers. Add texture images to Asset Catalog. Modify `BeadMaterialType.applyTo()` to load textures with fallback to solid colors.

**Tech Stack:** SwiftUI, SceneKit, SwiftData, Playwright (for texture download)

---

### Task 1: Fix Material Switching Bug in PracticeView

**Files:**
- Modify: `beads/Views/PracticeView.swift`

**Step 1: Add computed property for current material type**

Add after the `fastScrollMode` computed property (line 22):

```swift
private var currentMaterialType: BeadMaterialType {
    if let raw = allSettings.first?.currentBeadStyle {
        return BeadMaterialType(rawValue: raw) ?? .zitan
    }
    return .zitan
}
```

**Step 2: Apply material on appear**

In the `.onAppear` block, add before the ambient sound setup (before line 71):

```swift
sceneManager.materialType = currentMaterialType
verticalSceneManager.materialType = currentMaterialType
```

**Step 3: Add onChange handler for material changes**

Add after the existing `.onDisappear` block (after line 88):

```swift
.onChange(of: allSettings.first?.currentBeadStyle) {
    sceneManager.materialType = currentMaterialType
    verticalSceneManager.materialType = currentMaterialType
}
```

**Step 4: Build to verify no compile errors**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

**Step 5: Commit**

```bash
git add beads/Views/PracticeView.swift
git commit -m "fix: propagate material type from settings to scene managers"
```

---

### Task 2: Download Textures via Playwright

**Files:**
- Download to: `/tmp/beads_textures/` (temporary staging)

Use Playwright to browse ambientCG.com and download 1K texture ZIPs for each material. For each material:

1. Navigate to ambientCG.com
2. Search for the material keyword
3. Find a suitable texture, download the 1K-JPG ZIP
4. Extract `_Color.jpg` (diffuse) and `_NormalGL.jpg` (normal)

**Search plan (in order):**

| # | Material | URL pattern | Target |
|---|---|---|---|
| 1 | zitan | Search "wood dark" | Dark reddish-brown wood |
| 2 | bodhi | Search "wood rough" or "bark" | Rough, beige/tan surface |
| 3 | starMoonBodhi | Search "bone" or "ivory" | Cream/white smooth surface |
| 4 | huanghuali | Search "wood" (golden tone) | Golden-brown wood grain |
| 5 | amber | Search "amber" or "resin" | Golden translucent |

**Step 1: Create staging directory**

```bash
mkdir -p /tmp/beads_textures
```

**Step 2: For each material, use Playwright to:**
1. Navigate to `https://ambientcg.com/list?type=Material&sort=Popular&q={keyword}`
2. Click on a suitable result
3. Download the 1K-JPG variant
4. Unzip and rename files:
   - `*_Color.jpg` → `{material}_diffuse.jpg`
   - `*_NormalGL.jpg` → `{material}_normal.jpg`

**Step 3: Resize all textures to 1024x1024**

```bash
for f in /tmp/beads_textures/*.jpg; do
    sips -z 1024 1024 "$f"
done
```

**Step 4: Verify all 10 files exist**

```bash
ls -la /tmp/beads_textures/
```

Expected: 10 files — `{zitan,bodhi,starMoonBodhi,huanghuali,amber}_{diffuse,normal}.jpg`

---

### Task 3: Create Asset Catalog Imagesets

**Files:**
- Create: `beads/Assets.xcassets/Textures/Contents.json`
- Create: 10 imageset directories under `beads/Assets.xcassets/Textures/`

**Step 1: Create Textures folder in Asset Catalog**

```bash
mkdir -p beads/Assets.xcassets/Textures
```

Create `beads/Assets.xcassets/Textures/Contents.json`:
```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

**Step 2: For each of the 10 imagesets, create directory + Contents.json + copy image**

For each `{name}` in `[zitan_diffuse, zitan_normal, bodhi_diffuse, bodhi_normal, starMoonBodhi_diffuse, starMoonBodhi_normal, huanghuali_diffuse, huanghuali_normal, amber_diffuse, amber_normal]`:

```bash
mkdir -p "beads/Assets.xcassets/Textures/{name}.imageset"
cp "/tmp/beads_textures/{name}.jpg" "beads/Assets.xcassets/Textures/{name}.imageset/{name}.jpg"
```

Create `beads/Assets.xcassets/Textures/{name}.imageset/Contents.json`:
```json
{
  "images" : [
    {
      "filename" : "{name}.jpg",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

**Step 3: Verify asset catalog structure**

```bash
find beads/Assets.xcassets/Textures -type f | sort
```

Expected: 10 `.jpg` files + 11 `Contents.json` files (1 folder + 10 imagesets)

**Step 4: Commit**

```bash
git add beads/Assets.xcassets/Textures
git commit -m "feat: add diffuse and normal map textures for all 5 bead materials"
```

---

### Task 4: Update BeadMaterials.swift to Use Textures

**Files:**
- Modify: `beads/Scene/BeadMaterials.swift`

**Step 1: Add PlatformImage typealias**

Add after the existing `PlatformColor` typealias block (after line 16):

```swift
#if os(macOS)
    typealias PlatformImage = NSImage
#else
    typealias PlatformImage = UIImage
#endif
```

**Step 2: Add texture name computed properties**

Add to the `BeadMaterialType` enum, after the `metalness` property:

```swift
var diffuseTextureName: String {
    switch self {
    case .zitan: return "zitan_diffuse"
    case .bodhi: return "bodhi_diffuse"
    case .starMoonBodhi: return "starMoonBodhi_diffuse"
    case .huanghuali: return "huanghuali_diffuse"
    case .amber: return "amber_diffuse"
    }
}

var normalTextureName: String {
    switch self {
    case .zitan: return "zitan_normal"
    case .bodhi: return "bodhi_normal"
    case .starMoonBodhi: return "starMoonBodhi_normal"
    case .huanghuali: return "huanghuali_normal"
    case .amber: return "amber_normal"
    }
}
```

**Step 3: Update applyTo() to load textures with fallback**

Replace the existing `applyTo()` method:

```swift
func applyTo(_ material: SCNMaterial) {
    material.lightingModel = .physicallyBased

    // Diffuse: prefer texture, fallback to solid color
    if let diffuseImage = PlatformImage(named: diffuseTextureName) {
        material.diffuse.contents = diffuseImage
    } else {
        material.diffuse.contents = diffuseColor
    }

    // Normal map: apply if available
    if let normalImage = PlatformImage(named: normalTextureName) {
        material.normal.contents = normalImage
    }

    material.roughness.contents = roughness
    material.metalness.contents = metalness

    if self == .amber {
        material.transparency = 0.85
        material.transparencyMode = .dualLayer
    }
}
```

**Step 4: Build to verify no compile errors**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

**Step 5: Commit**

```bash
git add beads/Scene/BeadMaterials.swift
git commit -m "feat: load texture images in BeadMaterials with fallback to solid colors"
```

---

### Task 5: Final Verification Build

**Step 1: Clean build**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator clean build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

**Step 2: Run unit tests**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -10`
Expected: All tests pass

**Step 3: Verify git status is clean**

```bash
git status
```
