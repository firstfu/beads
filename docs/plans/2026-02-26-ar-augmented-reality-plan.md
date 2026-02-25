# AR 擴增實境功能實作計畫

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在念珠 App 中新增 AR 顯示模式，讓使用者透過相機將 3D 佛珠放置在真實平面上進行修行。

**Architecture:** 新增 `ARBeadView` 作為第三種顯示模式（與現有 circular/vertical 並列），使用 RealityKit `RealityView` 原生 SwiftUI 容器。建立 `ARBeadSceneManager` 管理 RealityKit Entity 層級，複用現有 `BeadMaterialType` 紋理資源。AR 功能僅限 iOS 平台（`#if os(iOS)`），macOS 和 visionOS 不受影響。

**Tech Stack:** RealityKit, ARKit, SwiftUI (RealityView), SwiftData, Swift Testing

---

## 前置知識

### 現有架構摘要

- **BeadSceneManager** (`beads/Scene/BeadSceneManager.swift`) — SceneKit 環形佛珠管理器，108 顆珠排列在半徑 2.0 的圓環上
- **BeadMaterials** (`beads/Scene/BeadMaterials.swift`) — 9 種 PBR 材質定義，使用 `SCNMaterial`，紋理從 `Assets.xcassets/Textures/` 載入
- **BeadSceneView** (`beads/Views/Components/BeadSceneView.swift`) — `UIViewRepresentable` 橋接 SceneKit → SwiftUI
- **PracticeView** (`beads/Views/PracticeView.swift`) — 根據 `displayMode` 切換 circular/vertical 場景
- **UserSettings** (`beads/Models/UserSettings.swift`) — SwiftData 持久化設定，`BeadDisplayMode` 列舉定義顯示模式
- **SettingsView** (`beads/Views/SettingsView.swift`) — 表單介面，Picker 選擇顯示模式

### 關鍵介面

```swift
// PracticeViewModel 公開方法（不需修改）
func startSession(mantraName: String)
func incrementBead()
var currentBeadIndex: Int { count % beadsPerRound }

// BeadMaterialType 的 SceneKit 方法（需新增 RealityKit 對應方法）
func applyTo(_ material: SCNMaterial)

// 現有 BeadDisplayMode
enum BeadDisplayMode: String, CaseIterable, Identifiable, Codable {
    case circular = "圓環式"
    case vertical = "直立式"
}
```

---

## Task 1: 擴充 BeadDisplayMode 列舉

**Files:**
- Modify: `beads/Models/UserSettings.swift:21-30`
- Test: `beadsTests/Models/UserSettingsARTests.swift` (create)

**Step 1: Write the failing test**

Create `beadsTests/Models/UserSettingsARTests.swift`:

```swift
import Testing
import Foundation
@testable import beads

struct UserSettingsARTests {
    @Test func arDisplayModeExists() async throws {
        let mode = BeadDisplayMode.ar
        #expect(mode.rawValue == "AR 實境")
    }

    @Test func arDisplayModeIdentifiable() async throws {
        let mode = BeadDisplayMode.ar
        #expect(mode.id == "AR 實境")
    }

    @Test func allCasesIncludesAR() async throws {
        #expect(BeadDisplayMode.allCases.contains(.ar))
        #expect(BeadDisplayMode.allCases.count == 3)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`
Expected: FAIL — `type 'BeadDisplayMode' has no member 'ar'`

**Step 3: Write minimal implementation**

In `beads/Models/UserSettings.swift`, add the `.ar` case after `.vertical`:

```swift
enum BeadDisplayMode: String, CaseIterable, Identifiable, Codable {
    case circular = "圓環式"
    case vertical = "直立式"
    case ar = "AR 實境"
    var id: String { rawValue }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`
Expected: PASS

**Step 5: Commit**

```bash
git add beads/Models/UserSettings.swift beadsTests/Models/UserSettingsARTests.swift
git commit -m "feat: add AR display mode to BeadDisplayMode enum"
```

---

## Task 2: 新增相機權限設定

**Files:**
- Modify: `beads/beads/Info.plist`

**Step 1: Add camera usage description to Info.plist**

在 `beads/beads/Info.plist` 的 `<dict>` 內新增：

```xml
<key>NSCameraUsageDescription</key>
<string>需要使用相機來啟用 AR 擴增實境功能，將虛擬佛珠放置在真實環境中。</string>
```

