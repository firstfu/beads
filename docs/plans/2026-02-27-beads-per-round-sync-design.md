# 每圈珠數同步修行頁面 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 修復「改了設定每圈珠數後，修行頁面沒有跟著調整」的 bug，讓珠數設定完整同步到修行畫面。

**Architecture:** 在 PracticeView 中新增 `currentBeadsPerRound` computed property 從 `@Query` 讀取設定值，透過 `onChange` 監聽珠數變化，同步更新 PracticeViewModel 和三個場景管理器。場景管理器的 `beadCount` 是 `private let`，所以需要重建實例。

**Tech Stack:** SwiftUI, SwiftData, SceneKit, @Observable

---

### Task 1: PracticeViewModel 新增 updateBeadsPerRound 方法

**Files:**
- Modify: `beads/ViewModels/PracticeViewModel.swift:27` (beadsPerRound property)
- Modify: `beads/ViewModels/PracticeViewModel.swift:174-179` (resetCount 方法附近)

**Step 1: 在 PracticeViewModel 中新增 `updateBeadsPerRound(_ count: Int)` 方法**

在 `resetCount()` 方法後面加入：

```swift
/// 更新每圈珠數並重置計數狀態
/// - Parameter count: 新的每圈珠數
func updateBeadsPerRound(_ count: Int) {
    beadsPerRound = count
    resetCount()
}
```

**Step 2: 建置確認無編譯錯誤**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/ViewModels/PracticeViewModel.swift
git commit -m "feat: add updateBeadsPerRound method to PracticeViewModel"
```

---

### Task 2: PracticeView 新增 currentBeadsPerRound computed property

**Files:**
- Modify: `beads/Views/PracticeView.swift:41-46` (currentBackgroundTheme 附近)

**Step 1: 在 `currentBackgroundTheme` computed property 之後新增 `currentBeadsPerRound`**

```swift
/// 目前每圈珠數，從使用者設定中取得
private var currentBeadsPerRound: Int {
    allSettings.first?.beadsPerRound ?? 108
}
```

這與 `displayMode`、`currentMaterialType`、`currentBackgroundTheme` 的模式完全一致。

**Step 2: 建置確認無編譯錯誤**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/PracticeView.swift
git commit -m "feat: add currentBeadsPerRound computed property to PracticeView"
```

---

### Task 3: PracticeView onAppear 初始化正確珠數

**Files:**
- Modify: `beads/Views/PracticeView.swift:98-107` (.onAppear block)

**Step 1: 在 `.onAppear` 中加入珠數初始化**

在現有的 `sceneManager.materialType = currentMaterialType` 之前，加入珠數同步：

```swift
.onAppear {
    // 同步珠數設定（必須在場景管理器初始化之前）
    let beadCount = currentBeadsPerRound
    viewModel.beadsPerRound = beadCount
    sceneManager = BeadSceneManager(beadCount: beadCount)
    verticalSceneManager = VerticalBeadSceneManager(beadCount: beadCount)
    braceletSceneManager = BraceletBeadSceneManager(beadCount: beadCount)

    sceneManager.materialType = currentMaterialType
    verticalSceneManager.materialType = currentMaterialType
    braceletSceneManager.materialType = currentMaterialType
    viewModel.startSession(mantraName: "南無阿彌陀佛")
    viewModel.loadTodayStats(modelContext: modelContext)
    #if os(iOS)
    UIApplication.shared.isIdleTimerDisabled = true
    #endif
}
```

**Step 2: 建置確認無編譯錯誤**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/PracticeView.swift
git commit -m "feat: initialize bead count from UserSettings on appear"
```

---

### Task 4: PracticeView 新增 onChange 監聽珠數變化

**Files:**
- Modify: `beads/Views/PracticeView.swift:114-118` (onChange of currentBeadStyle 附近)

**Step 1: 在現有的 `.onChange(of: allSettings.first?.currentBeadStyle)` 之後，新增珠數變化監聽**

```swift
.onChange(of: allSettings.first?.beadsPerRound) {
    let beadCount = currentBeadsPerRound
    viewModel.updateBeadsPerRound(beadCount)

    // 場景管理器的 beadCount 是 let，需要重建實例
    let material = currentMaterialType
    sceneManager = BeadSceneManager(beadCount: beadCount)
    sceneManager.materialType = material
    verticalSceneManager = VerticalBeadSceneManager(beadCount: beadCount)
    verticalSceneManager.materialType = material
    braceletSceneManager = BraceletBeadSceneManager(beadCount: beadCount)
    braceletSceneManager.materialType = material
}
```

**Step 2: 建置確認無編譯錯誤**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/PracticeView.swift
git commit -m "feat: sync bead count changes from settings to practice view"
```

---

### Task 5: 端到端驗證

**Step 1: 完整建置**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 2: 執行測試**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -10`
Expected: All tests pass

**Step 3: 最終 commit（如果有任何修正）**

只有在前面步驟需要修正時才建立此 commit。
