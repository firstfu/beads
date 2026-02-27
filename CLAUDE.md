# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案概述

**beads（佛珠念經計數器）** 是一款 SwiftUI + SwiftData 佛教修行 App，提供 3D 佛珠撥念、念誦計數、修行統計與經藏瀏覽功能。UI 全繁體中文，強制深色模式。

- **Bundle ID**: `com.example.buddhistPrayerBeads`
- **Swift Version**: 5.0
- **最低部署目標**: iOS 26.2
- **支援平台**: iPhone, iPad, Mac, visionOS
- **無第三方套件依賴**（純 Apple 框架）

## 建置與測試

```bash
# 建置
xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build

# 全部測試（單元 + UI）
xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' test

# 僅 UI 測試
xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:beadsUITests test

# 執行單一測試（以 PracticeSessionTests 為例）
xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:beadsTests/PracticeSessionTests test
```

## 架構

### 整體結構

App 使用 **TabView** 四頁籤架構：修行 → 記錄 → 經藏 → 設定

```
beadsApp.swift          # @main 入口，配置 ModelContainer，植入種子資料
ContentView.swift       # TabView 根視圖，注入 AudioService 到環境
├── PracticeView        # 修行主畫面（3D 佛珠 + 計數）
├── RecordsView         # 統計（今日/週/月報表、迴向歷史）
├── ScriptureView       # 經藏瀏覽（MantraListView → MantraDetailView）
└── SettingsView        # 偏好設定
```

### 資料層（SwiftData）

四個 `@Model`，全部註冊在同一個 `ModelContainer`：

| Model | 用途 |
|---|---|
| `PracticeSession` | 單次修行場次（計數、圈數、起訖時間、迴向） |
| `DailyRecord` | 每日彙總統計（日期正規化為零時） |
| `Mantra` | 咒語/佛號資料（名稱、原文、拼音、分類） |
| `UserSettings` | 使用者偏好（單例模式，App 啟動時確保存在） |

- Schema 遷移失敗時會自動刪除舊資料庫重建（見 `beadsApp.swift`）
- 種子資料透過 `MantraSeedData` 以 UserDefaults 版本號控制，支援升級路徑
- 種子資料分檔在 `Services/SeedData/MantraSeedData+*.swift`（各經典/咒語分類）
- CloudKit entitlements 已宣告但**未啟用同步**（container ID 為空，ModelConfiguration 無 CloudKit 參數）

### 3D 佛珠場景（SceneKit）

三種顯示模式，各自獨立的場景管理器：

| 管理器 | 排列方式 | 手勢 |
|---|---|---|
| `BeadSceneManager` | 圓環式（XY 平面） | 拖曳旋轉 |
| `VerticalBeadSceneManager` | 直立式（垂直排列） | 拖曳平移 |
| `BraceletBeadSceneManager` | 手串式（傾斜環形） | 拖曳旋轉 |

- 材質系統在 `BeadMaterials.swift`，定義 9 種木質材質（`BeadMaterialType`）
- 每種材質有 diffuse + normal 貼圖，存放在 `Assets.xcassets/Textures/`
- 場景管理器的 `beadCount` 是 `let`，變更珠數需重建實例
- 對應的 SwiftUI 包裝：`BeadSceneView`、`VerticalBeadSceneView`、`BraceletBeadSceneView`

### 服務層

| 服務 | 說明 |
|---|---|
| `AudioService` | `@Observable`，管理撥珠音效（wav）和背景音樂（mp3 循環播放），透過 `.environment()` 注入 |
| `HapticService` | CoreHaptics 觸覺回饋，撥珠用 UIImpactFeedback，完成一圈用自訂震動模式 |

- 音效檔案：`Resources/Audio/bead_click.wav`、`round_complete.wav`
- 背景音樂：`Resources/Audio/ambient/*.mp3`（11 首，對應 `AmbientTrack` enum）

### ViewModel 層

| ViewModel | 說明 |
|---|---|
| `PracticeViewModel` | `@Observable`，管理計數/圈數/撤銷堆疊，結束時寫入 PracticeSession + DailyRecord |
| `StatsViewModel` | `@Observable`，載入今日/週/月統計和連續天數 |

### 關鍵列舉（存為 rawValue 字串在 UserSettings 中）

- `BeadDisplayMode`：直立式 / 圓環式 / 手串式
- `BeadMaterialType`：9 種木質材質
- `AmbientTrack`：11 首背景音樂
- `ZenBackgroundTheme`：5 種禪意背景主題（水墨/午夜/寺廟/蓮花/竹林）
- `DedicationTemplate`：5 種迴向文模板

## 關鍵模式

- SwiftData `@Model` 持久化，`@Query` 響應式查詢
- `@Observable` 巨集用於 ViewModel 和 Service（非 ObservableObject）
- `AudioService` 透過 SwiftUI `.environment()` 注入，非 `@EnvironmentObject`
- 跨平台使用 `#if os(macOS)` / `#if os(iOS)` 和 `PlatformColor`/`PlatformImage` 型別別名
- 所有 UI 文字為繁體中文硬編碼（無 Localization 檔案）
- 程式碼註解風格：每個檔案頂部有 `// MARK: - 檔案說明` 區塊，繁中 DocC 風格註解

## 測試

- `beadsTests/` — Swift Testing 框架（`import Testing`、`@Test`、`#expect`），**非 XCTest**
- `beadsUITests/` — XCTest 框架
- 測試檔案結構映射源碼目錄：`beadsTests/Models/`、`beadsTests/Services/`、`beadsTests/ViewModels/`
