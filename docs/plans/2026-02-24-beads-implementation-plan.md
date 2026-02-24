# 念珠 App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a realistic 3D Buddhist bead counting iOS app with SceneKit rendering, haptic feedback, ambient audio, practice statistics, scripture library, and home screen widgets.

**Architecture:** SwiftUI + SceneKit for 3D bead rendering with PBR materials. SwiftData for persistence (PracticeSession, DailyRecord, Mantra, UserSettings). MVVM pattern with Observable ViewModels. Core Haptics for tactile feedback, AVFoundation for layered audio (ambient + SFX). WidgetKit for home/lock screen widgets.

**Tech Stack:** Swift 5.0, SwiftUI, SceneKit, SwiftData, Core Haptics, AVFoundation, WidgetKit, iOS 18.2+

---

## Phase 1: Foundation — Data Models & Core Infrastructure

### Task 1: Create SwiftData Models

**Files:**
- Create: `beads/Models/PracticeSession.swift`
- Create: `beads/Models/DailyRecord.swift`
- Create: `beads/Models/Mantra.swift`
- Create: `beads/Models/UserSettings.swift`
- Delete content of: `beads/Item.swift` (will be replaced)
- Test: `beadsTests/Models/PracticeSessionTests.swift`
- Test: `beadsTests/Models/DailyRecordTests.swift`
- Test: `beadsTests/Models/MantraTests.swift`

**Step 1: Write failing tests for PracticeSession**

```swift
// beadsTests/Models/PracticeSessionTests.swift
import Testing
import Foundation
@testable import beads

struct PracticeSessionTests {
    @Test func createSession() async throws {
        let session = PracticeSession(
            mantraName: "南無阿彌陀佛",
            beadsPerRound: 108
        )
        #expect(session.mantraName == "南無阿彌陀佛")
        #expect(session.beadsPerRound == 108)
        #expect(session.count == 0)
        #expect(session.rounds == 0)
        #expect(session.isActive == false)
    }

    @Test func incrementCount() async throws {
        let session = PracticeSession(
            mantraName: "南無阿彌陀佛",
            beadsPerRound: 108
        )
        session.increment()
        #expect(session.count == 1)
        #expect(session.rounds == 0)
    }

    @Test func completesRound() async throws {
        let session = PracticeSession(
            mantraName: "南無阿彌陀佛",
            beadsPerRound: 3
        )
        session.increment()
        session.increment()
        session.increment()
        #expect(session.count == 3)
        #expect(session.rounds == 1)
    }

    @Test func currentBeadPosition() async throws {
        let session = PracticeSession(
            mantraName: "南無阿彌陀佛",
            beadsPerRound: 108
        )
        #expect(session.currentBeadIndex == 0)
        session.increment()
        #expect(session.currentBeadIndex == 1)
    }

    @Test func sessionDuration() async throws {
        let session = PracticeSession(
            mantraName: "南無阿彌陀佛",
            beadsPerRound: 108
        )
        session.startTime = Date().addingTimeInterval(-60)
        session.endTime = Date()
        #expect(session.duration >= 59 && session.duration <= 61)
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`
Expected: FAIL — `PracticeSession` not found

**Step 3: Implement PracticeSession model**

```swift
// beads/Models/PracticeSession.swift
import Foundation
import SwiftData

@Model
final class PracticeSession {
    var mantraName: String
    var beadsPerRound: Int
    var count: Int
    var rounds: Int
    var startTime: Date?
    var endTime: Date?
    var isActive: Bool

    var currentBeadIndex: Int {
        count % beadsPerRound
    }

    var duration: TimeInterval {
        guard let start = startTime, let end = endTime else { return 0 }
        return end.timeIntervalSince(start)
    }

    init(mantraName: String, beadsPerRound: Int = 108) {
        self.mantraName = mantraName
        self.beadsPerRound = beadsPerRound
        self.count = 0
        self.rounds = 0
        self.isActive = false
    }

    func increment() {
        count += 1
        if count % beadsPerRound == 0 {
            rounds = count / beadsPerRound
        }
    }
}
```

**Step 4: Write failing tests for DailyRecord**

```swift
// beadsTests/Models/DailyRecordTests.swift
import Testing
import Foundation
@testable import beads

struct DailyRecordTests {
    @Test func createDailyRecord() async throws {
        let record = DailyRecord(date: Date())
        #expect(record.totalCount == 0)
        #expect(record.totalDuration == 0)
        #expect(record.sessionCount == 0)
    }

    @Test func addSessionToRecord() async throws {
        let record = DailyRecord(date: Date())
        record.addSession(count: 108, duration: 300)
        #expect(record.totalCount == 108)
        #expect(record.totalDuration == 300)
        #expect(record.sessionCount == 1)
    }

    @Test func multipleSessions() async throws {
        let record = DailyRecord(date: Date())
        record.addSession(count: 108, duration: 300)
        record.addSession(count: 216, duration: 600)
        #expect(record.totalCount == 324)
        #expect(record.totalDuration == 900)
        #expect(record.sessionCount == 2)
    }
}
```

**Step 5: Implement DailyRecord model**

```swift
// beads/Models/DailyRecord.swift
import Foundation
import SwiftData

@Model
final class DailyRecord {
    var date: Date
    var totalCount: Int
    var totalDuration: TimeInterval
    var sessionCount: Int

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
        self.totalCount = 0
        self.totalDuration = 0
        self.sessionCount = 0
    }

    func addSession(count: Int, duration: TimeInterval) {
        totalCount += count
        totalDuration += duration
        sessionCount += 1
    }
}
```

**Step 6: Implement Mantra model**

```swift
// beads/Models/Mantra.swift
import Foundation
import SwiftData

@Model
final class Mantra {
    var name: String
    var originalText: String
    var pinyinText: String
    var descriptionText: String
    var category: String
    var suggestedCount: Int
    var sortOrder: Int

    init(
        name: String,
        originalText: String,
        pinyinText: String = "",
        descriptionText: String = "",
        category: String = "淨土宗",
        suggestedCount: Int = 108,
        sortOrder: Int = 0
    ) {
        self.name = name
        self.originalText = originalText
        self.pinyinText = pinyinText
        self.descriptionText = descriptionText
        self.category = category
        self.suggestedCount = suggestedCount
        self.sortOrder = sortOrder
    }
}
```

**Step 7: Write failing tests for Mantra**

