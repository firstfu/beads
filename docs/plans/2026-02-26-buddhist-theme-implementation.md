# Buddhist Theme UI/UX Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform the beads app from a black-background design to a warm, earth-tone "Modern Buddhist" (現代佛系) aesthetic with a centralized theme system.

**Architecture:** Create a `BeadsTheme` struct with nested `Colors`, `Typography`, and `Layout` namespaces. Add a `Color+Hex` extension for hex color initialization. Apply theme tokens across all views by replacing hardcoded colors. Modify SceneKit scene managers for warm backgrounds and lighting.

**Tech Stack:** SwiftUI, SceneKit, Swift 5.0, iOS 26.2+

---

### Task 1: Create Color+Hex Extension

**Files:**
- Create: `beads/Theme/Color+Hex.swift`

**Step 1: Create the Color hex extension file**

```swift
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
```

**Step 2: Build to verify it compiles**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Theme/Color+Hex.swift
git commit -m "feat: add Color hex initializer extension"
```

---

### Task 2: Create BeadsTheme

**Files:**
- Create: `beads/Theme/BeadsTheme.swift`

**Step 1: Create the centralized theme file**

```swift
import SwiftUI

enum BeadsTheme {
    // MARK: - Colors
    enum Colors {
        static let background = Color(hex: "F5F0E8")
        static let surfacePrimary = Color(hex: "EDE5D8")
        static let surfaceSecondary = Color(hex: "E6DDD0")
        static let accent = Color(hex: "C4A265")
        static let accentSubtle = Color(hex: "C4A265").opacity(0.15)
        static let textPrimary = Color(hex: "3C2A1A")
        static let textSecondary = Color(hex: "7A6B5D")
        static let textTertiary = Color(hex: "A89B8C")
        static let divider = Color(hex: "D4C9BA")
        static let success = Color(hex: "8B9E6B")

        // Category colors
        static let categoryPureLand = Color(hex: "C4A265")
        static let categoryMantra = Color(hex: "9B7BB8")
        static let categoryClassic = Color(hex: "6B8DB5")
        static let categoryVerse = Color(hex: "8B9E6B")
    }

    // MARK: - Typography
    enum Typography {
        static let titleLarge = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let titleMedium = Font.system(size: 18, weight: .medium)
        static let bodyLarge = Font.system(size: 16)
        static let bodyMedium = Font.system(size: 14)
        static let caption = Font.system(size: 12)
        static let counter = Font.system(size: 48, weight: .thin, design: .rounded)
        static let counterSubtitle = Font.system(size: 14, weight: .light)
    }

    // MARK: - Layout
    enum Layout {
        static let radiusSmall: CGFloat = 8
        static let radiusMedium: CGFloat = 12
        static let radiusLarge: CGFloat = 16
        static let spacingXS: CGFloat = 4
        static let spacingS: CGFloat = 8
        static let spacingM: CGFloat = 16
        static let spacingL: CGFloat = 24
    }
}
```

**Step 2: Build to verify it compiles**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Theme/BeadsTheme.swift
git commit -m "feat: add centralized BeadsTheme with colors, typography, and layout tokens"
```

---

### Task 3: Theme the 3D Scene Managers (Background + Lighting)

**Files:**
- Modify: `beads/Scene/BeadSceneManager.swift` (lines 81-84, 100-103)
- Modify: `beads/Scene/VerticalBeadSceneManager.swift` (lines 72-75, 91-94)

**Step 1: Update BeadSceneManager background**

In `beads/Scene/BeadSceneManager.swift`, replace the scene background setup (lines 81-85):

```swift
// BEFORE:
#if os(macOS)
    scene.background.contents = NSColor.black
#else
    scene.background.contents = UIColor.black
#endif

// AFTER:
#if os(macOS)
    scene.background.contents = NSColor(red: 0.93, green: 0.90, blue: 0.85, alpha: 1.0)
#else
    scene.background.contents = UIColor(red: 0.93, green: 0.90, blue: 0.85, alpha: 1.0)
#endif
```

**Step 2: Update BeadSceneManager ambient light color**