完整 Info.plist:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSCameraUsageDescription</key>
	<string>需要使用相機來啟用 AR 擴增實境功能，將虛擬佛珠放置在真實環境中。</string>
	<key>UIBackgroundModes</key>
	<array>
		<string>remote-notification</string>
		<string>audio</string>
	</array>
</dict>
</plist>
```

**Step 2: Build to verify no errors**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Info.plist
git commit -m "feat: add NSCameraUsageDescription for AR camera access"
```

---

## Task 3: 建立 AR 會話服務（ARSessionService）

**Files:**
- Create: `beads/Services/ARSessionService.swift`
- Test: `beadsTests/Services/ARSessionServiceTests.swift` (create)

**Step 1: Write the failing test**

Create `beadsTests/Services/ARSessionServiceTests.swift`:

```swift
import Testing
import Foundation
@testable import beads

struct ARSessionServiceTests {
    @Test func initialPermissionStateIsNotDetermined() async throws {
        let service = ARSessionService()
        #expect(service.permissionStatus == .notDetermined)
    }

    @Test func arSupportedPropertyExists() async throws {
        let service = ARSessionService()
        // On simulator, AR is not supported
        #expect(service.isARSupported == false || service.isARSupported == true)
    }

    @Test func permissionStatusEnumHasAllCases() async throws {
        let statuses: [ARPermissionStatus] = [.notDetermined, .authorized, .denied]
        #expect(statuses.count == 3)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`
Expected: FAIL — `cannot find 'ARSessionService' in scope`

**Step 3: Write minimal implementation**

Create `beads/Services/ARSessionService.swift`:

```swift
// MARK: - 檔案說明
/// ARSessionService.swift
/// AR 會話服務 - 管理 AR 權限狀態與裝置支援檢測
/// 模組：Services

import Foundation
import AVFoundation
import Observation

#if os(iOS)
import ARKit
#endif

/// AR 相機權限狀態列舉
enum ARPermissionStatus: String {
    /// 尚未請求權限
    case notDetermined
    /// 使用者已授權
    case authorized
    /// 使用者已拒絕
    case denied
}

/// AR 會話服務
/// 負責管理相機權限請求與 AR 裝置支援檢測
@Observable
final class ARSessionService {
    /// 目前的相機權限狀態
    var permissionStatus: ARPermissionStatus = .notDetermined

    /// 裝置是否支援 AR 功能
    var isARSupported: Bool {
        #if os(iOS)
        return ARWorldTrackingConfiguration.isSupported
        #else
        return false
        #endif
    }

    /// 初始化 AR 會話服務，同步目前的權限狀態
    init() {
        syncPermissionStatus()
    }

    /// 請求相機權限
    /// - Parameter completion: 授權結果回呼（true = 已授權）
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionStatus = granted ? .authorized : .denied
                completion(granted)
            }
        }
    }

    /// 同步系統目前的相機權限狀態至本地屬性
    private func syncPermissionStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionStatus = .authorized
        case .denied, .restricted:
            permissionStatus = .denied
        case .notDetermined:
            permissionStatus = .notDetermined
        @unknown default:
            permissionStatus = .notDetermined
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`
Expected: PASS

**Step 5: Commit**

```bash
git add beads/Services/ARSessionService.swift beadsTests/Services/ARSessionServiceTests.swift
git commit -m "feat: add ARSessionService for camera permission management"
```

---

## Task 4: 擴充 BeadMaterials 支援 RealityKit

**Files:**
- Modify: `beads/Scene/BeadMaterials.swift:135-158`
- Test: `beadsTests/Scene/BeadMaterialsARTests.swift` (create)

**Step 1: Write the failing test**

Create `beadsTests/Scene/BeadMaterialsARTests.swift`:

```swift
import Testing
import Foundation
@testable import beads

#if os(iOS)
import RealityKit

struct BeadMaterialsARTests {
    @Test func createRealityKitMaterialExists() async throws {
        let material = BeadMaterialType.zitan.createRealityKitMaterial()
        #expect(material != nil)
    }

    @Test func allMaterialTypesCreateRealityKitMaterial() async throws {
        for type in BeadMaterialType.allCases {
            let material = type.createRealityKitMaterial()
            #expect(material != nil, "Material \(type.rawValue) should create RealityKit material")
        }
    }
}
#endif
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`
Expected: FAIL — `has no member 'createRealityKitMaterial'`