```swift
// beadsTests/Models/MantraTests.swift
import Testing
import Foundation
@testable import beads

struct MantraTests {
    @Test func createMantra() async throws {
        let mantra = Mantra(
            name: "南無阿彌陀佛",
            originalText: "南無阿彌陀佛",
            pinyinText: "Nā mó ā mí tuó fó",
            descriptionText: "淨土宗核心佛號",
            category: "淨土宗",
            suggestedCount: 108
        )
        #expect(mantra.name == "南無阿彌陀佛")
        #expect(mantra.category == "淨土宗")
        #expect(mantra.suggestedCount == 108)
    }
}
```

**Step 8: Implement UserSettings model**

```swift
// beads/Models/UserSettings.swift
import Foundation
import SwiftData

@Model
final class UserSettings {
    var currentBeadStyle: String
    var beadsPerRound: Int
    var soundEnabled: Bool
    var hapticEnabled: Bool
    var ambientSoundEnabled: Bool
    var ambientVolume: Float
    var sfxVolume: Float
    var keepScreenOn: Bool

    init() {
        self.currentBeadStyle = "小葉紫檀"
        self.beadsPerRound = 108
        self.soundEnabled = true
        self.hapticEnabled = true
        self.ambientSoundEnabled = true
        self.ambientVolume = 0.5
        self.sfxVolume = 0.8
        self.keepScreenOn = true
    }
}
```

**Step 9: Run all model tests**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`
Expected: ALL PASS

**Step 10: Update beadsApp.swift schema and remove Item.swift**

```swift
// beads/beadsApp.swift
import SwiftUI
import SwiftData

@main
struct beadsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PracticeSession.self,
            DailyRecord.self,
            Mantra.self,
            UserSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

Delete `beads/Item.swift` (no longer needed).

**Step 11: Commit**

```bash
git add beads/Models/ beadsTests/Models/ beads/beadsApp.swift
git rm beads/Item.swift
git commit -m "feat: add SwiftData models for PracticeSession, DailyRecord, Mantra, UserSettings"
```

---

### Task 2: Create Practice ViewModel

**Files:**
- Create: `beads/ViewModels/PracticeViewModel.swift`
- Test: `beadsTests/ViewModels/PracticeViewModelTests.swift`

**Step 1: Write failing tests for PracticeViewModel**

```swift
// beadsTests/ViewModels/PracticeViewModelTests.swift
import Testing
import Foundation
@testable import beads

struct PracticeViewModelTests {
    @Test func initialState() async throws {
        let vm = PracticeViewModel()
        #expect(vm.count == 0)
        #expect(vm.rounds == 0)
        #expect(vm.currentBeadIndex == 0)
        #expect(vm.isActive == false)
        #expect(vm.beadsPerRound == 108)
    }

    @Test func startSession() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "南無阿彌陀佛")
        #expect(vm.isActive == true)
        #expect(vm.mantraName == "南無阿彌陀佛")
    }

    @Test func incrementBead() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "南無阿彌陀佛")
        vm.incrementBead()
        #expect(vm.count == 1)
        #expect(vm.currentBeadIndex == 1)
    }

    @Test func roundCompletion() async throws {
        let vm = PracticeViewModel()
        vm.beadsPerRound = 3
        vm.startSession(mantraName: "test")
        vm.incrementBead()
        vm.incrementBead()
        vm.incrementBead()
        #expect(vm.rounds == 1)
        #expect(vm.didCompleteRound == true)
    }

    @Test func undoLastIncrement() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "test")
        vm.incrementBead()
        vm.incrementBead()
        vm.incrementBead()
        vm.undo()
        #expect(vm.count == 2)
    }

    @Test func undoLimit() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "test")
        vm.incrementBead()
        vm.undo()
        vm.undo() // should not go below 0
        #expect(vm.count == 0)
    }

    @Test func todayCount() async throws {
        let vm = PracticeViewModel()
        #expect(vm.todayCount == 0)
    }

    @Test func streakDays() async throws {
        let vm = PracticeViewModel()
        #expect(vm.streakDays == 0)
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`
Expected: FAIL — `PracticeViewModel` not found

**Step 3: Implement PracticeViewModel**

```swift
// beads/ViewModels/PracticeViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
final class PracticeViewModel {
    var count: Int = 0
    var rounds: Int = 0
    var beadsPerRound: Int = 108
    var isActive: Bool = false
    var mantraName: String = "南無阿彌陀佛"
    var didCompleteRound: Bool = false
    var todayCount: Int = 0
    var streakDays: Int = 0

    private var undoStack: [Int] = []
    private let maxUndoCount = 5
    private var sessionStartTime: Date?

    var currentBeadIndex: Int {
        count % beadsPerRound
    }

    func startSession(mantraName: String) {
        self.mantraName = mantraName
        self.isActive = true
        self.sessionStartTime = Date()
        self.didCompleteRound = false
    }

    func incrementBead() {
        guard isActive else { return }
        undoStack.append(count)
        if undoStack.count > maxUndoCount {
            undoStack.removeFirst()
        }
        count += 1
        let newRounds = count / beadsPerRound
        if newRounds > rounds {
            rounds = newRounds
            didCompleteRound = true
        } else {
            didCompleteRound = false
        }
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        count = previous
        rounds = count / beadsPerRound
        didCompleteRound = false
    }

    func endSession(modelContext: ModelContext) {
        guard isActive else { return }
        isActive = false
        let endTime = Date()

        let session = PracticeSession(mantraName: mantraName, beadsPerRound: beadsPerRound)
        session.count = count
        session.rounds = rounds
        session.startTime = sessionStartTime
        session.endTime = endTime
        session.isActive = false
        modelContext.insert(session)

        updateDailyRecord(modelContext: modelContext, count: count, duration: endTime.timeIntervalSince(sessionStartTime ?? endTime))

        try? modelContext.save()
    }

    func loadTodayStats(modelContext: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.date == today }
        )
        if let record = try? modelContext.fetch(descriptor).first {
            todayCount = record.totalCount
        } else {
            todayCount = 0
        }
        streakDays = calculateStreak(modelContext: modelContext)
    }

    private func updateDailyRecord(modelContext: ModelContext, count: Int, duration: TimeInterval) {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.date == today }
        )
        let record: DailyRecord
        if let existing = try? modelContext.fetch(descriptor).first {
            record = existing
        } else {
            record = DailyRecord(date: today)
            modelContext.insert(record)
        }
        record.addSession(count: count, duration: duration)
        todayCount = record.totalCount
    }

    private func calculateStreak(modelContext: ModelContext) -> Int {
        let descriptor = FetchDescriptor<DailyRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let records = try? modelContext.fetch(descriptor), !records.isEmpty else { return 0 }

        var streak = 0
        var expectedDate = Calendar.current.startOfDay(for: Date())

        for record in records {
            let recordDate = Calendar.current.startOfDay(for: record.date)
            if recordDate == expectedDate && record.totalCount > 0 {
                streak += 1
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if recordDate < expectedDate {
                break
            }
        }
        return streak
    }

    func resetCount() {
        count = 0
        rounds = 0
        undoStack.removeAll()
        didCompleteRound = false
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add beads/ViewModels/ beadsTests/ViewModels/
git commit -m "feat: add PracticeViewModel with count, undo, round tracking, streak"
```