In the same file, replace the ambient light color (lines 100-104):

```swift
// BEFORE:
#if os(macOS)
    ambientLight.light?.color = NSColor(white: 0.9, alpha: 1.0)
#else
    ambientLight.light?.color = UIColor(white: 0.9, alpha: 1.0)
#endif

// AFTER:
#if os(macOS)
    ambientLight.light?.color = NSColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1.0)
#else
    ambientLight.light?.color = UIColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1.0)
#endif
```

**Step 3: Update VerticalBeadSceneManager background**

In `beads/Scene/VerticalBeadSceneManager.swift`, replace the scene background setup (lines 72-76):

```swift
// BEFORE:
#if os(macOS)
    scene.background.contents = NSColor.black
#else
    scene.background.contents = UIColor.black
#endif

// AFTER:
#if os(macOS)
    scene.background.contents = NSColor(red: 0.93, green: 0.90, blue: 0.85, alpha: 1.0)
#else
    scene.background.contents = UIColor(red: 0.93, green: 0.90, blue: 0.85, alpha: 1.0)
#endif
```

**Step 4: Update VerticalBeadSceneManager ambient light color**

In the same file, replace the ambient light color (lines 91-95):

```swift
// BEFORE:
#if os(macOS)
    ambientLight.light?.color = NSColor(white: 0.9, alpha: 1.0)
#else
    ambientLight.light?.color = UIColor(white: 0.9, alpha: 1.0)
#endif

// AFTER:
#if os(macOS)
    ambientLight.light?.color = NSColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1.0)
#else
    ambientLight.light?.color = UIColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1.0)
#endif
```

**Step 5: Update SCNView backgroundColor in BeadSceneView.swift**

In `beads/Views/Components/BeadSceneView.swift`, replace `.backgroundColor = .black` on lines 37 and 101:

```swift
// BEFORE:
scnView.backgroundColor = .black

// AFTER (macOS, line 37):
scnView.backgroundColor = NSColor(red: 0.93, green: 0.90, blue: 0.85, alpha: 1.0)

// AFTER (iOS, line 101):
scnView.backgroundColor = UIColor(red: 0.93, green: 0.90, blue: 0.85, alpha: 1.0)
```

**Step 6: Update SCNView backgroundColor in VerticalBeadSceneView.swift**

In `beads/Views/Components/VerticalBeadSceneView.swift`, replace `.backgroundColor = .black` on lines 37 and 101:

```swift
// BEFORE:
scnView.backgroundColor = .black

// AFTER (macOS, line 37):
scnView.backgroundColor = NSColor(red: 0.93, green: 0.90, blue: 0.85, alpha: 1.0)

// AFTER (iOS, line 101):
scnView.backgroundColor = UIColor(red: 0.93, green: 0.90, blue: 0.85, alpha: 1.0)
```

**Step 7: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 8: Commit**

```bash
git add beads/Scene/BeadSceneManager.swift beads/Scene/VerticalBeadSceneManager.swift beads/Views/Components/BeadSceneView.swift beads/Views/Components/VerticalBeadSceneView.swift
git commit -m "feat: change 3D scene backgrounds from black to warm earth tone and warm lighting"
```

---

### Task 4: Theme CounterOverlay (Practice Page Text)

**Files:**
- Modify: `beads/Views/Components/CounterOverlay.swift`

**Step 1: Replace all hardcoded colors in CounterOverlay**

In `beads/Views/Components/CounterOverlay.swift`, make these replacements:

Line 36: `.foregroundStyle(.white.opacity(0.8))` → `.foregroundStyle(BeadsTheme.Colors.accent)`
Line 46: `.foregroundStyle(.white.opacity(0.6))` → `.foregroundStyle(BeadsTheme.Colors.textSecondary)`
Line 56: `.foregroundStyle(.white)` → `.foregroundStyle(BeadsTheme.Colors.textPrimary)`
Line 60: `.foregroundStyle(.white.opacity(0.5))` → `.foregroundStyle(BeadsTheme.Colors.textTertiary)`
Line 68: `.foregroundStyle(.white.opacity(0.9))` → `.foregroundStyle(BeadsTheme.Colors.textPrimary)`
Line 75: `.foregroundStyle(.white.opacity(0.7))` → `.foregroundStyle(BeadsTheme.Colors.textSecondary)`
Line 79: `.foregroundStyle(.orange.opacity(0.9))` → `.foregroundStyle(BeadsTheme.Colors.accent)`