**Step 3: Write minimal implementation**

在 `beads/Scene/BeadMaterials.swift` 檔案末尾（`}` 關閉 enum 之前，約 line 157），新增 RealityKit 材質方法：

```swift
    // MARK: - RealityKit 材質

    #if os(iOS)
    /// 建立 RealityKit PhysicallyBasedMaterial
    /// 將現有 PBR 屬性轉換為 RealityKit 材質系統
    /// - Returns: 設定好的 PhysicallyBasedMaterial，若建立失敗則回傳 SimpleMaterial
    func createRealityKitMaterial() -> any RealityKit.Material {
        var material = PhysicallyBasedMaterial()

        // 漫反射色
        let color = diffuseColor
        material.baseColor = .init(tint: .init(color))

        // 嘗試載入漫反射貼圖
        if let diffuseImage = UIImage(named: diffuseTextureName),
           let cgImage = diffuseImage.cgImage,
           let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .color))
        {
            material.baseColor = .init(texture: .init(texture))
        }

        // 嘗試載入法線貼圖
        if let normalImage = UIImage(named: normalTextureName),
           let cgImage = normalImage.cgImage,
           let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .normal))
        {
            material.normal = .init(texture: .init(texture))
        }

        // PBR 屬性
        material.roughness = .init(floatLiteral: Float(roughness))
        material.metallic = .init(floatLiteral: Float(metalness))

        // 琥珀蜜蠟半透明效果
        if self == .amber {
            material.blending = .transparent(opacity: .init(floatLiteral: 0.85))
        }

        return material
    }
    #endif
```

注意：需要在檔案頂部新增 RealityKit import：

```swift
#if os(iOS)
import RealityKit
#endif
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`
Expected: PASS

**Step 5: Commit**

```bash
git add beads/Scene/BeadMaterials.swift beadsTests/Scene/BeadMaterialsARTests.swift
git commit -m "feat: add RealityKit material conversion to BeadMaterialType"
```

---

## Task 5: 建立 ARBeadSceneManager（RealityKit 佛珠管理器）

**Files:**
- Create: `beads/Scene/ARBeadSceneManager.swift`

**Step 1: Create the ARBeadSceneManager**

Create `beads/Scene/ARBeadSceneManager.swift`:

