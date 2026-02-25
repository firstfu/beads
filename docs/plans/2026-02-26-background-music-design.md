# Background Music Integration - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Download 8 royalty-free background music tracks from Pixabay using Playwright and integrate them into the beads app with a music selection UI.

**Architecture:** Use Playwright MCP tools to browse Pixabay Music, download tracks per category, convert with ffmpeg. Add an `AmbientTrack` enum for categorization. Update `UserSettings` with track selection, `AudioService` with playback, `PracticeView` with auto-start, and `SettingsView` with picker UI.

**Tech Stack:** Playwright MCP, ffmpeg, SwiftUI, SwiftData, AVFoundation

---

## Task 1: Download meditation/ambient tracks from Pixabay

**Files:**
- Create: `beads/Resources/Audio/ambient/meditation_1.mp3`
- Create: `beads/Resources/Audio/ambient/meditation_2.mp3`

**Step 1: Create ambient directory**

```bash
mkdir -p /Users/firstfu/Desktop/beads/beads/Resources/Audio/ambient
```

**Step 2: Use Playwright to browse Pixabay Music**

Navigate to `https://pixabay.com/music/search/meditation%20ambient/` using `mcp__playwright__browser_navigate`.

**Step 3: Take snapshot to find download elements**

Use `mcp__playwright__browser_snapshot` to identify the page structure — find track cards, play buttons, and download links.

**Step 4: Download first 2 tracks**

Click the download buttons for the first 2 suitable tracks (duration > 1 min). The files will be downloaded to the system download folder.

**Step 5: Move and rename files**

```bash
# Move downloaded files to project (adjust filenames based on actual downloads)
mv ~/Downloads/<downloaded_file_1>.mp3 /Users/firstfu/Desktop/beads/beads/Resources/Audio/ambient/meditation_1.mp3
mv ~/Downloads/<downloaded_file_2>.mp3 /Users/firstfu/Desktop/beads/beads/Resources/Audio/ambient/meditation_2.mp3
```

**Step 6: Trim to 2-3 minutes with ffmpeg**

```bash
ffmpeg -i ambient/meditation_1.mp3 -t 180 -b:a 128k -y ambient/meditation_1_trimmed.mp3
mv ambient/meditation_1_trimmed.mp3 ambient/meditation_1.mp3
# Repeat for meditation_2.mp3
```

---

## Task 2: Download buddhist/chanting tracks from Pixabay

**Files:**
- Create: `beads/Resources/Audio/ambient/chanting_1.mp3`
- Create: `beads/Resources/Audio/ambient/chanting_2.mp3`

**Step 1: Navigate to Pixabay Music**

Search `https://pixabay.com/music/search/buddhist%20chanting/` or `https://pixabay.com/music/search/tibetan%20bowl/`

**Step 2-4: Same pattern as Task 1** — snapshot, download 2 tracks, move and rename.

**Step 5: Trim with ffmpeg**

```bash
ffmpeg -i ambient/chanting_1.mp3 -t 180 -b:a 128k -y ambient/chanting_1_trimmed.mp3
mv ambient/chanting_1_trimmed.mp3 ambient/chanting_1.mp3
```

---

## Task 3: Download nature sound tracks from Pixabay

**Files:**
- Create: `beads/Resources/Audio/ambient/nature_1.mp3`
- Create: `beads/Resources/Audio/ambient/nature_2.mp3`

Search: `https://pixabay.com/music/search/nature%20rain%20stream/`

Same pattern as Tasks 1-2.

---

## Task 4: Download calm piano tracks from Pixabay

**Files:**
- Create: `beads/Resources/Audio/ambient/piano_1.mp3`
- Create: `beads/Resources/Audio/ambient/piano_2.mp3`

Search: `https://pixabay.com/music/search/calm%20piano%20relaxing/`

Same pattern as Tasks 1-3.

---

## Task 5: Add AmbientTrack enum and update UserSettings

**Files:**
- Modify: `beads/Models/UserSettings.swift`

**Step 1: Add AmbientTrack enum to UserSettings.swift (after BeadDisplayMode)**

```swift
enum AmbientTrack: String, CaseIterable, Identifiable {
    // Meditation
    case meditation1 = "meditation_1"
    case meditation2 = "meditation_2"
    // Buddhist Chanting
    case chanting1 = "chanting_1"
    case chanting2 = "chanting_2"
    // Nature Sounds
    case nature1 = "nature_1"
    case nature2 = "nature_2"
    // Light Music
    case piano1 = "piano_1"
    case piano2 = "piano_2"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .meditation1: return "冥想氛圍 1"
        case .meditation2: return "冥想氛圍 2"
        case .chanting1: return "梵唄誦經 1"
        case .chanting2: return "梵唄誦經 2"
        case .nature1: return "自然之聲 1"
        case .nature2: return "自然之聲 2"
        case .piano1: return "靜心鋼琴 1"
        case .piano2: return "靜心鋼琴 2"
        }
    }

    var category: String {
        switch self {
        case .meditation1, .meditation2: return "禪修冥想"
        case .chanting1, .chanting2: return "梵唄誦經"
        case .nature1, .nature2: return "自然之聲"
        case .piano1, .piano2: return "輕音樂"
        }
    }

    static var groupedByCategory: [(category: String, tracks: [AmbientTrack])] {
        let categories = ["禪修冥想", "梵唄誦經", "自然之聲", "輕音樂"]
        return categories.map { cat in
            (category: cat, tracks: allCases.filter { $0.category == cat })
        }
    }
}
```

