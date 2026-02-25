# 經藏資料完善 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 完善經藏模組的種子資料，補齊 4 筆咒語全文、新增 9 部經典、新增 8 首偈頌，所有內容含完整原文與拼音。

**Architecture:** 沿用現有 `Mantra` Model 不做變更。所有新資料寫入 `MantraSeedData.swift`，長篇經典按品/分拆成多筆記錄。新增 `UserDefaults` 版本控制機制，確保既有用戶能獲得新資料。

**Tech Stack:** Swift, SwiftData, Swift Testing

---

### Task 1: 重構種子資料版本控制機制

**Files:**
- Modify: `beads/Services/MantraSeedData.swift`
- Test: `beadsTests/Services/MantraSeedDataTests.swift`（新建）

**Step 1: Write the failing test**

```swift
// beadsTests/Services/MantraSeedDataTests.swift
import Testing
import Foundation
import SwiftData
@testable import beads

struct MantraSeedDataTests {
    @Test func seedVersionKey_existsAfterSeed() async throws {
        // 建立 in-memory container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Mantra.self, configurations: config)
        let context = ModelContext(container)

        MantraSeedData.seedIfNeeded(modelContext: context)

        let version = UserDefaults.standard.integer(forKey: "seedDataVersion")
        #expect(version == 2)
    }

    @Test func seedVersion2_containsAllCategories() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Mantra.self, configurations: config)
        let context = ModelContext(container)

        MantraSeedData.seedIfNeeded(modelContext: context)

        let descriptor = FetchDescriptor<Mantra>()
        let all = try context.fetch(descriptor)
        let categories = Set(all.map(\.category))
        #expect(categories.contains("淨土宗"))
        #expect(categories.contains("咒語"))
        #expect(categories.contains("經典"))
        #expect(categories.contains("偈頌"))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:beadsTests/MantraSeedDataTests test`
Expected: FAIL — no `seedDataVersion` key, no 經典/偈頌 categories

**Step 3: Refactor `seedIfNeeded` with version control**

Replace the current `seedIfNeeded` method in `beads/Services/MantraSeedData.swift`:

```swift
import SwiftData
import Foundation

struct MantraSeedData {
    /// 當前種子資料版本
    /// - 1: 初始 9 筆（淨土宗 4 + 咒語 5，咒語為截斷版）
    /// - 2: 完整版（補齊咒語全文 + 經典 + 偈頌）
    private static let currentSeedVersion = 2
    private static let seedVersionKey = "seedDataVersion"

    static func seedIfNeeded(modelContext: ModelContext) {
        let savedVersion = UserDefaults.standard.integer(forKey: seedVersionKey)
        guard savedVersion < currentSeedVersion else { return }

        if savedVersion < 1 {
            // 全新安裝：植入所有資料
            seedAllData(modelContext: modelContext)
        } else if savedVersion < 2 {
            // 從 v1 升級：刪除舊的截斷咒語，重新植入完整版 + 新增經典/偈頌
            upgradeToV2(modelContext: modelContext)
        }

        UserDefaults.standard.set(currentSeedVersion, forKey: seedVersionKey)
        try? modelContext.save()
    }

    /// 全新安裝：植入所有資料
    private static func seedAllData(modelContext: ModelContext) {
        for data in pureAndSectMantras { insertMantra(data, into: modelContext) }
        for data in mantraMantras { insertMantra(data, into: modelContext) }
        for data in sutraMantras { insertMantra(data, into: modelContext) }
        for data in verseMantras { insertMantra(data, into: modelContext) }
    }

    /// v1 → v2 升級：補植缺失的資料
    private static func upgradeToV2(modelContext: ModelContext) {
        // 刪除截斷版咒語（原文含 ⋯⋯ 的）
        let descriptor = FetchDescriptor<Mantra>()
        if let existing = try? modelContext.fetch(descriptor) {
            for mantra in existing where mantra.originalText.contains("⋯⋯") {
                modelContext.delete(mantra)
            }
        }
        // 重新植入完整咒語
        for data in mantraMantras { insertMantra(data, into: modelContext) }
        // 新增經典與偈頌
        for data in sutraMantras { insertMantra(data, into: modelContext) }
        for data in verseMantras { insertMantra(data, into: modelContext) }
    }

    private static func insertMantra(
        _ data: (String, String, String, String, String, Int, Int),
        into context: ModelContext
    ) {
        let (name, text, pinyin, desc, category, count, order) = data
        context.insert(Mantra(
            name: name, originalText: text, pinyinText: pinyin,
            descriptionText: desc, category: category,
            suggestedCount: count, sortOrder: order
        ))
    }

    // MARK: - 淨土宗佛號（保持不變）
    private static let pureAndSectMantras: [(String, String, String, String, String, Int, Int)] = [
        // ... Task 2 不動這裡，保持原有 4 筆
    ]

    // MARK: - 咒語（Task 2-5 填入完整資料）
    private static let mantraMantras: [(String, String, String, String, String, Int, Int)] = []

    // MARK: - 經典（Task 6-11 填入）
    private static let sutraMantras: [(String, String, String, String, String, Int, Int)] = []

    // MARK: - 偈頌（Task 12 填入）
    private static let verseMantras: [(String, String, String, String, String, Int, Int)] = []
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:beadsTests test`
Expected: PASS (version tests pass with empty arrays — categories test will still fail, that's OK, it passes after later tasks)

**Step 5: Commit**

```bash
git add beads/Services/MantraSeedData.swift beadsTests/Services/MantraSeedDataTests.swift
git commit -m "refactor: add seed data version control mechanism for scripture upgrade path"
```

---

### Task 2: 補齊淨土宗佛號 + 六字大明咒（原有 5 筆不變）

**Files:**
- Modify: `beads/Services/MantraSeedData.swift`

**Step 1: 填入 `pureAndSectMantras` 與六字大明咒**

將現有 4 筆淨土宗佛號原封不動搬入 `pureAndSectMantras` 陣列。六字大明咒搬入 `mantraMantras`。這些資料不需修改，只是搬遷到新的分陣列結構中。

**Step 2: Build 確認編譯通過**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build`

**Step 3: Commit**

```bash
git add beads/Services/MantraSeedData.swift
git commit -m "refactor: migrate existing Pure Land and Om Mani mantras to new array structure"
```

---

### Task 3: 補齊大悲咒完整全文與拼音

**Files:**
- Modify: `beads/Services/MantraSeedData.swift`

**Step 1: 寫入大悲咒完整 84 句原文與拼音**

在 `mantraMantras` 中加入大悲咒完整資料。原文為千手千眼觀世音菩薩廣大圓滿無礙大悲心陀羅尼全文 84 句，拼音逐句對應。`suggestedCount` = 3（傳統持誦 3 遍/7 遍/21 遍，取最低），`sortOrder` = 5。

**Step 2: Build 確認編譯通過**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build`

**Step 3: Commit**

```bash
git add beads/Services/MantraSeedData.swift
git commit -m "feat: add complete Great Compassion Mantra (84 lines) with full pinyin"
```

---

### Task 4: 補齊往生咒完整全文與拼音

**Files:**
- Modify: `beads/Services/MantraSeedData.swift`

**Step 1: 寫入往生咒完整原文與拼音**

在 `mantraMantras` 中加入往生咒（拔一切業障根本得生淨土陀羅尼）完整資料。`suggestedCount` = 21，`sortOrder` = 6。

**Step 2: Build 確認編譯通過**

**Step 3: Commit**

```bash
git add beads/Services/MantraSeedData.swift
git commit -m "feat: add complete Rebirth Mantra with full pinyin"
```

---

### Task 5: 補齊藥師灌頂真言 + 準提神咒完整全文與拼音

**Files:**
- Modify: `beads/Services/MantraSeedData.swift`

**Step 1: 寫入藥師灌頂真言完整原文與拼音**

`suggestedCount` = 108，`sortOrder` = 7。

**Step 2: 寫入準提神咒完整原文與拼音**

`suggestedCount` = 108，`sortOrder` = 8。

**Step 3: Build 確認編譯通過**

**Step 4: Commit**

```bash
git add beads/Services/MantraSeedData.swift
git commit -m "feat: add complete Medicine Buddha Mantra and Cundi Dharani with full pinyin"
```

---

### Task 6: 新增短篇經典（心經、大勢至念佛圓通章、八大人覺經）

**Files:**
- Modify: `beads/Services/MantraSeedData.swift`

**Step 1: 寫入般若波羅蜜多心經完整原文與拼音**

category = "經典"，`suggestedCount` = 1，`sortOrder` = 100。心經全文約 260 字，含完整拼音。

**Step 2: 寫入大勢至菩薩念佛圓通章完整原文與拼音**

`sortOrder` = 104。

**Step 3: 寫入八大人覺經完整原文與拼音**

`sortOrder` = 105。

**Step 4: Build 確認編譯通過**

**Step 5: Run tests**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:beadsTests test`

**Step 6: Commit**

```bash
git add beads/Services/MantraSeedData.swift
git commit -m "feat: add Heart Sutra, Mahasthamaprapta chapter, and Eight Realizations with full pinyin"
```

---

### Task 7: 新增中篇經典（阿彌陀經、普門品、藥師經）

**Files:**
- Modify: `beads/Services/MantraSeedData.swift`

**Step 1: 寫入佛說阿彌陀經完整原文與拼音**

`sortOrder` = 101。淨土三經之一，全文約 1,800 字。

**Step 2: 寫入觀世音菩薩普門品完整原文與拼音**

`sortOrder` = 102。法華經第二十五品。

**Step 3: 寫入藥師琉璃光如來本願功德經完整原文與拼音**

`sortOrder` = 103。

**Step 4: Build 確認編譯通過**

**Step 5: Commit**

```bash
git add beads/Services/MantraSeedData.swift
git commit -m "feat: add Amitabha Sutra, Universal Gate chapter, and Medicine Buddha Sutra with full pinyin"
```

---

### Task 8: 新增金剛經（32 分）

**Files:**
- Modify: `beads/Services/MantraSeedData.swift`

**Step 1: 寫入金剛經第 1-16 分完整原文與拼音**

每分一筆資料，name 格式：`"金剛經・法會因由分第一"`。category = "經典"，`suggestedCount` = 1，`sortOrder` = 200-215。

**Step 2: Build 確認編譯通過**

**Step 3: Commit**

```bash
git add beads/Services/MantraSeedData.swift
git commit -m "feat: add Diamond Sutra chapters 1-16 with full pinyin"
```

**Step 4: 寫入金剛經第 17-32 分完整原文與拼音**

`sortOrder` = 216-231。

**Step 5: Build 確認編譯通過**

**Step 6: Commit**

```bash
git add beads/Services/MantraSeedData.swift
git commit -m "feat: add Diamond Sutra chapters 17-32 with full pinyin"
```

---

### Task 9: 新增地藏經（13 品）

**Files:**
- Modify: `beads/Services/MantraSeedData.swift`

**Step 1: 寫入地藏經第 1-7 品完整原文與拼音**

每品一筆資料，name 格式：`"地藏經・忉利天宮神通品第一"`。category = "經典"，`suggestedCount` = 1，`sortOrder` = 300-306。

**Step 2: Build 確認編譯通過**

**Step 3: Commit**

```bash
git add beads/Services/MantraSeedData.swift
git commit -m "feat: add Ksitigarbha Sutra chapters 1-7 with full pinyin"
```

**Step 4: 寫入地藏經第 8-13 品完整原文與拼音**

`sortOrder` = 307-312。

**Step 5: Build 確認編譯通過**

**Step 6: Commit**

```bash
git add beads/Services/MantraSeedData.swift
git commit -m "feat: add Ksitigarbha Sutra chapters 8-13 with full pinyin"
```

---

### Task 10: 新增佛說無量壽經（分段）

**Files:**
- Modify: `beads/Services/MantraSeedData.swift`

**Step 1: 確定分段策略**

佛說無量壽經篇幅較長，依內容分為合理段落（約 6-10 段），每段一筆。name 格式：`"無量壽經・第一章"`。`sortOrder` = 400+。

**Step 2: 寫入各段完整原文與拼音**

**Step 3: Build 確認編譯通過**

**Step 4: Commit**

```bash
git add beads/Services/MantraSeedData.swift
git commit -m "feat: add Infinite Life Sutra with full pinyin"
```

---

### Task 11: 新增偈頌（8 首）

**Files:**
- Modify: `beads/Services/MantraSeedData.swift`

**Step 1: 寫入 8 首偈頌完整原文與拼音**

在 `verseMantras` 陣列中加入：

| # | 名稱 | sortOrder | suggestedCount |
|---|------|-----------|---------------|
| 1 | 開經偈 | 500 | 1 |
| 2 | 迴向偈 | 501 | 1 |
| 3 | 四弘誓願 | 502 | 3 |
| 4 | 三皈依 | 503 | 3 |
| 5 | 懺悔偈 | 504 | 3 |
| 6 | 普賢菩薩警眾偈 | 505 | 1 |
| 7 | 讚佛偈 | 506 | 1 |
| 8 | 發願文 | 507 | 1 |

category = "偈頌"，每首含完整原文與拼音。

**Step 2: Build 確認編譯通過**

**Step 3: Run all tests**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:beadsTests test`
Expected: ALL PASS（包含 seedVersion2_containsAllCategories）

**Step 4: Commit**

```bash
git add beads/Services/MantraSeedData.swift
git commit -m "feat: add 8 Buddhist verses (偈頌) with full pinyin"
```

---

### Task 12: 補強測試 + 最終驗證

**Files:**
- Modify: `beadsTests/Services/MantraSeedDataTests.swift`

**Step 1: 增加資料完整性測試**

```swift
@Test func allMantras_haveNonEmptyOriginalText() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Mantra.self, configurations: config)
    let context = ModelContext(container)

    MantraSeedData.seedIfNeeded(modelContext: context)

    let descriptor = FetchDescriptor<Mantra>()
    let all = try context.fetch(descriptor)

    for mantra in all {
        #expect(!mantra.originalText.isEmpty, "Missing originalText for: \(mantra.name)")
        #expect(!mantra.pinyinText.isEmpty, "Missing pinyinText for: \(mantra.name)")
        #expect(!mantra.originalText.contains("⋯⋯"), "Truncated text found in: \(mantra.name)")
    }
}

@Test func allMantras_havValidSortOrder() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Mantra.self, configurations: config)
    let context = ModelContext(container)

    MantraSeedData.seedIfNeeded(modelContext: context)

    let descriptor = FetchDescriptor<Mantra>(sortBy: [SortDescriptor(\.sortOrder)])
    let all = try context.fetch(descriptor)

    // 確認無重複 sortOrder
    let orders = all.map(\.sortOrder)
    #expect(Set(orders).count == orders.count, "Duplicate sortOrder found")
}

@Test func upgradeFromV1_addsNewCategories() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Mantra.self, configurations: config)
    let context = ModelContext(container)

    // 模擬 v1 狀態
    UserDefaults.standard.set(1, forKey: "seedDataVersion")
    context.insert(Mantra(name: "test", originalText: "test⋯⋯", category: "咒語", sortOrder: 99))
    try context.save()

    MantraSeedData.seedIfNeeded(modelContext: context)

    let descriptor = FetchDescriptor<Mantra>()
    let all = try context.fetch(descriptor)
    let categories = Set(all.map(\.category))
    #expect(categories.contains("經典"))
    #expect(categories.contains("偈頌"))
    // 截斷版應被刪除
    #expect(!all.contains(where: { $0.originalText.contains("⋯⋯") }))

    // 清理 UserDefaults
    UserDefaults.standard.removeObject(forKey: "seedDataVersion")
}
```

**Step 2: Run all tests**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:beadsTests test`
Expected: ALL PASS

**Step 3: Full build verification**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add beadsTests/Services/MantraSeedDataTests.swift
git commit -m "test: add comprehensive seed data integrity and upgrade tests"
```

---

## Task Summary

| Task | 描述 | 預估筆數 |
|------|------|---------|
| 1 | 版本控制機制 + 測試 | 0（架構） |
| 2 | 搬遷淨土宗佛號 + 六字大明咒 | 5 筆不變 |
| 3 | 大悲咒完整 84 句 | 1 筆 |
| 4 | 往生咒完整 | 1 筆 |
| 5 | 藥師灌頂真言 + 準提神咒 | 2 筆 |
| 6 | 短篇經典（心經等 3 部） | 3 筆 |
| 7 | 中篇經典（阿彌陀經等 3 部） | 3 筆 |
| 8 | 金剛經 32 分 | 32 筆 |
| 9 | 地藏經 13 品 | 13 筆 |
| 10 | 無量壽經分段 | ~8 筆 |
| 11 | 偈頌 8 首 | 8 筆 |
| 12 | 補強測試 + 最終驗證 | 0（測試） |

**總計約 76+ 筆資料**