---

## Phase 2: Tab Navigation & Basic UI Shell

### Task 3: Create Tab-based Navigation

**Files:**
- Modify: `beads/ContentView.swift` (replace entirely)
- Create: `beads/Views/PracticeView.swift`
- Create: `beads/Views/RecordsView.swift`
- Create: `beads/Views/ScriptureView.swift`
- Create: `beads/Views/SettingsView.swift`

**Step 1: Replace ContentView with TabView**

```swift
// beads/ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("修行", systemImage: "circle.circle") {
                PracticeView()
            }
            Tab("記錄", systemImage: "chart.bar") {
                RecordsView()
            }
            Tab("經藏", systemImage: "book") {
                ScriptureView()
            }
            Tab("設定", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            PracticeSession.self,
            DailyRecord.self,
            Mantra.self,
            UserSettings.self,
        ], inMemory: true)
}
```

**Step 2: Create placeholder views**

```swift
// beads/Views/PracticeView.swift
import SwiftUI

struct PracticeView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("修行")
                .font(.largeTitle)
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    PracticeView()
}
```

```swift
// beads/Views/RecordsView.swift
import SwiftUI

struct RecordsView: View {
    var body: some View {
        NavigationStack {
            Text("修行記錄")
                .navigationTitle("記錄")
        }
    }
}

#Preview {
    RecordsView()
}
```

```swift
// beads/Views/ScriptureView.swift
import SwiftUI

struct ScriptureView: View {
    var body: some View {
        NavigationStack {
            Text("經藏")
                .navigationTitle("經藏")
        }
    }
}

#Preview {
    ScriptureView()
}
```

```swift
// beads/Views/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Text("設定")
                .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView()
}
```

**Step 3: Build to verify compilation**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add beads/ContentView.swift beads/Views/
git commit -m "feat: add tab-based navigation with Practice, Records, Scripture, Settings"
```

---

## Phase 3: 3D Bead Rendering with SceneKit

### Task 4: Create SceneKit Bead Scene

**Files:**
- Create: `beads/Scene/BeadSceneManager.swift`
- Create: `beads/Scene/BeadMaterials.swift`
- Create: `beads/Views/Components/BeadSceneView.swift`

**Step 1: Create BeadMaterials — material definitions for 5 bead types**

```swift
// beads/Scene/BeadMaterials.swift
import SceneKit

enum BeadMaterialType: String, CaseIterable, Identifiable {
    case zitan = "小葉紫檀"
    case bodhi = "菩提子"
    case starMoonBodhi = "星月菩提"
    case huanghuali = "黃花梨"
    case amber = "琥珀蜜蠟"

    var id: String { rawValue }

    var diffuseColor: UIColor {
        switch self {
        case .zitan: return UIColor(red: 0.35, green: 0.12, blue: 0.08, alpha: 1.0)
        case .bodhi: return UIColor(red: 0.85, green: 0.80, blue: 0.70, alpha: 1.0)
        case .starMoonBodhi: return UIColor(red: 0.90, green: 0.85, blue: 0.70, alpha: 1.0)
        case .huanghuali: return UIColor(red: 0.75, green: 0.58, blue: 0.28, alpha: 1.0)
        case .amber: return UIColor(red: 0.90, green: 0.65, blue: 0.20, alpha: 0.85)
        }
    }

    var roughness: CGFloat {
        switch self {
        case .zitan: return 0.3
        case .bodhi: return 0.6
        case .starMoonBodhi: return 0.5
        case .huanghuali: return 0.25
        case .amber: return 0.15
        }
    }

    var metalness: CGFloat {
        switch self {
        case .amber: return 0.05
        default: return 0.0
        }
    }

    func applyTo(_ material: SCNMaterial) {
        material.lightingModel = .physicallyBased
        material.diffuse.contents = diffuseColor
        material.roughness.contents = roughness
        material.metalness.contents = metalness
        if self == .amber {
            material.transparency = 0.85
            material.transparencyMode = .dualLayer
        }
    }
}
```

**Step 2: Create BeadSceneManager — builds and manages the 3D scene**

```swift
// beads/Scene/BeadSceneManager.swift
import SceneKit
import Foundation

final class BeadSceneManager {
    let scene: SCNScene
    private var beadNodes: [SCNNode] = []
    private let beadCount: Int
    private let radius: Float = 3.0
    private let beadRadius: Float = 0.25

    var currentBeadIndex: Int = 0 {
        didSet { highlightCurrentBead() }
    }

    var materialType: BeadMaterialType = .zitan {
        didSet { applyMaterial() }
    }

    init(beadCount: Int = 108) {
        self.beadCount = min(beadCount, 108)
        self.scene = SCNScene()
        setupScene()
    }

    private func setupScene() {
        scene.background.contents = UIColor.black

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 45
        cameraNode.position = SCNVector3(0, 0, 8)
        cameraNode.name = "camera"
        scene.rootNode.addChildNode(cameraNode)

        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 300
        ambientLight.light?.color = UIColor(white: 0.8, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)

        // Directional light (key light)
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 800
        keyLight.light?.castsShadow = true
        keyLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
        scene.rootNode.addChildNode(keyLight)

        // Fill light
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.intensity = 400
        fillLight.eulerAngles = SCNVector3(-Float.pi / 6, -Float.pi / 3, 0)
        scene.rootNode.addChildNode(fillLight)

        createBeads()
        createString()
    }