**Step 2: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/Components/CounterOverlay.swift
git commit -m "feat: apply Buddhist theme colors to counter overlay"
```

---

### Task 5: Theme PracticeView (Merit Popup)

**Files:**
- Modify: `beads/Views/PracticeView.swift`

**Step 1: Replace merit popup colors**

In `beads/Views/PracticeView.swift`:

Line 89: `.foregroundStyle(.yellow)` → `.foregroundStyle(BeadsTheme.Colors.success)`
Line 90: `.shadow(color: .yellow.opacity(0.5), radius: 8)` → `.shadow(color: BeadsTheme.Colors.success.opacity(0.5), radius: 8)`

**Step 2: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/PracticeView.swift
git commit -m "feat: change merit popup from yellow to success green"
```

---

### Task 6: Theme RecordsView (Stats Page)

**Files:**
- Modify: `beads/Views/RecordsView.swift`

**Step 1: Replace chart color and card backgrounds**

In `beads/Views/RecordsView.swift`:

Line 55: `.foregroundStyle(Color.orange.gradient)` → `.foregroundStyle(BeadsTheme.Colors.accent.gradient)`
Line 66: `.background(.ultraThinMaterial)` → `.background(BeadsTheme.Colors.surfacePrimary)`
Line 72: `.background(.ultraThinMaterial)` → `.background(BeadsTheme.Colors.surfacePrimary)`

**Step 2: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/RecordsView.swift
git commit -m "feat: apply Buddhist theme to records view charts and cards"
```

---

### Task 7: Theme StatsCardView

**Files:**
- Modify: `beads/Views/Components/StatsCardView.swift`

**Step 1: Replace card background**

In `beads/Views/Components/StatsCardView.swift`:

Line 49: `.background(.ultraThinMaterial)` → `.background(BeadsTheme.Colors.surfacePrimary)`

Also add a shadow after `.clipShape(...)` on line 50:

Add after line 50: `.shadow(color: BeadsTheme.Colors.textPrimary.opacity(0.08), radius: 8, y: 2)`

**Step 2: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/Components/StatsCardView.swift
git commit -m "feat: apply Buddhist theme to stats card with warm shadow"
```

---

### Task 8: Theme PracticeCalendarView (Heatmap)

**Files:**
- Modify: `beads/Views/Components/PracticeCalendarView.swift`

**Step 1: Replace heatmap colors**

In `beads/Views/Components/PracticeCalendarView.swift`, replace the `heatColor` function body (lines 69-75):

```swift
// BEFORE:
case 0: return Color(.systemGray5)
case 1..<100: return Color.orange.opacity(0.3)
case 100..<300: return Color.orange.opacity(0.5)
case 300..<600: return Color.orange.opacity(0.7)
default: return Color.orange.opacity(0.95)

// AFTER:
case 0: return BeadsTheme.Colors.surfaceSecondary
case 1..<100: return BeadsTheme.Colors.accent.opacity(0.3)
case 100..<300: return BeadsTheme.Colors.accent.opacity(0.5)
case 300..<600: return BeadsTheme.Colors.accent.opacity(0.7)
default: return BeadsTheme.Colors.accent.opacity(0.95)
```

**Step 2: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/Components/PracticeCalendarView.swift
git commit -m "feat: apply Buddhist gold heatmap colors to practice calendar"
```

---

### Task 9: Theme MantraListView (Scripture Categories)

**Files:**
- Modify: `beads/Views/Scripture/MantraListView.swift`

**Step 1: Replace the colorForCategory function**

In `beads/Views/Scripture/MantraListView.swift`, replace the `colorForCategory` function (lines 31-38):

```swift
// BEFORE:
private func colorForCategory(_ category: String) -> Color {
    switch category {
    case "淨土宗": return .orange
    case "咒語": return .purple
    case "經典": return .blue
    case "偈頌": return .green
    default: return .gray
    }
}

