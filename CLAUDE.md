# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**beads** is a SwiftUI + SwiftData iOS/macOS/visionOS app. Currently at the Xcode template stage with basic CRUD functionality for timestamped items.

- **Bundle ID**: `com.firstfu.tw.beads`
- **Swift Version**: 5.0
- **Minimum Deployment Target**: iOS 26.2 / macOS (auto SDK)
- **Supported Platforms**: iPhone, iPad, Mac, visionOS

## Build & Run

```bash
# Build
xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator build

# Run unit tests (Swift Testing framework)
xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run UI tests only
xcodebuild -project beads.xcodeproj -scheme beads -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:beadsUITests test
```

## Architecture

- **App Entry**: `beads/beadsApp.swift` — `@main` app struct, configures `ModelContainer` with `Item` schema
- **Data Model**: `beads/Item.swift` — SwiftData `@Model` class with a single `timestamp: Date` property
- **Main UI**: `beads/ContentView.swift` — `NavigationSplitView` with list/detail layout, uses `@Query` for data binding
- **Persistence**: SwiftData with on-disk storage (not in-memory), CloudKit entitlements configured
- **Entitlements**: Push notifications (APNs development) and iCloud/CloudKit enabled

## Key Patterns

- SwiftData `@Model` for persistence (not Core Data)
- `@Query` property wrapper for reactive data fetching in views
- `#if os(macOS)` / `#if os(iOS)` for platform-specific UI adjustments
- Unit tests use Swift Testing framework (`import Testing`, `@Test`), not XCTest
- UI tests use traditional XCTest framework

## Test Structure

- `beadsTests/` — Unit tests (Swift Testing)
- `beadsUITests/` — UI tests and launch performance tests (XCTest)