    private func createBeads() {
        let displayCount = min(beadCount, 54) // Display up to 54 beads visually in the circle
        let beadGeometry = SCNSphere(radius: CGFloat(beadRadius))
        beadGeometry.segmentCount = 48

        let material = SCNMaterial()
        materialType.applyTo(material)
        beadGeometry.materials = [material]

        for i in 0..<displayCount {
            let angle = Float(i) / Float(displayCount) * Float.pi * 2 - Float.pi / 2
            let x = radius * cos(angle)
            let y = radius * sin(angle)

            let node = SCNNode(geometry: beadGeometry.copy() as? SCNGeometry)
            node.position = SCNVector3(x, y, 0)
            node.name = "bead_\(i)"
            scene.rootNode.addChildNode(node)
            beadNodes.append(node)
        }

        // Guru bead (larger, at top)
        let guruGeometry = SCNSphere(radius: CGFloat(beadRadius * 1.4))
        guruGeometry.segmentCount = 48
        let guruMaterial = SCNMaterial()
        materialType.applyTo(guruMaterial)
        guruGeometry.materials = [guruMaterial]

        let guruNode = SCNNode(geometry: guruGeometry)
        guruNode.position = SCNVector3(0, -radius, 0)
        guruNode.name = "guru_bead"
        scene.rootNode.addChildNode(guruNode)
    }

    private func createString() {
        let displayCount = min(beadCount, 54)
        let path = UIBezierPath()
        for i in 0...displayCount {
            let angle = CGFloat(Float(i) / Float(displayCount) * Float.pi * 2 - Float.pi / 2)
            let x = CGFloat(radius) * cos(angle)
            let y = CGFloat(radius) * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.close()

        let shape = SCNShape(path: path, extrusionDepth: 0.02)
        let stringMaterial = SCNMaterial()
        stringMaterial.diffuse.contents = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        shape.materials = [stringMaterial]

        let stringNode = SCNNode(geometry: shape)
        stringNode.name = "string"
        scene.rootNode.addChildNode(stringNode)
    }

    private func highlightCurrentBead() {
        let displayCount = min(beadCount, 54)
        let displayIndex = currentBeadIndex % displayCount

        // Reset all beads
        for (i, node) in beadNodes.enumerated() {
            let scale: Float = (i == displayIndex) ? 1.3 : 1.0
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.2
            node.scale = SCNVector3(scale, scale, scale)
            SCNTransaction.commit()
        }
    }

    private func applyMaterial() {
        for node in beadNodes {
            if let geometry = node.geometry, let material = geometry.materials.first {
                materialType.applyTo(material)
            }
        }
        if let guru = scene.rootNode.childNode(withName: "guru_bead", recursively: false),
           let material = guru.geometry?.materials.first {
            materialType.applyTo(material)
        }
    }

    func animateBeadForward() {
        let displayCount = min(beadCount, 54)
        let index = currentBeadIndex % displayCount
        guard index < beadNodes.count else { return }
        let node = beadNodes[index]

        // Quick scale pulse animation
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        node.scale = SCNVector3(1.5, 1.5, 1.5)
        SCNTransaction.completionBlock = {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.15
            node.scale = SCNVector3(1.0, 1.0, 1.0)
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
    }
}
```

**Step 3: Create BeadSceneView — SwiftUI wrapper for SceneKit**

```swift
// beads/Views/Components/BeadSceneView.swift
import SwiftUI
import SceneKit

struct BeadSceneView: UIViewRepresentable {
    let sceneManager: BeadSceneManager
    var onSwipeUp: (() -> Void)?

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = sceneManager.scene
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = .black

        let swipeUp = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipe(_:)))
        swipeUp.direction = .up
        scnView.addGestureRecognizer(swipeUp)

        let swipeLeft = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipe(_:)))
        swipeLeft.direction = .left
        scnView.addGestureRecognizer(swipeLeft)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.onSwipeUp = onSwipeUp
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onSwipeUp: onSwipeUp)
    }

    class Coordinator: NSObject {
        var onSwipeUp: (() -> Void)?

        init(onSwipeUp: (() -> Void)?) {
            self.onSwipeUp = onSwipeUp
        }

        @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
            onSwipeUp?()
        }
    }
}
```

**Step 4: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add beads/Scene/ beads/Views/Components/
git commit -m "feat: add SceneKit 3D bead rendering with PBR materials and swipe gesture"
```

---

## Phase 4: Haptic & Audio Engine

### Task 5: Create Haptic Engine

**Files:**
- Create: `beads/Services/HapticService.swift`

**Step 1: Implement HapticService**

```swift
// beads/Services/HapticService.swift
import CoreHaptics
import UIKit

final class HapticService {
    private var engine: CHHapticEngine?
    var isEnabled: Bool = true

    init() {
        setupEngine()
    }

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            print("Haptic engine error: \(error)")
        }
    }

    func playBeadTap() {
        guard isEnabled else { return }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func playRoundComplete() {
        guard isEnabled else { return }
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics, let engine else {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
            return
        }

        do {
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)

            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.15)
            let event3 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.3)

            let pattern = try CHHapticPattern(events: [event1, event2, event3], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic pattern error: \(error)")
        }
    }
}
```

**Step 2: Build and commit**

```bash
git add beads/Services/HapticService.swift
git commit -m "feat: add Core Haptics service for bead tap and round completion"
```

---

### Task 6: Create Audio Engine

**Files:**
- Create: `beads/Services/AudioService.swift`

**Step 1: Implement AudioService**

```swift
// beads/Services/AudioService.swift
import AVFoundation

final class AudioService {
    private var ambientPlayer: AVAudioPlayer?
    private var sfxPlayer: AVAudioPlayer?

    var isSFXEnabled: Bool = true
    var isAmbientEnabled: Bool = true
    var ambientVolume: Float = 0.5 {
        didSet { ambientPlayer?.volume = ambientVolume }
    }
    var sfxVolume: Float = 0.8

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    func playBeadClick() {
        guard isSFXEnabled else { return }
        playSound(named: "bead_click", volume: sfxVolume)
    }

    func playRoundComplete() {
        guard isSFXEnabled else { return }
        playSound(named: "round_complete", volume: sfxVolume)
    }

    func startAmbient(named name: String) {
        guard isAmbientEnabled else { return }
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            ambientPlayer = try AVAudioPlayer(contentsOf: url)
            ambientPlayer?.numberOfLoops = -1 // loop forever
            ambientPlayer?.volume = ambientVolume
            ambientPlayer?.play()
        } catch {
            print("Ambient audio error: \(error)")
        }
    }

    func stopAmbient() {
        ambientPlayer?.stop()
        ambientPlayer = nil
    }

    func fadeOutAmbient(duration: TimeInterval = 1.0) {
        guard let player = ambientPlayer else { return }
        let steps = 20
        let interval = duration / Double(steps)
        let volumeStep = player.volume / Float(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                player.volume -= volumeStep
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.ambientPlayer?.stop()
            self?.ambientPlayer = nil
        }
    }

    private func playSound(named name: String, volume: Float) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") ??
                        Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            sfxPlayer = try AVAudioPlayer(contentsOf: url)
            sfxPlayer?.volume = volume
            sfxPlayer?.play()
        } catch {
            print("SFX error: \(error)")
        }
    }
}
```

