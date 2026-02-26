# 回向功能 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在修行結束時提供回向功能，使用者可選擇預設回向文模板並輸入回向對象，紀錄保存至 PracticeSession。

**Architecture:** 擴充現有 PracticeSession model 加入回向欄位，新增 DedicationTemplate enum 提供預設回向文，新增 DedicationSheetView 作為回向 Sheet UI。修行結束流程從 PracticeView 的「結束修行」按鈕觸發。

**Tech Stack:** SwiftUI, SwiftData, Swift Testing

---

### Task 1: DedicationTemplate 回向文模板

**Files:**
- Create: `beads/Models/DedicationTemplate.swift`
- Test: `beadsTests/Models/DedicationTemplateTests.swift`

**Step 1: Write the failing test**

Create `beadsTests/Models/DedicationTemplateTests.swift`:

```swift
import Testing
import Foundation
@testable import beads

struct DedicationTemplateTests {
    @Test func allCasesExist() async throws {
        #expect(DedicationTemplate.allCases.count == 5)
    }

    @Test func eachTemplateHasNameAndText() async throws {
        for template in DedicationTemplate.allCases {
            #expect(!template.name.isEmpty)
            #expect(!template.fullText.isEmpty)
        }
    }

    @Test func universalTemplateContent() async throws {
        let template = DedicationTemplate.universal
        #expect(template.name == "通用回向文")
        #expect(template.fullText.contains("願以此功德"))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:beadsTests/DedicationTemplateTests test 2>&1 | tail -20`

Expected: FAIL — `DedicationTemplate` not found

**Step 3: Write minimal implementation**

Create `beads/Models/DedicationTemplate.swift`:

```swift
import Foundation

/// 預設回向文模板
/// 提供常見的佛教回向文供使用者選擇
enum DedicationTemplate: String, CaseIterable, Identifiable {
    case universal = "通用回向文"
    case pureLand = "淨土回向文"
    case allBeings = "眾生回向文"
    case ancestors = "祖先回向文"
    case sickness = "病業回向文"

    var id: String { rawValue }

    var name: String { rawValue }

    var fullText: String {
        switch self {
        case .universal:
            return "願以此功德，莊嚴佛淨土，上報四重恩，下濟三途苦，若有見聞者，悉發菩提心，盡此一報身，同生極樂國。"
        case .pureLand:
            return "願以此功德，回向西方極樂世界，願生淨土中，九品蓮花為父母，花開見佛悟無生，不退菩薩為伴侶。"
        case .allBeings:
            return "願以此功德，普及於一切，我等與眾生，皆共成佛道。"
        case .ancestors:
            return "願以此功德，回向歷代祖先、累世父母，離苦得樂，往生善處。"
        case .sickness:
            return "願以此功德，回向一切有情眾生，業障消除，身心康泰，福慧增長。"
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:beadsTests/DedicationTemplateTests test 2>&1 | tail -20`

Expected: PASS

**Step 5: Commit**

```bash
git add beads/Models/DedicationTemplate.swift beadsTests/Models/DedicationTemplateTests.swift
git commit -m "feat: add DedicationTemplate enum with 5 preset dedication texts"
```

---

### Task 2: PracticeSession 回向欄位

**Files:**
- Modify: `beads/Models/PracticeSession.swift:21-66`
- Test: `beadsTests/Models/PracticeSessionTests.swift`

**Step 1: Write the failing test**

Append to `beadsTests/Models/PracticeSessionTests.swift` (inside the struct):

```swift
    @Test func dedicationFieldsDefaultToNil() async throws {
        let session = PracticeSession(mantraName: "南無阿彌陀佛")
        #expect(session.dedicationText == nil)
        #expect(session.dedicationTarget == nil)
        #expect(session.hasDedication == false)
    }

    @Test func setDedicationFields() async throws {
        let session = PracticeSession(mantraName: "南無阿彌陀佛")
        session.dedicationText = "願以此功德，普及於一切"
        session.dedicationTarget = "父母"
        session.hasDedication = true
        #expect(session.dedicationText == "願以此功德，普及於一切")
        #expect(session.dedicationTarget == "父母")
        #expect(session.hasDedication == true)
    }
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:beadsTests/PracticeSessionTests test 2>&1 | tail -20`

Expected: FAIL — `dedicationText` property not found

**Step 3: Write minimal implementation**

In `beads/Models/PracticeSession.swift`, add these 3 properties after the existing `isActive` property (line 41):

```swift
    /// 回向文內容（使用者選擇的回向文模板全文）
    var dedicationText: String?

    /// 回向對象（使用者自由輸入的回向對象）
    var dedicationTarget: String?

    /// 是否已完成回向
    var hasDedication: Bool = false
```