// AFTER:
private func colorForCategory(_ category: String) -> Color {
    switch category {
    case "淨土宗": return BeadsTheme.Colors.categoryPureLand
    case "咒語": return BeadsTheme.Colors.categoryMantra
    case "經典": return BeadsTheme.Colors.categoryClassic
    case "偈頌": return BeadsTheme.Colors.categoryVerse
    default: return BeadsTheme.Colors.textTertiary
    }
}
```

**Step 2: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/Scripture/MantraListView.swift
git commit -m "feat: apply Buddhist theme category colors to mantra list"
```

---

### Task 10: Theme MantraDetailView (Scripture Detail)

**Files:**
- Modify: `beads/Views/Scripture/MantraDetailView.swift`

**Step 1: Replace all hardcoded colors**

In `beads/Views/Scripture/MantraDetailView.swift`, make these replacements:

Line 101: `Color(.systemGray6)` → `BeadsTheme.Colors.surfacePrimary`
Line 124: `Color(.systemGray6)` → `BeadsTheme.Colors.surfacePrimary`
Line 146: `Color(.systemGray6)` → `BeadsTheme.Colors.surfacePrimary`
Line 162: `.foregroundStyle(.orange)` → `.foregroundStyle(BeadsTheme.Colors.accent)`
Line 170: `Color.orange.opacity(0.8)` → `BeadsTheme.Colors.accent.opacity(0.8)`
Line 176: `Color.orange.opacity(0.1)` → `BeadsTheme.Colors.accentSubtle`
Line 220: `Color.black.opacity(0.75)` → `BeadsTheme.Colors.accent`

**Step 2: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/Scripture/MantraDetailView.swift
git commit -m "feat: apply Buddhist theme to mantra detail view"
```

---

### Task 11: Theme SettingsView

**Files:**
- Modify: `beads/Views/SettingsView.swift`

**Step 1: Add tint modifier to the Form**

In `beads/Views/SettingsView.swift`, add `.tint(BeadsTheme.Colors.accent)` after the `.navigationTitle("設定")` line (after line 131):

```swift
// Add this line:
.tint(BeadsTheme.Colors.accent)
```

This will theme all Toggle, Slider, and Picker controls with the Buddhist gold color.

**Step 2: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/SettingsView.swift
git commit -m "feat: apply Buddhist gold tint to settings form controls"
```

---

### Task 12: Theme Tab Bar (ContentView)

**Files:**
- Modify: `beads/ContentView.swift`

**Step 1: Add tint and appearance modifiers**

In `beads/ContentView.swift`, add `.tint(BeadsTheme.Colors.accent)` modifier to the TabView (after line 41, before `.environment(audioService)`):

```swift
TabView {
    // ... existing tabs ...
}
.tint(BeadsTheme.Colors.accent)
.environment(audioService)
```

**Step 2: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/ContentView.swift
git commit -m "feat: apply Buddhist gold accent to tab bar"
```

---

### Task 13: Create Lotus Shape Decoration

**Files:**
- Create: `beads/Theme/LotusShape.swift`

**Step 1: Create a simple lotus SwiftUI shape**

```swift
import SwiftUI

struct LotusView: View {
    var color: Color = BeadsTheme.Colors.accent
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            // Center petal (top)
            Ellipse()
                .fill(color.opacity(0.3))
                .frame(width: size * 0.3, height: size * 0.5)
                .offset(y: -size * 0.15)

            // Left petal
            Ellipse()
                .fill(color.opacity(0.2))
                .frame(width: size * 0.3, height: size * 0.45)
                .rotationEffect(.degrees(30))
                .offset(x: -size * 0.2, y: -size * 0.05)

            // Right petal
            Ellipse()
                .fill(color.opacity(0.2))
                .frame(width: size * 0.3, height: size * 0.45)
                .rotationEffect(.degrees(-30))
                .offset(x: size * 0.2, y: -size * 0.05)