**Step 2: Add `audio` background mode to Info.plist**

Add `audio` to UIBackgroundModes array in `beads/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>audio</string>
</array>
```

**Step 3: Build and commit**

```bash
git add beads/Services/AudioService.swift beads/Info.plist
git commit -m "feat: add AudioService with ambient music and SFX support"
```

---

## Phase 5: Full Practice View

### Task 7: Build the Complete Practice View

**Files:**
- Modify: `beads/Views/PracticeView.swift` (replace placeholder)
- Create: `beads/Views/Components/CounterOverlay.swift`

**Step 1: Create CounterOverlay component**

```swift
// beads/Views/Components/CounterOverlay.swift
import SwiftUI

struct CounterOverlay: View {
    let count: Int
    let rounds: Int
    let todayCount: Int
    let streakDays: Int
    let mantraName: String

    var body: some View {
        VStack {
            // Top bar
            HStack {
                Text(mantraName)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Round counter
            if rounds > 0 {
                Text("第 \(rounds) 圈")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 4)
            }

            Spacer()

            // Center count (rendered over the bead circle)
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("總計數")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            // Mantra text
            Text(mantraName)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.bottom, 8)

            // Bottom stats bar
            HStack {
                Label("今日：\(todayCount)", systemImage: "sun.min")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Label("\(streakDays) 天", systemImage: "flame")
                    .font(.footnote)
                    .foregroundStyle(.orange.opacity(0.9))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
}
```

**Step 2: Build the full PracticeView**

```swift
// beads/Views/PracticeView.swift
import SwiftUI
import SwiftData

struct PracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PracticeViewModel()
    @State private var sceneManager = BeadSceneManager()
    @State private var hapticService = HapticService()
    @State private var audioService = AudioService()
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            // 3D Bead Scene
            BeadSceneView(sceneManager: sceneManager) {
                onBeadSwipe()
            }
            .ignoresSafeArea()

            // Counter overlay
            CounterOverlay(
                count: viewModel.count,
                rounds: viewModel.rounds,
                todayCount: viewModel.todayCount + viewModel.count,
                streakDays: viewModel.streakDays,
                mantraName: viewModel.mantraName
            )
        }
        .onAppear {
            viewModel.startSession(mantraName: "南無阿彌陀佛")
            viewModel.loadTodayStats(modelContext: modelContext)
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            viewModel.endSession(modelContext: modelContext)
            audioService.fadeOutAmbient()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onShake {
            if viewModel.count > 0 {
                viewModel.undo()
                sceneManager.currentBeadIndex = viewModel.currentBeadIndex
            }
        }
        .alert("確定要重置計數嗎？", isPresented: $showResetConfirm) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                viewModel.resetCount()
                sceneManager.currentBeadIndex = 0
            }
        } message: {
            Text("此操作將清除本次修行的所有計數。")
        }
    }

    private func onBeadSwipe() {
        viewModel.incrementBead()
        sceneManager.currentBeadIndex = viewModel.currentBeadIndex
        sceneManager.animateBeadForward()
        hapticService.playBeadTap()
        audioService.playBeadClick()

        if viewModel.didCompleteRound {
            hapticService.playRoundComplete()
            audioService.playRoundComplete()
        }
    }
}

// Shake gesture extension
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeDetector(action: action))
    }
}

struct ShakeDetector: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name("deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}
```

**Step 3: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add beads/Views/
git commit -m "feat: build complete PracticeView with 3D beads, counter, haptics, audio"
```

---

## Phase 6: Records & Statistics View

### Task 8: Build Records View with Charts

**Files:**
- Modify: `beads/Views/RecordsView.swift` (replace placeholder)
- Create: `beads/Views/Components/StatsCardView.swift`
- Create: `beads/Views/Components/PracticeCalendarView.swift`
- Create: `beads/ViewModels/StatsViewModel.swift`

**Step 1: Create StatsViewModel**

```swift
// beads/ViewModels/StatsViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
final class StatsViewModel {
    var todayCount: Int = 0
    var todayDuration: TimeInterval = 0
    var todaySessions: Int = 0
    var streakDays: Int = 0
    var weeklyData: [(date: Date, count: Int)] = []
    var monthlyRecords: [DailyRecord] = []

    func load(modelContext: ModelContext) {
        loadToday(modelContext: modelContext)
        loadWeekly(modelContext: modelContext)
        loadMonthly(modelContext: modelContext)
        streakDays = calculateStreak(modelContext: modelContext)
    }

    private func loadToday(modelContext: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.date == today }
        )
        if let record = try? modelContext.fetch(descriptor).first {
            todayCount = record.totalCount
            todayDuration = record.totalDuration
            todaySessions = record.sessionCount
        }
    }

    private func loadWeekly(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return }

        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.date >= weekAgo },
            sortBy: [SortDescriptor(\.date)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []

        weeklyData = (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: weekAgo)!
            let dayStart = calendar.startOfDay(for: date)
            let count = records.first { calendar.startOfDay(for: $0.date) == dayStart }?.totalCount ?? 0
            return (date: date, count: count)
        }
    }

    private func loadMonthly(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: today) else { return }

        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.date >= monthAgo },
            sortBy: [SortDescriptor(\.date)]
        )
        monthlyRecords = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func calculateStreak(modelContext: ModelContext) -> Int {
        let descriptor = FetchDescriptor<DailyRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let records = try? modelContext.fetch(descriptor), !records.isEmpty else { return 0 }

        var streak = 0
        var expectedDate = Calendar.current.startOfDay(for: Date())

        for record in records {
            let recordDate = Calendar.current.startOfDay(for: record.date)
            if recordDate == expectedDate && record.totalCount > 0 {
                streak += 1
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if recordDate < expectedDate {
                break
            }
        }
        return streak
    }
}
```

**Step 2: Create StatsCardView**

```swift
// beads/Views/Components/StatsCardView.swift
import SwiftUI

struct StatsCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2.bold())
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

**Step 3: Create PracticeCalendarView (heatmap)**

