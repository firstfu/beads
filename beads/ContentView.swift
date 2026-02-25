//
//  ContentView.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var allSettings: [UserSettings]
    @State private var audioService = AudioService()

    private var settings: UserSettings? { allSettings.first }

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
        .environment(audioService)
        .onAppear {
            syncAudioWithSettings()
        }
        .onChange(of: settings?.ambientSoundEnabled) {
            syncAudioWithSettings()
        }
        .onChange(of: settings?.selectedAmbientTrack) {
            syncAudioWithSettings()
        }
        .onChange(of: settings?.ambientVolume) {
            if let s = settings {
                audioService.ambientVolume = s.ambientVolume
            }
        }
        .onChange(of: settings?.soundEnabled) {
            if let s = settings {
                audioService.isSFXEnabled = s.soundEnabled
            }
        }
        .onChange(of: settings?.sfxVolume) {
            if let s = settings {
                audioService.sfxVolume = s.sfxVolume
            }
        }
    }

    private func syncAudioWithSettings() {
        guard let s = settings else { return }
        audioService.isSFXEnabled = s.soundEnabled
        audioService.sfxVolume = s.sfxVolume
        audioService.ambientVolume = s.ambientVolume
        if s.ambientSoundEnabled {
            audioService.isAmbientEnabled = true
            audioService.startAmbient(named: s.selectedAmbientTrack)
        } else {
            audioService.isAmbientEnabled = false
            audioService.stopAmbient()
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
