# Bracelet Vertical 3D Effect Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Change bracelet mode from tilted-forward (table view) to upright-vertical (hanging bracelet) with large beads and strong perspective depth.

**Architecture:** The bead ring stays in the XY plane with no X-axis tilt. The camera is positioned very close in front at z=4.0. Beads are enlarged to radius 0.40 (from 0.18) on a ring of radius 2.5. A subtle Y-axis tilt of ~10° adds depth. All rotation methods are simplified to remove tiltAngle references.

**Tech Stack:** SceneKit, SwiftUI, UIViewRepresentable

---

### Task 1: Update geometry parameters (circle radius, bead size, gap)

**Files:**
- Modify: `beads/Scene/BraceletBeadSceneManager.swift:36-40` (排列參數)
- Modify: `beads/Scene/BraceletBeadSceneManager.swift:47-48` (tiltAngle)

**Step 1: Update geometry constants and remove tiltAngle**

Replace the 排列參數 section and tiltAngle:

```swift
// MARK: - 排列參數

/// 圓環半徑
private let circleRadius: Float = 2.5
/// 單顆佛珠半徑
private let beadRadius: Float = 0.40
/// 佛珠之間的間隙
private let beadGap: Float = 0.10
```

Replace tiltAngle with yTilt:

```swift
/// Y 軸微傾角度（增加立體深度感）
private let yTilt: Float = 10.0 * Float.pi / 180.0
```

**Step 2: Build to check for compilation errors**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,id=15F42FF2-7AEB-4385-8F9B-4FAAB50ED601' build 2>&1 | grep -E '(BUILD|error:)'`

Expected: Compilation errors because `tiltAngle` is referenced in 4 other methods. This confirms our next tasks.

**Step 3: Commit (skip — wait until Task 3 to commit all together)**

---

### Task 2: Update camera and lighting

**Files:**
- Modify: `beads/Scene/BraceletBeadSceneManager.swift:91-98` (camera setup)
- Modify: `beads/Scene/BraceletBeadSceneManager.swift:112-135` (lighting)

**Step 1: Update camera parameters**

Replace the camera block:

```swift
// 攝影機 — 正前方近距離，強透視效果
let cameraNode = SCNNode()
cameraNode.camera = SCNCamera()
cameraNode.camera?.fieldOfView = 85
cameraNode.position = SCNVector3(0.3, 0.2, 4.0)
cameraNode.eulerAngles = SCNVector3(0, 0, 0)
cameraNode.name = "camera"
scene.rootNode.addChildNode(cameraNode)
```

**Step 2: Update lighting for vertical view**

Replace the key/fill/rim lights block:

```swift
// 主光源 — 左上方打光，產生立體感
let keyLight = SCNNode()
keyLight.light = SCNLight()
keyLight.light?.type = .directional
keyLight.light?.intensity = 1000
keyLight.light?.castsShadow = true
keyLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
scene.rootNode.addChildNode(keyLight)

// 補光燈 — 右側柔化陰影
let fillLight = SCNNode()
fillLight.light = SCNLight()
fillLight.light?.type = .directional
fillLight.light?.intensity = 200
fillLight.eulerAngles = SCNVector3(-Float.pi / 6, -Float.pi / 3, 0)
scene.rootNode.addChildNode(fillLight)

// Rim light — 從後方打光，勾勒前排佛珠輪廓
let rimLight = SCNNode()
rimLight.light = SCNLight()
rimLight.light?.type = .directional
rimLight.light?.intensity = 150
rimLight.eulerAngles = SCNVector3(0, Float.pi, 0)
scene.rootNode.addChildNode(rimLight)
```

**Step 3: Commit (skip — wait until Task 3)**

---

### Task 3: Update ring setup, rotation methods, and string

**Files:**
- Modify: `beads/Scene/BraceletBeadSceneManager.swift:144-148` (createBeads — ring setup)
- Modify: `beads/Scene/BraceletBeadSceneManager.swift:173-174` (createString — torus radius)
- Modify: `beads/Scene/BraceletBeadSceneManager.swift:211-214` (rotateRing)
- Modify: `beads/Scene/BraceletBeadSceneManager.swift:220-233` (snapToNearestBead)
- Modify: `beads/Scene/BraceletBeadSceneManager.swift:237-257` (animateBeadForward)

**Step 1: Update createBeads — ring node euler angles**

Replace the beadRingNode setup:

```swift
private func createBeads() {
    // 將環形容器加入場景，Y 軸微傾增加立體感
    beadRingNode.name = "bead_ring"
    beadRingNode.eulerAngles = SCNVector3(0, yTilt, 0)
    scene.rootNode.addChildNode(beadRingNode)
```

**Step 2: Update createString — torus dimensions**

Replace:
```swift
let torus = SCNTorus(ringRadius: CGFloat(circleRadius), pipeRadius: 0.012)
```
With:
```swift
let torus = SCNTorus(ringRadius: CGFloat(circleRadius), pipeRadius: 0.018)
```

**Step 3: Update rotateRing**

Replace entire method:

```swift
func rotateRing(by deltaAngle: Float) {
    panRotation += deltaAngle
    beadRingNode.eulerAngles = SCNVector3(0, yTilt, panRotation)
}
```

**Step 4: Update snapToNearestBead**

Replace the euler angles line inside the animation:

```swift
beadRingNode.eulerAngles = SCNVector3(0, yTilt, snappedAngle)
```

**Step 5: Update animateBeadForward**

Replace the euler angles line inside the animation:

```swift
beadRingNode.eulerAngles = SCNVector3(0, yTilt, targetAngle)
```

**Step 6: Update class doc comment**

Replace lines 21-24:

```swift
/// 手串佛珠場景管理器
/// 負責建立 SceneKit 3D 場景，佛珠環形排列在 XY 平面上垂直懸掛，
/// 相機從正前方近距離觀看，產生強烈的 3D 透視效果。
/// 材質設定、燈光配置、佛珠高亮顯示及手勢驅動的旋轉動畫
```

**Step 7: Build and verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,id=15F42FF2-7AEB-4385-8F9B-4FAAB50ED601' build 2>&1 | grep -E '(BUILD|error:)'`

Expected: `** BUILD SUCCEEDED **`

**Step 8: Commit all changes**

```bash
git add beads/Scene/BraceletBeadSceneManager.swift
git commit -m "feat: change bracelet mode to vertical hanging perspective

Rework bracelet 3D scene from tilted-forward (table view) to
upright-vertical (hanging bracelet) with strong perspective:
- Remove X-axis tilt, add subtle Y-axis tilt (10°)
- Enlarge beads from 0.18 to 0.40 radius on 2.5 ring
- Camera at z=4.0 with 85° FOV for ~4x perspective ratio
- Rim light from behind for front bead outlines
- All rotation methods use (0, yTilt, panRotation)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 4: Verify all three display modes

**Step 1: Build full project**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,id=15F42FF2-7AEB-4385-8F9B-4FAAB50ED601' build 2>&1 | grep -E '(BUILD|error:)'`

Expected: `** BUILD SUCCEEDED **`

**Step 2: Manual verification checklist**

- [ ] Bracelet mode: vertical oval, large front beads, small back beads
- [ ] String (torus) aligned with beads, not separated
- [ ] Swipe up/down rotates beads along ring smoothly
- [ ] Tap advances one bead with animation
- [ ] Circular mode: unchanged, works normally
- [ ] Vertical mode: unchanged, works normally
- [ ] Mode switching between all three: no crashes
- [ ] Lotus decoration NOT in center of bracelet view