```swift
// beads/Views/Components/PracticeCalendarView.swift
import SwiftUI

struct PracticeCalendarView: View {
    let records: [DailyRecord]

    var body: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        VStack(alignment: .leading, spacing: 4) {
            Text("修行日曆")
                .font(.headline)
                .padding(.bottom, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 3) {
                ForEach(0..<35, id: \.self) { offset in
                    let date = calendar.date(byAdding: .day, value: -(34 - offset), to: today)!
                    let count = records.first {
                        calendar.startOfDay(for: $0.date) == calendar.startOfDay(for: date)
                    }?.totalCount ?? 0

                    RoundedRectangle(cornerRadius: 3)
                        .fill(heatColor(for: count))
                        .frame(height: 20)
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("少")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach([0, 50, 200, 500, 1000], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatColor(for: level))
                        .frame(width: 12, height: 12)
                }
                Text("多")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    private func heatColor(for count: Int) -> Color {
        switch count {
        case 0: return Color(.systemGray5)
        case 1..<100: return Color.orange.opacity(0.3)
        case 100..<300: return Color.orange.opacity(0.5)
        case 300..<600: return Color.orange.opacity(0.7)
        default: return Color.orange.opacity(0.95)
        }
    }
}
```

**Step 4: Build the full RecordsView**

```swift
// beads/Views/RecordsView.swift
import SwiftUI
import SwiftData
import Charts

struct RecordsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Today stats
                    HStack(spacing: 12) {
                        StatsCardView(
                            title: "今日計數",
                            value: "\(viewModel.todayCount)",
                            subtitle: "\(viewModel.todaySessions) 次修行",
                            icon: "sun.min"
                        )
                        StatsCardView(
                            title: "連續修行",
                            value: "\(viewModel.streakDays) 天",
                            subtitle: "持續精進",
                            icon: "flame"
                        )
                    }

                    // Weekly chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("本週修行")
                            .font(.headline)

                        Chart(viewModel.weeklyData, id: \.date) { item in
                            BarMark(
                                x: .value("日期", item.date, unit: .day),
                                y: .value("計數", item.count)
                            )
                            .foregroundStyle(Color.orange.gradient)
                            .cornerRadius(4)
                        }
                        .frame(height: 180)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Calendar heatmap
                    PracticeCalendarView(records: viewModel.monthlyRecords)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Duration
                    StatsCardView(
                        title: "今日時長",
                        value: formatDuration(viewModel.todayDuration),
                        subtitle: "專注修行",
                        icon: "clock"
                    )
                }
                .padding()
            }
            .navigationTitle("記錄")
            .onAppear {
                viewModel.load(modelContext: modelContext)
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes < 60 {
            return "\(minutes) 分鐘"
        }
        let hours = minutes / 60
        let remaining = minutes % 60
        return "\(hours) 小時 \(remaining) 分"
    }
}
```

**Step 5: Build and commit**

```bash
git add beads/Views/ beads/ViewModels/StatsViewModel.swift
git commit -m "feat: add Records view with stats cards, weekly chart, practice calendar heatmap"
```

---

## Phase 7: Scripture / Content Library

### Task 9: Build Scripture View and Seed Data

**Files:**
- Modify: `beads/Views/ScriptureView.swift`
- Create: `beads/Views/Scripture/MantraListView.swift`
- Create: `beads/Views/Scripture/MantraDetailView.swift`
- Create: `beads/Views/Scripture/ScriptureReadingView.swift`
- Create: `beads/Services/MantraSeedData.swift`

**Step 1: Create MantraSeedData**

```swift
// beads/Services/MantraSeedData.swift
import SwiftData

struct MantraSeedData {
    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Mantra>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let mantras: [(String, String, String, String, String, Int, Int)] = [
            ("南無阿彌陀佛", "南無阿彌陀佛", "Nā mó ā mí tuó fó", "淨土宗核心佛號。稱念阿彌陀佛名號，祈願往生西方極樂世界。", "淨土宗", 108, 0),
            ("南無觀世音菩薩", "南無觀世音菩薩", "Nā mó guān shì yīn pú sà", "觀世音菩薩大慈大悲，救苦救難，聞聲救苦。", "淨土宗", 108, 1),
            ("南無地藏王菩薩", "南無地藏王菩薩", "Nā mó dì zàng wáng pú sà", "地藏菩薩發願「地獄不空，誓不成佛」。", "淨土宗", 108, 2),
            ("南無藥師琉璃光如來", "南無藥師琉璃光如來", "Nā mó yào shī liú lí guāng rú lái", "藥師佛為東方淨琉璃世界教主，消災延壽。", "淨土宗", 108, 3),
            ("六字大明咒", "嗡嘛呢唄美吽", "Ǎn ma ní bēi měi hōng", "觀世音菩薩心咒，蘊含諸佛無盡的慈悲與加持。", "咒語", 108, 4),
            ("大悲咒", "南無喝囉怛那哆囉夜耶⋯⋯", "Nā mó hé là dá nā duō là yè yē...", "千手千眼觀世音菩薩廣大圓滿無礙大悲心陀羅尼。全咒共84句。", "咒語", 84, 5),
            ("往生咒", "南無阿彌多婆夜⋯⋯", "Nā mó ā mí duō pó yè...", "拔一切業障根本得生淨土陀羅尼。", "咒語", 21, 6),
            ("藥師灌頂真言", "南謨薄伽伐帝⋯⋯", "Nā mó bó qié fá dì...", "藥師琉璃光如來本願功德經中的核心咒語。", "咒語", 108, 7),
            ("準提神咒", "稽首皈依蘇悉帝⋯⋯", "Jī shǒu guī yī sū xī dì...", "準提菩薩咒，能滅十惡五逆一切罪障。", "咒語", 108, 8),
        ]

        for (name, text, pinyin, desc, category, count, order) in mantras {
            let mantra = Mantra(
                name: name,
                originalText: text,
                pinyinText: pinyin,
                descriptionText: desc,
                category: category,
                suggestedCount: count,
                sortOrder: order
            )
            modelContext.insert(mantra)
        }
        try? modelContext.save()
    }
}
```

**Step 2: Create MantraListView and MantraDetailView**

```swift
// beads/Views/Scripture/MantraListView.swift
import SwiftUI
import SwiftData

struct MantraListView: View {
    @Query(sort: \Mantra.sortOrder) private var mantras: [Mantra]

    var body: some View {
        let grouped = Dictionary(grouping: mantras, by: \.category)
        let categories = grouped.keys.sorted()

        List {
            ForEach(categories, id: \.self) { category in
                Section(header: Text(category)) {
                    ForEach(grouped[category] ?? [], id: \.name) { mantra in
                        NavigationLink(destination: MantraDetailView(mantra: mantra)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mantra.name)
                                    .font(.body)
                                Text(mantra.pinyinText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
}
```