            // Outer left petal
            Ellipse()
                .fill(color.opacity(0.15))
                .frame(width: size * 0.25, height: size * 0.4)
                .rotationEffect(.degrees(55))
                .offset(x: -size * 0.32, y: size * 0.05)

            // Outer right petal
            Ellipse()
                .fill(color.opacity(0.15))
                .frame(width: size * 0.25, height: size * 0.4)
                .rotationEffect(.degrees(-55))
                .offset(x: size * 0.32, y: size * 0.05)
        }
        .frame(width: size, height: size)
    }
}
```

**Step 2: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Theme/LotusShape.swift
git commit -m "feat: add lotus shape decoration component"
```

---

### Task 14: Add Lotus Decoration to Practice Page

**Files:**
- Modify: `beads/Views/Components/CounterOverlay.swift`

**Step 1: Add lotus above the mantra name**

In `beads/Views/Components/CounterOverlay.swift`, add a `LotusView` above the top mantra name HStack (before line 33):

```swift
// Add before the top HStack:
HStack {
    Spacer()
    LotusView(color: BeadsTheme.Colors.accent.opacity(0.5), size: 28)
    Spacer()
}
.padding(.top, 4)
```

**Step 2: Build to verify**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add beads/Views/Components/CounterOverlay.swift
git commit -m "feat: add subtle lotus decoration to practice page header"
```

---

### Task 15: Add Theme Files to Xcode Project

**Important Note:** The new files created in `beads/Theme/` need to be part of the Xcode project. Since these files are within the `beads/` target directory, Xcode should auto-discover them if the project uses folder references. If the build fails because files are not found, they need to be added to the Xcode project file.

**Step 1: Verify all new files are included in the build**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -10`

If the build fails with "no such module" or "cannot find type" errors for BeadsTheme, the files need to be manually added to the Xcode project. In that case, check if the project uses file references and add the Theme folder.

**Step 2: Final full build verification**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Run tests**

Run: `xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -10`
Expected: All tests pass

**Step 4: Final commit if any adjustments were needed**

```bash
git add -A
git commit -m "feat: ensure all theme files are included in Xcode build"
```

---

## Summary of All Changes

| File | Change Type | Description |
|------|-------------|-------------|
| `beads/Theme/Color+Hex.swift` | **NEW** | Color hex initializer extension |
| `beads/Theme/BeadsTheme.swift` | **NEW** | Centralized theme (Colors, Typography, Layout) |
| `beads/Theme/LotusShape.swift` | **NEW** | Lotus decoration view |
| `beads/Scene/BeadSceneManager.swift` | MODIFY | Background: black → warm ivory, warm lighting |
| `beads/Scene/VerticalBeadSceneManager.swift` | MODIFY | Background: black → warm ivory, warm lighting |
| `beads/Views/Components/BeadSceneView.swift` | MODIFY | SCNView background: black → warm ivory |
| `beads/Views/Components/VerticalBeadSceneView.swift` | MODIFY | SCNView background: black → warm ivory |
| `beads/Views/Components/CounterOverlay.swift` | MODIFY | All text: white → theme colors, lotus decoration |
| `beads/Views/PracticeView.swift` | MODIFY | Merit popup: yellow → success green |
| `beads/Views/RecordsView.swift` | MODIFY | Charts: orange → accent gold, cards: material → surface |
| `beads/Views/Components/StatsCardView.swift` | MODIFY | Card: material → surface + shadow |
| `beads/Views/Components/PracticeCalendarView.swift` | MODIFY | Heatmap: orange → accent gold |
| `beads/Views/Scripture/MantraListView.swift` | MODIFY | Category colors → theme tokens |
| `beads/Views/Scripture/MantraDetailView.swift` | MODIFY | All orange/gray → theme tokens |
| `beads/Views/SettingsView.swift` | MODIFY | Form tint → accent gold |
| `beads/ContentView.swift` | MODIFY | Tab bar tint → accent gold |