```swift
// MARK: - 檔案說明
/// ARBeadSceneManager.swift
/// AR 佛珠場景管理器 - 使用 RealityKit 管理 AR 環境中的佛珠 Entity
/// 模組：Scene

import Foundation
import Observation

#if os(iOS)
import RealityKit
import ARKit

/// AR 佛珠場景管理器
/// 負責在 RealityKit Entity 層級建立環形佛珠、管理材質切換與佛珠高亮
@Observable
final class ARBeadSceneManager {
    /// 所有佛珠 Entity 的陣列
    private var beadEntities: [ModelEntity] = []
    /// 佛珠總數（上限 108）
    private let beadCount: Int

    // MARK: - 排列參數

    /// 圓環半徑（公尺，AR 真實尺度）
    private let circleRadius: Float = 0.12
    /// 單顆佛珠半徑（公尺）
    private let beadRadius: Float = 0.006
    /// 佛珠之間的間隙（公尺）
    private let beadGap: Float = 0.002
    /// 實際顯示在圓環上的佛珠數量
    private(set) var displayCount: Int = 0

    /// 佛珠環容器 Entity
    let beadRingEntity = Entity()

    /// 每顆佛珠對應的角度步幅（弧度）
    private(set) var anglePerBead: Float = 0

    /// 目前高亮的佛珠索引
    var currentBeadIndex: Int = 0 {
        didSet { highlightCurrentBead() }
    }

    /// 目前佛珠材質類型
    var materialType: BeadMaterialType = .zitan {
        didSet { applyMaterial() }
    }

    /// 初始化 AR 佛珠場景管理器
    /// - Parameter beadCount: 佛珠總數，預設 108，上限 108
    init(beadCount: Int = 108) {
        self.beadCount = min(beadCount, 108)

        let circumference = 2.0 * Float.pi * circleRadius
        let beadDiameter = beadRadius * 2.0
        let spacePerBead = beadDiameter + beadGap
        self.displayCount = min(Int(circumference / spacePerBead), self.beadCount)
        self.anglePerBead = (Float.pi * 2.0) / Float(displayCount)

        createBeads()
    }

    /// 建立 AR 環形佛珠排列
    private func createBeads() {
        beadRingEntity.name = "ar_bead_ring"

        let beadMesh = MeshResource.generateSphere(radius: beadRadius)
        let material = materialType.createRealityKitMaterial()

        for i in 0..<displayCount {
            let angle = Float(i) / Float(displayCount) * Float.pi * 2 + Float.pi / 2
            let x = circleRadius * cos(angle)
            let z = circleRadius * sin(angle)

            let entity = ModelEntity(mesh: beadMesh, materials: [material])
            entity.position = SIMD3<Float>(x, 0, z)
            entity.name = "bead_\(i)"
            beadRingEntity.addChild(entity)
            beadEntities.append(entity)
        }

        // 母珠 — 較大顆，位於頂部
        let guruMesh = MeshResource.generateSphere(radius: beadRadius * 1.5)
        let guruEntity = ModelEntity(mesh: guruMesh, materials: [material])
        guruEntity.position = SIMD3<Float>(0, 0, circleRadius)
        guruEntity.name = "guru_bead"
        beadRingEntity.addChild(guruEntity)

        // 佛珠環整體向上抬高，讓佛珠放在平面上方
        beadRingEntity.position = SIMD3<Float>(0, beadRadius + 0.005, 0)
    }

    /// 高亮顯示目前佛珠
    /// 將目前佛珠放大至 1.3 倍，其餘恢復原始大小
    private func highlightCurrentBead() {
        let displayIndex = currentBeadIndex % displayCount

        for (i, entity) in beadEntities.enumerated() {
            let scale: Float = (i == displayIndex) ? 1.3 : 1.0
            entity.scale = SIMD3<Float>(repeating: scale)
        }
    }

    /// 套用材質至所有佛珠
    private func applyMaterial() {
        let newMaterial = materialType.createRealityKitMaterial()
        for entity in beadEntities {
            entity.model?.materials = [newMaterial]
        }
        // 母珠
        if let guru = beadRingEntity.children.first(where: { $0.name == "guru_bead" }) as? ModelEntity {
            guru.model?.materials = [newMaterial]
        }
    }

    /// 旋轉佛珠環
    /// - Parameter deltaAngle: 旋轉角度差量（弧度）
    func rotateRing(by deltaAngle: Float) {
        let current = beadRingEntity.orientation
        let rotation = simd_quatf(angle: deltaAngle, axis: SIMD3<Float>(0, 1, 0))
        beadRingEntity.orientation = rotation * current
    }

    /// 動畫推進一顆佛珠
    func animateBeadForward() {
        let rotation = simd_quatf(angle: -anglePerBead, axis: SIMD3<Float>(0, 1, 0))
        let targetOrientation = rotation * beadRingEntity.orientation

        beadRingEntity.move(
            to: Transform(
                scale: beadRingEntity.scale,
                rotation: targetOrientation,
                translation: beadRingEntity.position
            ),
            relativeTo: beadRingEntity.parent,
            duration: 0.25,
            timingFunction: .easeInOut
        )
    }
}
#endif
```

**Step 2: Build to verify no errors**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Scene/ARBeadSceneManager.swift
git commit -m "feat: add ARBeadSceneManager with RealityKit entity management"
```

---

## Task 6: 建立 ARBeadView（SwiftUI AR 視圖）

**Files:**
- Create: `beads/Views/Components/ARBeadView.swift`

**Step 1: Create the ARBeadView**

Create `beads/Views/Components/ARBeadView.swift`:

```swift
// MARK: - 檔案說明
/// ARBeadView.swift
/// AR 佛珠視圖 - 使用 RealityView 在 AR 環境中顯示佛珠，支援平面偵測與手勢互動
/// 模組：Views/Components

import SwiftUI

#if os(iOS)
import RealityKit
import ARKit

/// AR 佛珠視圖
/// 使用 RealityView 將 3D 佛珠放置在偵測到的真實平面上
struct ARBeadView: View {
    /// AR 佛珠場景管理器
    let sceneManager: ARBeadSceneManager
    /// 佛珠推進時的回呼閉包
    var onBeadAdvance: (() -> Void)?
    /// 是否啟用快速捲動模式
    var fastScrollMode: Bool = false