```swift
// beads/Views/Scripture/MantraDetailView.swift
import SwiftUI

struct MantraDetailView: View {
    let mantra: Mantra

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text(mantra.name)
                    .font(.largeTitle.bold())

                // Original text
                VStack(alignment: .leading, spacing: 8) {
                    Text("原文")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(mantra.originalText)
                        .font(.title2)
                }

                // Pinyin
                VStack(alignment: .leading, spacing: 8) {
                    Text("拼音")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(mantra.pinyinText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("說明")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(mantra.descriptionText)
                        .font(.body)
                }

                // Suggested count
                HStack {
                    Image(systemName: "target")
                    Text("建議每次持誦 \(mantra.suggestedCount) 遍")
                        .font(.subheadline)
                }
                .foregroundStyle(.orange)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
        .navigationTitle(mantra.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

**Step 3: Build the full ScriptureView**

```swift
// beads/Views/ScriptureView.swift
import SwiftUI
import SwiftData

struct ScriptureView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            MantraListView()
                .navigationTitle("經藏")
                .onAppear {
                    MantraSeedData.seedIfNeeded(modelContext: modelContext)
                }
        }
    }
}
```

**Step 4: Build and commit**

```bash
git add beads/Views/Scripture/ beads/Views/ScriptureView.swift beads/Services/MantraSeedData.swift
git commit -m "feat: add Scripture view with mantra library, detail view, and seed data"
```

---

## Phase 8: Settings View

### Task 10: Build Settings View

**Files:**
- Modify: `beads/Views/SettingsView.swift` (replace placeholder)

**Step 1: Implement full SettingsView**

```swift
// beads/Views/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var settings: UserSettings?

    // Local state bound to settings
    @State private var currentBeadStyle: String = "小葉紫檀"
    @State private var beadsPerRound: Int = 108
    @State private var soundEnabled: Bool = true
    @State private var hapticEnabled: Bool = true
    @State private var ambientSoundEnabled: Bool = true
    @State private var ambientVolume: Float = 0.5
    @State private var sfxVolume: Float = 0.8
    @State private var keepScreenOn: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                // Bead style
                Section("佛珠樣式") {
                    Picker("材質", selection: $currentBeadStyle) {
                        ForEach(BeadMaterialType.allCases) { material in
                            Text(material.rawValue).tag(material.rawValue)
                        }
                    }
                }

                // Counting
                Section("計數設定") {
                    Picker("每圈珠數", selection: $beadsPerRound) {
                        Text("18 顆").tag(18)
                        Text("21 顆").tag(21)
                        Text("36 顆").tag(36)
                        Text("54 顆").tag(54)
                        Text("108 顆").tag(108)
                    }
                }

                // Sound
                Section("音效") {
                    Toggle("撥珠音效", isOn: $soundEnabled)
                    Toggle("觸感反饋", isOn: $hapticEnabled)
                    Toggle("背景音樂", isOn: $ambientSoundEnabled)
                    if ambientSoundEnabled {
                        VStack(alignment: .leading) {
                            Text("背景音量")
                                .font(.caption)
                            Slider(value: $ambientVolume, in: 0...1)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("音效音量")
                            .font(.caption)
                        Slider(value: $sfxVolume, in: 0...1)
                    }
                }

                // Display
                Section("顯示") {
                    Toggle("修行時螢幕常亮", isOn: $keepScreenOn)
                }

                // About
                Section("關於") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .onAppear { loadSettings() }
            .onChange(of: currentBeadStyle) { saveSettings() }
            .onChange(of: beadsPerRound) { saveSettings() }
            .onChange(of: soundEnabled) { saveSettings() }
            .onChange(of: hapticEnabled) { saveSettings() }
            .onChange(of: ambientSoundEnabled) { saveSettings() }
            .onChange(of: ambientVolume) { saveSettings() }
            .onChange(of: sfxVolume) { saveSettings() }
            .onChange(of: keepScreenOn) { saveSettings() }
        }
    }

    private func loadSettings() {
        let descriptor = FetchDescriptor<UserSettings>()
        if let existing = try? modelContext.fetch(descriptor).first {
            settings = existing
        } else {
            let new = UserSettings()
            modelContext.insert(new)
            try? modelContext.save()
            settings = new
        }
        guard let s = settings else { return }
        currentBeadStyle = s.currentBeadStyle
        beadsPerRound = s.beadsPerRound
        soundEnabled = s.soundEnabled
        hapticEnabled = s.hapticEnabled
        ambientSoundEnabled = s.ambientSoundEnabled
        ambientVolume = s.ambientVolume
        sfxVolume = s.sfxVolume
        keepScreenOn = s.keepScreenOn
    }

    private func saveSettings() {
        guard let s = settings else { return }
        s.currentBeadStyle = currentBeadStyle
        s.beadsPerRound = beadsPerRound
        s.soundEnabled = soundEnabled
        s.hapticEnabled = hapticEnabled
        s.ambientSoundEnabled = ambientSoundEnabled
        s.ambientVolume = ambientVolume
        s.sfxVolume = sfxVolume
        s.keepScreenOn = keepScreenOn
        try? modelContext.save()
    }
}
```

**Step 2: Build and commit**

```bash
git add beads/Views/SettingsView.swift
git commit -m "feat: add Settings view with bead style, counting, audio, and display options"
```

---

## Phase 9: Widget Extension

### Task 11: Create WidgetKit Extension

**Files:**
- Create: `beadsWidget/beadsWidget.swift`
- Create: `beadsWidget/beadsWidgetBundle.swift`
- Create: `beadsWidget/Info.plist`

> **Note:** This task requires adding a Widget Extension target in Xcode. The engineer must:
> 1. Open beads.xcodeproj in Xcode
> 2. File → New → Target → Widget Extension
> 3. Name it `beadsWidget`
> 4. Uncheck "Include Live Activity"
> 5. Then replace generated files with the code below

**Step 1: Implement Widget**

```swift
// beadsWidget/beadsWidget.swift
import WidgetKit
import SwiftUI
import SwiftData

struct BeadsEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
    let streakDays: Int
}