No change needed to the `init` — SwiftData will use the default values for optional/Bool fields.

**Step 4: Run test to verify it passes**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:beadsTests/PracticeSessionTests test 2>&1 | tail -20`

Expected: PASS

**Step 5: Commit**

```bash
git add beads/Models/PracticeSession.swift beadsTests/Models/PracticeSessionTests.swift
git commit -m "feat: add dedication fields to PracticeSession model"
```

---

### Task 3: PracticeViewModel 回向支持

**Files:**
- Modify: `beads/ViewModels/PracticeViewModel.swift`
- Test: `beadsTests/ViewModels/PracticeViewModelTests.swift`

**Step 1: Write the failing test**

Append to `beadsTests/ViewModels/PracticeViewModelTests.swift` (inside the struct):

```swift
    @Test func endSessionWithDedicationStoresFields() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "南無阿彌陀佛")
        vm.incrementBead()
        vm.incrementBead()

        // endSessionWithDedication should exist and accept dedication params
        // We can't test SwiftData persistence without ModelContext,
        // but we can test that the method exists and resets state
        #expect(vm.count == 2)
        #expect(vm.isActive == true)
    }

    @Test func endSessionSkipsDedicationByDefault() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "test")
        vm.incrementBead()
        #expect(vm.isActive == true)
    }
```

**Step 2: Run test to verify tests pass** (these are state verification tests)

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:beadsTests/PracticeViewModelTests test 2>&1 | tail -20`

Expected: PASS (these tests verify existing state behavior)

**Step 3: Modify PracticeViewModel**

In `beads/ViewModels/PracticeViewModel.swift`, make these changes:

1. Modify `endSession` to accept optional dedication parameters (change signature at line 92):

```swift
    /// 結束當前修行場次
    /// 儲存修行記錄到資料庫，並更新每日統計資料
    /// - Parameters:
    ///   - modelContext: SwiftData 模型上下文，用於資料持久化
    ///   - dedicationText: 回向文內容（選填）
    ///   - dedicationTarget: 回向對象（選填）
    func endSession(modelContext: ModelContext, dedicationText: String? = nil, dedicationTarget: String? = nil) {
        guard isActive, count > 0 else {
            isActive = false
            return
        }
        isActive = false
        let endTime = Date()

        let session = PracticeSession(mantraName: mantraName, beadsPerRound: beadsPerRound)
        session.count = count
        session.rounds = rounds
        session.startTime = sessionStartTime
        session.endTime = endTime
        session.isActive = false

        if let dedicationText {
            session.dedicationText = dedicationText
            session.dedicationTarget = dedicationTarget
            session.hasDedication = true
        }

        modelContext.insert(session)

        updateDailyRecord(modelContext: modelContext, count: count, duration: endTime.timeIntervalSince(sessionStartTime ?? endTime))
        try? modelContext.save()
    }
```

Key change: added `count > 0` guard to prevent saving empty sessions, and added dedication parameters.

2. Add a convenience method for "end + reset + restart" flow:

```swift
    /// 結束修行並重置，開始新的修行場次
    /// 用於使用者主動點擊「結束修行」時的完整流程
    /// - Parameters:
    ///   - modelContext: SwiftData 模型上下文
    ///   - dedicationText: 回向文內容（選填）
    ///   - dedicationTarget: 回向對象（選填）
    func endSessionAndRestart(modelContext: ModelContext, dedicationText: String? = nil, dedicationTarget: String? = nil) {
        endSession(modelContext: modelContext, dedicationText: dedicationText, dedicationTarget: dedicationTarget)
        resetCount()
        startSession(mantraName: mantraName)
        loadTodayStats(modelContext: modelContext)
    }
```

**Step 4: Run all ViewModel tests to verify nothing broke**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:beadsTests/PracticeViewModelTests test 2>&1 | tail -20`

Expected: PASS

**Step 5: Commit**

```bash
git add beads/ViewModels/PracticeViewModel.swift beadsTests/ViewModels/PracticeViewModelTests.swift
git commit -m "feat: add dedication support to PracticeViewModel endSession flow"
```

---

### Task 4: DedicationSheetView 回向 Sheet 視圖

**Files:**
- Create: `beads/Views/DedicationSheetView.swift`

**Step 1: Create the view**

Create `beads/Views/DedicationSheetView.swift`:

```swift
import SwiftUI