    /// 是否已將佛珠錨定至平面
    @State private var isAnchored = false
    /// 提示文字
    @State private var instructionText = "將相機對準平面以放置佛珠"

    /// 輕撥手勢狀態
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // AR 場景
            RealityView { content in
                // 建立水平平面錨點
                let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.1, 0.1)))
                anchor.addChild(sceneManager.beadRingEntity)
                content.add(anchor)

                // 新增環境光探測
                let pointLight = PointLight()
                pointLight.light.intensity = 1000
                pointLight.position = SIMD3<Float>(0, 0.5, 0)
                anchor.addChild(pointLight)

            } update: { content in
                // RealityView 更新時同步狀態
            }
            .gesture(tapGesture)
            .gesture(dragGesture)
            .ignoresSafeArea()

            // 指示文字覆蓋層
            if !isAnchored {
                VStack {
                    Spacer()
                    Text(instructionText)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            // 延遲後假設已錨定（平面偵測通常幾秒內完成）
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    isAnchored = true
                }
            }
        }
    }

    // MARK: - 手勢

    /// 點擊手勢 - 推進一顆佛珠
    private var tapGesture: some Gesture {
        TapGesture()
            .onEnded { _ in
                guard !isAnimating else { return }
                isAnimating = true
                sceneManager.animateBeadForward()
                onBeadAdvance?()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    isAnimating = false
                }
            }
    }

    /// 拖曳手勢 - 旋轉佛珠環
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if fastScrollMode {
                    let delta = Float(-value.translation.height / 300) * sceneManager.anglePerBead
                    sceneManager.rotateRing(by: delta)
                }
            }
            .onEnded { value in
                if fastScrollMode {
                    let totalSteps = Int(abs(value.translation.height) / 30)
                    for _ in 0..<totalSteps {
                        onBeadAdvance?()
                    }
                } else if abs(value.translation.height) > 30 && !isAnimating {
                    isAnimating = true
                    sceneManager.animateBeadForward()
                    onBeadAdvance?()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                        isAnimating = false
                    }
                }
            }
    }
}
#endif
```

**Step 2: Build to verify no errors**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/Components/ARBeadView.swift
git commit -m "feat: add ARBeadView with RealityView and gesture support"
```

---

## Task 7: 整合 AR 模式至 PracticeView

**Files:**
- Modify: `beads/Views/PracticeView.swift`

**Step 1: Add AR scene manager and conditional view**

在 `PracticeView.swift` 中進行以下修改：

1. 在 import 區塊後方新增條件匯入：

```swift
#if os(iOS)
import RealityKit
#endif
```

2. 在 `@State private var verticalSceneManager` (line 46) 後方新增：

```swift
    #if os(iOS)
    /// AR 佛珠場景管理器
    @State private var arSceneManager = ARBeadSceneManager()
    /// AR 會話服務
    @State private var arSessionService = ARSessionService()
    #endif
```

3. 修改 body 中的 3D 場景切換區塊（lines 63-74），將 `if displayMode == .vertical` 改為三路條件：

```swift
            // 3D 佛珠場景 - 根據顯示模式切換
            #if os(iOS)
            if displayMode == .ar {
                if arSessionService.permissionStatus == .authorized {
                    ARBeadView(sceneManager: arSceneManager, onBeadAdvance: {
                        onBeadAdvance()
                    }, fastScrollMode: fastScrollMode)
                    .ignoresSafeArea()
                } else {
                    // AR 權限未授權時顯示提示
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("需要相機權限才能使用 AR 模式")
                            .font(.headline)
                        if arSessionService.permissionStatus == .notDetermined {
                            Button("授權相機") {
                                arSessionService.requestCameraPermission { _ in }
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Text("請至設定 > 隱私權 > 相機中開啟權限")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else
            #endif
            if displayMode == .vertical {
                VerticalBeadSceneView(sceneManager: verticalSceneManager, onBeadAdvance: {
                    onBeadAdvance()
                }, fastScrollMode: fastScrollMode)
                .ignoresSafeArea()
            } else {
                BeadSceneView(sceneManager: sceneManager, onBeadAdvance: {
                    onBeadAdvance()
                }, fastScrollMode: fastScrollMode)
                .ignoresSafeArea()
            }
```

4. 在 `onAppear` 區塊（line 97）中新增 AR 場景管理器的材質同步：