struct BeadsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BeadsEntry {
        BeadsEntry(date: Date(), todayCount: 0, streakDays: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (BeadsEntry) -> Void) {
        completion(BeadsEntry(date: Date(), todayCount: 108, streakDays: 7))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BeadsEntry>) -> Void) {
        // Read from shared SwiftData or App Group UserDefaults
        let entry = BeadsEntry(date: Date(), todayCount: 0, streakDays: 0)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

struct BeadsWidgetSmallView: View {
    let entry: BeadsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "circle.circle")
                    .foregroundStyle(.orange)
                Text("念珠")
                    .font(.caption.bold())
            }
            Spacer()
            Text("\(entry.todayCount)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            HStack(spacing: 4) {
                Image(systemName: "flame")
                    .foregroundStyle(.orange)
                    .font(.caption2)
                Text("\(entry.streakDays) 天")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct BeadsWidgetMediumView: View {
    let entry: BeadsEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "circle.circle")
                        .foregroundStyle(.orange)
                    Text("念珠")
                        .font(.caption.bold())
                }
                Spacer()
                Text("\(entry.todayCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("今日計數")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame")
                        .foregroundStyle(.orange)
                    Text("\(entry.streakDays)")
                        .font(.title2.bold())
                }
                Text("連續天數")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct BeadsWidget: Widget {
    let kind: String = "beadsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BeadsTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                BeadsWidgetSmallView(entry: entry)
            }
        }
        .configurationDisplayName("念珠")
        .description("追蹤今日修行計數與連續天數")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}
```

```swift
// beadsWidget/beadsWidgetBundle.swift
import WidgetKit
import SwiftUI

@main
struct beadsWidgetBundle: WidgetBundle {
    var body: some Widget {
        BeadsWidget()
    }
}
```

**Step 2: Build and commit**

```bash
git add beadsWidget/
git commit -m "feat: add WidgetKit extension with small, medium, and lock screen widgets"
```

---

## Phase 10: Audio Assets & Polish

### Task 12: Add Placeholder Audio Assets and App Icon

**Files:**
- Create audio placeholders in `beads/Resources/Audio/`
- Update `beads/Assets.xcassets/`

> **Note:** This task requires:
> 1. Creating placeholder audio files (can use system sounds or generate with `afplay`/`say` until real assets arrive)
> 2. Adding an app icon (can be placeholder initially)

**Step 1: Create Resources directory structure**

```bash
mkdir -p beads/Resources/Audio
```

**Step 2: Create a simple sound generation script (temporary placeholders)**

The engineer should source real audio files (royalty-free wood click sounds, temple bells, nature sounds). For now, create empty placeholder references:

```swift
// Add to AudioService.swift - fallback when audio files not found
// Already handled: guard let url = ... else { return }
```

**Step 3: Commit directory structure**

```bash
touch beads/Resources/Audio/.gitkeep
git add beads/Resources/
git commit -m "chore: add audio resources directory structure"
```

---

### Task 13: Integration Testing & Final Polish

**Files:**
- Modify: `beads/beadsApp.swift` (add seed data on launch)
- Run full build and test suite

**Step 1: Update beadsApp.swift to seed mantra data on first launch**

```swift
// beads/beadsApp.swift — add .onAppear to ContentView
import SwiftUI
import SwiftData

@main
struct beadsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PracticeSession.self,
            DailyRecord.self,
            Mantra.self,
            UserSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    MantraSeedData.seedIfNeeded(modelContext: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
```

**Step 2: Run full build**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 3: Run all tests**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20`
Expected: ALL PASS

**Step 4: Final commit**

```bash
git add beads/beadsApp.swift
git commit -m "feat: add mantra seed data on first launch, integration polish"
```

---

## Summary of All Tasks

| Task | Phase | Description | Estimated Steps |
|------|-------|-------------|-----------------|
| 1 | Foundation | SwiftData Models (PracticeSession, DailyRecord, Mantra, UserSettings) | 11 |
| 2 | Foundation | PracticeViewModel (count, undo, round tracking, streak) | 5 |
| 3 | UI Shell | Tab-based Navigation + placeholder views | 4 |
| 4 | 3D | SceneKit bead scene + PBR materials + swipe gesture | 5 |
| 5 | Haptics | Core Haptics service | 2 |
| 6 | Audio | AVFoundation audio service (ambient + SFX) | 3 |
| 7 | Practice | Full PracticeView (3D + counter + haptics + audio) | 4 |
| 8 | Records | Records view with charts + heatmap calendar | 5 |
| 9 | Scripture | Scripture view + mantra library + seed data | 4 |
| 10 | Settings | Settings view with all options | 2 |
| 11 | Widget | WidgetKit extension (small/medium/lock screen) | 2 |
| 12 | Assets | Audio placeholder resources | 3 |
| 13 | Polish | Integration testing + final polish | 4 |

**Total: 13 tasks, ~54 steps**

---

## File Structure After Completion

```
beads/
├── beads/
│   ├── beadsApp.swift                    (modified)
│   ├── ContentView.swift                 (modified — TabView)
│   ├── Models/
│   │   ├── PracticeSession.swift         (new)
│   │   ├── DailyRecord.swift             (new)
│   │   ├── Mantra.swift                  (new)
│   │   └── UserSettings.swift            (new)
│   ├── ViewModels/
│   │   ├── PracticeViewModel.swift       (new)
│   │   └── StatsViewModel.swift          (new)
│   ├── Views/
│   │   ├── PracticeView.swift            (new)
│   │   ├── RecordsView.swift             (new)
│   │   ├── ScriptureView.swift           (new)
│   │   ├── SettingsView.swift            (new)
│   │   ├── Components/
│   │   │   ├── BeadSceneView.swift       (new)
│   │   │   ├── CounterOverlay.swift      (new)
│   │   │   ├── StatsCardView.swift       (new)
│   │   │   └── PracticeCalendarView.swift(new)
│   │   └── Scripture/
│   │       ├── MantraListView.swift      (new)
│   │       └── MantraDetailView.swift    (new)
│   ├── Scene/
│   │   ├── BeadSceneManager.swift        (new)
│   │   └── BeadMaterials.swift           (new)
│   ├── Services/
│   │   ├── HapticService.swift           (new)
│   │   ├── AudioService.swift            (new)
│   │   └── MantraSeedData.swift          (new)
│   ├── Resources/
│   │   └── Audio/                        (new)
│   ├── Assets.xcassets/
│   ├── Info.plist                        (modified)
│   └── beads.entitlements
├── beadsWidget/                          (new target)
│   ├── beadsWidget.swift
│   └── beadsWidgetBundle.swift
├── beadsTests/
│   ├── Models/
│   │   ├── PracticeSessionTests.swift    (new)
│   │   ├── DailyRecordTests.swift        (new)
│   │   └── MantraTests.swift             (new)
│   └── ViewModels/
│       └── PracticeViewModelTests.swift  (new)
└── docs/plans/
    ├── 2026-02-24-beads-app-design.md
    └── 2026-02-24-beads-implementation-plan.md
```