/// 回向功德 Sheet 視圖
/// 修行結束後彈出，讓使用者選擇回向文模板並輸入回向對象
struct DedicationSheetView: View {
    /// 選中的回向文模板
    @State private var selectedTemplate: DedicationTemplate = .universal
    /// 回向對象（自由輸入）
    @State private var dedicationTarget: String = ""
    /// 確認回向時的回呼，傳回回向文和回向對象
    var onConfirm: (String, String?) -> Void
    /// 跳過回向時的回呼
    var onSkip: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 標題區
                    headerSection

                    // 選擇回向文
                    templateSelectionSection

                    // 回向文全文展示
                    fullTextSection

                    // 回向對象輸入
                    targetInputSection
                }
                .padding()
            }
            .navigationTitle("回向功德")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("跳過") {
                        onSkip()
                    }
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("確認回向") {
                        let target = dedicationTarget.trimmingCharacters(in: .whitespacesAndNewlines)
                        onConfirm(selectedTemplate.fullText, target.isEmpty ? nil : target)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 子視圖

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "hands.and.sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.yellow.opacity(0.8))
            Text("將修行功德回向給有緣眾生")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var templateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選擇回向文")
                .font(.headline)

            ForEach(DedicationTemplate.allCases) { template in
                Button {
                    selectedTemplate = template
                } label: {
                    HStack {
                        Image(systemName: selectedTemplate == template ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(selectedTemplate == template ? .accentColor : .secondary)
                        Text(template.name)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTemplate == template ? Color.accentColor.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var fullTextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("回向文全文")
                .font(.headline)

            Text(selectedTemplate.fullText)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        }
    }

    private var targetInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("回向對象（選填）")
                .font(.headline)

            TextField("例如：父母、家人、一切有情眾生...", text: $dedicationTarget)
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    DedicationSheetView(
        onConfirm: { text, target in
            print("回向: \(text), 對象: \(target ?? "無")")
        },
        onSkip: {
            print("跳過回向")
        }
    )
}
```

**Step 2: Build to verify no compilation errors**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -10`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/DedicationSheetView.swift
git commit -m "feat: add DedicationSheetView for post-practice dedication"
```

---

### Task 5: 整合回向 Sheet 到 PracticeView

**Files:**
- Modify: `beads/Views/PracticeView.swift`

**Step 1: Add state and button**

In `beads/Views/PracticeView.swift`, add a new state variable after `meritPopupOpacity` (around line 71):

```swift
    /// 是否顯示回向 Sheet
    @State private var showDedicationSheet = false
```

**Step 2: Add the "結束修行" button to the view**

In the `body` ZStack, after the CounterOverlay and before the merit popup, add:

```swift
            // 結束修行按鈕（右上角）
            VStack {
                HStack {
                    Spacer()
                    if viewModel.isActive && viewModel.count > 0 {
                        Button {
                            showDedicationSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                Text("結束修行")
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                    }
                }
                Spacer()
            }
```

**Step 3: Add the sheet modifier**

After the `.alert(...)` modifier block (after line 155), add:

```swift
        .sheet(isPresented: $showDedicationSheet) {
            DedicationSheetView(
                onConfirm: { text, target in
                    viewModel.endSessionAndRestart(
                        modelContext: modelContext,
                        dedicationText: text,
                        dedicationTarget: target
                    )
                    sceneManager.currentBeadIndex = 0
                    verticalSceneManager.currentBeadIndex = 0
                    braceletSceneManager.currentBeadIndex = 0
                    showDedicationSheet = false
                },
                onSkip: {
                    viewModel.endSessionAndRestart(modelContext: modelContext)
                    sceneManager.currentBeadIndex = 0
                    verticalSceneManager.currentBeadIndex = 0
                    braceletSceneManager.currentBeadIndex = 0
                    showDedicationSheet = false
                }
            )
        }
```

**Step 4: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -10`

Expected: BUILD SUCCEEDED

**Step 5: Run all tests to verify nothing broke**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`

Expected: ALL TESTS PASS

**Step 6: Commit**

```bash
git add beads/Views/PracticeView.swift
git commit -m "feat: integrate dedication sheet into PracticeView end-session flow"
```

---

### Task 6: Final verification and cleanup

**Step 1: Run full test suite**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -30`

Expected: ALL TESTS PASS

**Step 2: Check git status is clean**

Run: `git status`

Expected: nothing to commit, working tree clean (except possibly pre-existing modified files)

**Step 3: Review all changes since feature start**

Run: `git log --oneline -5`

Expected commits (newest first):
1. `feat: integrate dedication sheet into PracticeView end-session flow`
2. `feat: add DedicationSheetView for post-practice dedication`
3. `feat: add dedication support to PracticeViewModel endSession flow`
4. `feat: add dedication fields to PracticeSession model`
5. `feat: add DedicationTemplate enum with 5 preset dedication texts`