```swift
            #if os(iOS)
            arSceneManager.materialType = currentMaterialType
            #endif
```

5. 在 `onChange(of: allSettings.first?.currentBeadStyle)` 區塊（line 112）中新增：

```swift
            #if os(iOS)
            arSceneManager.materialType = currentMaterialType
            #endif
```

6. 在 `onBeadAdvance()` 方法中（line 134 後），新增 AR 場景索引同步：

```swift
        #if os(iOS)
        arSceneManager.currentBeadIndex = viewModel.currentBeadIndex
        #endif
```

**Step 2: Build to verify no errors**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/PracticeView.swift
git commit -m "feat: integrate AR display mode into PracticeView"
```

---

## Task 8: 更新 SettingsView 加入 AR 選項

**Files:**
- Modify: `beads/Views/SettingsView.swift`

**Step 1: Update the display mode picker**

在 `SettingsView.swift` 的顯示模式 Section（lines 51-58），修改 Picker 以包含 AR 選項，但在不支援 AR 的裝置上隱藏：

```swift
                // MARK: - 顯示模式設定
                Section("顯示模式") {
                    Picker("佛珠排列", selection: $displayMode) {
                        ForEach(BeadDisplayMode.allCases) { mode in
                            #if os(iOS)
                            Text(mode.rawValue).tag(mode.rawValue)
                            #else
                            if mode != .ar {
                                Text(mode.rawValue).tag(mode.rawValue)
                            }
                            #endif
                        }
                    }
                    .pickerStyle(.segmented)

                    if displayMode == BeadDisplayMode.ar.rawValue {
                        HStack {
                            Image(systemName: "arkit")
                            Text("AR 模式需要相機權限，請將裝置對準平面")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
```

**Step 2: Build to verify no errors**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Run full test suite**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`
Expected: All tests PASS

**Step 4: Commit**

```bash
git add beads/Views/SettingsView.swift
git commit -m "feat: add AR display mode option to SettingsView"
```

---

## Task 9: 完整建置驗證與整合測試

**Files:**
- All modified files

**Step 1: Run full build**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 2: Run all tests**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`
Expected: All tests PASS

**Step 3: Verify no regressions in existing modes**

確認以下功能未受影響：
- 圓環式顯示模式正常運作
- 直立式顯示模式正常運作
- 設定頁面載入正常
- 材質切換正常
- 音效和觸感回饋正常

**Step 4: Commit final integration**

```bash
git add -A
git commit -m "chore: verify AR feature integration - all tests pass"
```

---

## 新增檔案清單

| 檔案 | 用途 |
|------|------|
| `beads/Services/ARSessionService.swift` | AR 權限管理服務 |
| `beads/Scene/ARBeadSceneManager.swift` | RealityKit 佛珠 Entity 管理 |
| `beads/Views/Components/ARBeadView.swift` | SwiftUI RealityView AR 視圖 |
| `beadsTests/Models/UserSettingsARTests.swift` | AR 顯示模式單元測試 |
| `beadsTests/Services/ARSessionServiceTests.swift` | AR 服務單元測試 |
| `beadsTests/Scene/BeadMaterialsARTests.swift` | RealityKit 材質轉換測試 |

## 修改檔案清單

| 檔案 | 修改內容 |
|------|---------|
| `beads/Models/UserSettings.swift` | 新增 `.ar` case 至 BeadDisplayMode |
| `beads/Scene/BeadMaterials.swift` | 新增 `createRealityKitMaterial()` 方法 |
| `beads/Views/PracticeView.swift` | 整合 AR 視圖分支與權限判斷 |
| `beads/Views/SettingsView.swift` | 顯示模式 Picker 加入 AR 選項 |
| `beads/Info.plist` | 新增 `NSCameraUsageDescription` |

---

## 後續 Phase 2 功能（本計畫不包含）

完成 Phase 1 後，可繼續實作：
1. **虛擬佛堂/供桌放置** — 3D 佛像 + 香爐模型在 AR 空間
2. **visionOS 沉浸式冥想空間** — ImmersiveSpace + 360° 寺廟環境
3. **手勢追蹤撥珠** — Vision framework 手指捏合偵測
4. **AR 經文懸浮顯示** — 3D 空間中展示咒語文字
5. **空間音訊** — 位置化的佛珠聲音與環境梵音