**Step 2: Add selectedAmbientTrack field to UserSettings**

Add after `var keepScreenOn: Bool`:

```swift
var selectedAmbientTrack: String
```

Add in `init()`:

```swift
self.selectedAmbientTrack = AmbientTrack.meditation1.rawValue
```

**Step 3: Build to verify**

```bash
xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5
```

**Step 4: Commit**

```bash
git add beads/Models/UserSettings.swift
git commit -m "feat: add AmbientTrack enum and selectedAmbientTrack setting"
```

---

## Task 6: Update AudioService to support ambient subdirectory

**Files:**
- Modify: `beads/Services/AudioService.swift`

**Step 1: Update startAmbient to search in ambient/ subdirectory**

Replace the `startAmbient` method (lines 37-48):

```swift
func startAmbient(named name: String) {
    guard isAmbientEnabled else { return }
    // Look in ambient subdirectory first, then root
    guard let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "ambient")
            ?? Bundle.main.url(forResource: name, withExtension: "mp3") else {
        print("Ambient file not found: \(name).mp3")
        return
    }
    do {
        ambientPlayer = try AVAudioPlayer(contentsOf: url)
        ambientPlayer?.numberOfLoops = -1
        ambientPlayer?.volume = ambientVolume
        ambientPlayer?.play()
    } catch {
        print("Ambient audio error: \(error)")
    }
}
```

**Step 2: Build to verify**

```bash
xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5
```

**Step 3: Commit**

```bash
git add beads/Services/AudioService.swift
git commit -m "feat: update AudioService to search ambient subdirectory"
```

---

## Task 7: Update PracticeView to auto-start background music

**Files:**
- Modify: `beads/Views/PracticeView.swift`

**Step 1: Add settings query (already has @Query for allSettings)**

The view already has `@Query private var allSettings: [UserSettings]`.

**Step 2: Add startAmbient call in onAppear (after line 70, before #endif)**

Add inside `.onAppear` block, after `viewModel.loadTodayStats(...)`:

```swift
if let settings = allSettings.first, settings.ambientSoundEnabled {
    audioService.isAmbientEnabled = true
    audioService.ambientVolume = settings.ambientVolume
    audioService.startAmbient(named: settings.selectedAmbientTrack)
} else {
    audioService.isAmbientEnabled = false
}
```

**Step 3: Build to verify**

```bash
xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5
```

**Step 4: Commit**

```bash
git add beads/Views/PracticeView.swift
git commit -m "feat: auto-start background music when entering practice"
```

---

## Task 8: Update SettingsView with music track picker

**Files:**
- Modify: `beads/Views/SettingsView.swift`

**Step 1: Add selectedAmbientTrack state variable**

Add after `@State private var ambientVolume`:

```swift
@State private var selectedAmbientTrack: String = AmbientTrack.meditation1.rawValue
```

**Step 2: Add music picker in the "音效" section**

After the `Toggle("背景音樂", ...)` and its volume slider, add:

```swift
if ambientSoundEnabled {
    Picker("背景音樂曲目", selection: $selectedAmbientTrack) {
        ForEach(AmbientTrack.groupedByCategory, id: \.category) { group in
            Section(group.category) {
                ForEach(group.tracks) { track in
                    Text(track.displayName).tag(track.rawValue)
                }
            }
        }
    }
}
```

**Step 3: Update loadSettings() — add after keepScreenOn load:**

```swift
selectedAmbientTrack = s.selectedAmbientTrack
```

**Step 4: Update saveSettings() — add after keepScreenOn save:**

```swift
s.selectedAmbientTrack = selectedAmbientTrack
```

**Step 5: Add onChange handler — add after existing onChange calls:**

```swift
.onChange(of: selectedAmbientTrack) { saveSettings() }
```

**Step 6: Build to verify**

```bash
xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5
```

**Step 7: Commit**

```bash
git add beads/Views/SettingsView.swift
git commit -m "feat: add ambient track picker to settings"
```

---

## Task 9: Clean up old generated files and verify Xcode resource inclusion

**Files:**
- Delete: `beads/Resources/Audio/ambient_meditation.wav` (old generated file)

**Step 1: Remove old generated files**

```bash
rm /Users/firstfu/Desktop/beads/beads/Resources/Audio/ambient_meditation.wav
```

**Step 2: Verify ambient directory has all 8 mp3 files**

```bash
ls -la /Users/firstfu/Desktop/beads/beads/Resources/Audio/ambient/
# Should show 8 .mp3 files
```

**Step 3: Build and run to verify**

```bash
xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build 2>&1 | tail -5
```

**Step 4: Final commit**

```bash
git add -A beads/Resources/Audio/
git commit -m "feat: add 8 royalty-free background music tracks from Pixabay"
```
