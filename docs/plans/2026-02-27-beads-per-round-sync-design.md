# 設定每圈珠數同步修行頁面 - 設計文件

**日期**: 2026-02-27
**狀態**: 已核准

## 問題

使用者在設定頁面修改「每圈珠數」後，修行頁面沒有跟著調整。畫面珠子數量、圈數計算邏輯都停留在硬編碼的 108 顆。

## 根本原因

`PracticeViewModel.beadsPerRound` 硬編碼為 108，沒有從 `UserSettings` 讀取。`PracticeView` 中的場景管理器也用預設值初始化。

## 修復方案（方案 A：@Query + onChange 注入）

### 修改檔案

1. **`PracticeView.swift`**
   - 新增 `currentBeadsPerRound` computed property，從 `allSettings.first?.beadsPerRound` 讀取
   - 新增 `onChange(of: allSettings.first?.beadsPerRound)` 同步更新 ViewModel 和場景管理器
   - `.onAppear` 中初始化正確珠數

2. **`PracticeViewModel.swift`**
   - `beadsPerRound` 初始值仍為 108（作為 fallback）
   - 新增 `updateBeadsPerRound(_ count: Int)` 方法：更新珠數、重置計數、重新計算圈數

3. **`BeadSceneManager.swift` / `VerticalBeadSceneManager.swift`**
   - 確認有公開方法可動態更新 `beadCount` 並重建珠子佈局

### 行為規則

- 修行頁面啟動時：從 UserSettings 讀取珠數
- 設定改了珠數：onChange 自動觸發同步
- 珠數變更時：重置當前計數歸零
- 場景管理器重建珠子佈局以反映新數量

### 不修改的部分

- `UserSettings.swift`（已正確）
- `SettingsView.swift`（已正確）
- `PracticeSession.swift`（已正確記錄珠數）
