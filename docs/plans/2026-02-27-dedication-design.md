# 回向功能設計文件

**日期**: 2026-02-27
**方案**: A — 最小化方案，PracticeSession 擴充

## 需求摘要

- **觸發時機**: 結束修行時手動觸發（endSession 後彈出）
- **內容形式**: 預設回向文模板 + 自由輸入回向對象
- **數據保存**: 紀錄每次回向到 PracticeSession
- **視覺風格**: 簡潔 Sheet（底部彈出）
- **必要性**: 可以跳過，不強制

## 資料模型

### PracticeSession 擴充

在現有 `PracticeSession` model 新增 3 個可選欄位：

```swift
var dedicationText: String?       // 選擇的回向文內容
var dedicationTarget: String?     // 回向對象（自由輸入）
var hasDedication: Bool            // 是否已完成回向（默認 false）
```

- 所有欄位有默認值，SwiftData schema migration 向後相容
- 跳過回向時保持 nil

### DedicationTemplate enum

硬編碼的回向文模板（類似 BeadMaterialType）：

| Case | 名稱 | 全文 |
|------|------|------|
| universal | 通用回向文 | 願以此功德，莊嚴佛淨土，上報四重恩，下濟三途苦，若有見聞者，悉發菩提心，盡此一報身，同生極樂國 |
| pureLand | 淨土回向文 | 願以此功德，回向西方極樂世界，願生淨土 |
| allBeings | 眾生回向文 | 願以此功德，普及於一切，我等與眾生，皆共成佛道 |
| ancestors | 祖先回向文 | 願以此功德，回向歷代祖先，離苦得樂，往生善處 |
| sickness | 病業回向文 | 願以此功德，回向 OO 身體康健，業障消除，福慧增長 |

每個 case 提供 `name`、`fullText`、`category` 屬性。

## UI 設計

### 觸發流程

```
修行中 → 使用者點「結束修行」
        → endSession() 保存計數
        → 彈出回向 Sheet
        → 使用者選擇回向文 / 輸入對象 / 或跳過
        → 保存回向資訊到 PracticeSession
        → Sheet 關閉
```

### 回向 Sheet 畫面結構

```
┌─────────────────────────────┐
│         回向功德              │  ← 標題
│                             │
│  ── 選擇回向文 ──            │
│  ┌─────────────────────┐    │
│  │ ○ 通用回向文          │    │
│  │ ● 淨土回向文          │    │  ← Radio 選擇
│  │ ○ 眾生回向文          │    │
│  │ ○ 祖先回向文          │    │
│  │ ○ 病業回向文          │    │
│  └─────────────────────┘    │
│                             │
│  所選回向文全文：             │
│  ┌─────────────────────┐    │
│  │「願以此功德，回向西方     │    │  ← 顯示選中模板全文
│  │  極樂世界，願生淨土」     │    │
│  └─────────────────────┘    │
│                             │
│  ── 回向對象（選填）──       │
│  ┌─────────────────────┐    │
│  │ 輸入回向對象...        │    │  ← TextField
│  └─────────────────────┘    │
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │   跳過    │ │  確認回向  │  │
│  └──────────┘ └──────────┘  │
└─────────────────────────────┘
```

### 設計重點

- Sheet 高度：`.presentationDetents([.medium, .large])` 預設中等高度
- 使用現有 ZenBackgroundTheme 配色
- 回向文全文用楷書風格字體
- 跳過按鈕清晰可見，不設障礙
- 確認後顯示簡單的 checkmark 動畫提示

## 檔案變更範圍

### 修改的檔案

| 檔案 | 變更 |
|------|------|
| `beads/Models/PracticeSession.swift` | 新增 dedicationText、dedicationTarget、hasDedication 欄位 |
| `beads/ViewModels/PracticeViewModel.swift` | 新增 saveDedication() 方法，修改 endSession() 流程 |
| `beads/Views/PracticeView.swift` | 新增回向 Sheet 呈現邏輯 |

### 新增的檔案

| 檔案 | 說明 |
|------|------|
| `beads/Models/DedicationTemplate.swift` | 回向文模板 enum |
| `beads/Views/DedicationSheetView.swift` | 回向 Sheet 視圖 |

### 不改的（YAGNI）

- RecordsView — 不加回向歷史展示
- SettingsView — 不增加回向相關設定
- DailyRecord — 不聚合回向數據

## 測試策略

- Unit tests：DedicationTemplate 模板資料完整性
- Unit tests：PracticeSession 回向欄位存取
- Unit tests：saveDedication() 正確寫入欄位
- 手動測試：Sheet 彈出/關閉流程、跳過功能

## 未來擴展（不在本次範圍）

- 回向歷史展示（在 RecordsView）
- 自訂回向文模板
- 回向對象統計
- 全螢幕回向儀式動畫
