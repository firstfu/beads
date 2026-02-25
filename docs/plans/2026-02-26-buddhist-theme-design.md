# Buddhist Theme UI/UX Design — 現代佛系風格

**Date**: 2026-02-26
**Status**: Approved
**Style Direction**: 現代佛系 — 融合現代設計語言與佛教元素

---

## 1. Design Goals

- 將全 App 從純黑背景改為暖色大地色系
- 建立集中化 `BeadsTheme` 主題系統，消除散落的硬編碼顏色
- 透過配色、留白和少量蓮花裝飾傳達佛教療癒氛圍
- 四個頁面（修行、記錄、經藏、設定）全部統一改造

---

## 2. Color System

### Primary Palette

| Token | Hex | Usage |
|---|---|---|
| `background` | `#F5F0E8` | 全域背景（暖米白/象牙色） |
| `surfacePrimary` | `#EDE5D8` | 卡片、容器背景（淡南瓜/米黃） |
| `surfaceSecondary` | `#E6DDD0` | 次要容器、input 背景（暖灰米色） |
| `accent` | `#C4A265` | 強調色：按鈕、badge、重點（佛金/素金色） |
| `accentSubtle` | `#C4A265` @ 15% | 淡強調色背景點綴 |
| `textPrimary` | `#3C2A1A` | 主要文字（深檀木色） |
| `textSecondary` | `#7A6B5D` | 次要文字、副標（暖灰棕） |
| `textTertiary` | `#A89B8C` | 提示文字、佔位符（淡暖灰） |
| `divider` | `#D4C9BA` | 分隔線（淡棕灰） |
| `success` | `#8B9E6B` | 正向回饋/功德+1（菩提綠/苔蘚綠） |

### Category Colors

| Token | Hex | Category |
|---|---|---|
| `categoryPureLand` | `#C4A265` | 淨土宗（佛金色） |
| `categoryMantra` | `#9B7BB8` | 咒語（紫色） |
| `categoryClassic` | `#6B8DB5` | 經典（藍色） |
| `categoryVerse` | `#8B9E6B` | 偈頌（苔蘚綠） |

### 3D Scene Colors

| Token | Value | Usage |
|---|---|---|
| `sceneBackground` | Gradient `#EDE5D8` → `#D4C9BA` | 修行頁 3D 場景背景 |
| `sceneLightColor` | RGB `(1.0, 0.95, 0.88)` | 暖色光源 |

---

## 3. Typography

| Token | Spec | Usage |
|---|---|---|
| `titleLarge` | 24pt, `.semibold`, `.rounded` | 頁面標題 |
| `titleMedium` | 18pt, `.medium` | Section 標題 |
| `bodyLarge` | 16pt, `.regular` | 主要內容文字 |
| `bodyMedium` | 14pt, `.regular` | 卡片內文 |
| `caption` | 12pt, `.regular` | 副標/提示 |
| `counter` | 48pt, `.thin`, `.rounded` | 計數大數字 |
| `counterSubtitle` | 14pt, `.light` | 圈數/小計 |

---

## 4. Layout Tokens

### Corner Radius

| Token | Value | Usage |
|---|---|---|
| `radiusSmall` | 8pt | Badge、小按鈕 |
| `radiusMedium` | 12pt | 卡片 |
| `radiusLarge` | 16pt | 大容器 |

### Spacing

| Token | Value | Usage |
|---|---|---|
| `spacingXS` | 4pt | 行內間距 |
| `spacingS` | 8pt | 元素間距 |
| `spacingM` | 16pt | Section 內間距 |
| `spacingL` | 24pt | Section 間距 |

### Shadow

| Token | Value |
|---|---|
| `cardShadow` | color: `textPrimary` @ 8%, radius: 8, y: 2 |

---

## 5. Page-by-Page Design

### 5.1 修行頁 (PracticeView)

- Background: 純黑 → `sceneBackground` 暖色漸層
- 3D scene lighting: 調整為暖色光源配合淡背景
- Counter text: 白色 → `textPrimary` 深檀木色
- Merit +1 animation: 黃色 → `success` 菩提綠
- Bottom status bar: 暖米色半透明底板 + 檀木色文字
- Top mantra name: `accent` 佛金色
- Round label: `textSecondary` 暖灰棕

### 5.2 記錄頁 (RecordsView)

- Background: `background` 暖米白
- Stats cards: `surfacePrimary` + `cardShadow`
- Weekly bar chart: 橘色漸層 → `accent.gradient` 佛金色漸層
- Heatmap: 色階 `surfaceSecondary` → `accent`（灰米 → 金色）
- Number highlights: `accent` 佛金色
- Text: `textPrimary` / `textSecondary`

### 5.3 經藏頁 (ScriptureView)

- Background: `background` 暖米白
- Category color bars: 各自顏色保留，色調調暖
- Pure Land category: 橘色 → `categoryPureLand` 佛金色
- Search bar: `surfaceSecondary` 底色
- Scripture text container: `surfacePrimary`（取代 systemGray6）
- Copy toast: 佛金色底 + 暖白文字

### 5.4 設定頁 (SettingsView)

- Form background: `background` 暖米白
- Section background: `surfacePrimary`
- Toggle/Slider/Picker tint: `accent` 佛金色
- Secondary text: `textTertiary`

### 5.5 Tab Bar

- Background: `surfacePrimary`
- Selected icon: `accent` 佛金色
- Unselected icon: `textTertiary`

### 5.6 Lotus Decoration (畫龍點睛)

- 修行頁頂部: 簡約線條蓮花 icon，淡金色，mantra 名稱上方
- 記錄頁 header: 可選用蓮花分隔線
- Implementation: SwiftUI Shape 繪製或 SF Symbol

---

## 6. Technical Architecture

### New Files

- `beads/Theme/BeadsTheme.swift` — 集中化主題（Colors, Typography, Layout）
- `beads/Theme/Color+Hex.swift` — Color hex 初始化擴展
- `beads/Theme/LotusShape.swift` — 蓮花裝飾 Shape（可選）

### Implementation Strategy

1. Build `BeadsTheme.swift` + `Color+Hex.swift`
2. Apply per-page: PracticeView → RecordsView → ScriptureView → SettingsView → Tab Bar
3. 3D scene background via SceneKit scene background property
4. Lotus icon via simple SwiftUI Shape

### Unchanged

- 3D bead material system (PBR materials)
- Gesture system and animation logic
- Data models and SwiftData
- Audio/haptic feedback system
