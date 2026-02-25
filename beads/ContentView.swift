// MARK: - 檔案說明
/// ContentView.swift
/// 主畫面 - 管理 Tab 導覽和音訊設定同步
/// 模組：Views

//
//  ContentView.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

import SwiftUI
import SwiftData

/// 應用程式主視圖，包含底部 Tab 導覽列，並負責將使用者設定同步至音訊服務
struct ContentView: View {
    /// 從 SwiftData 查詢所有使用者設定
    @Query private var allSettings: [UserSettings]
    /// 音訊服務實例，管理背景音樂和音效播放
    @State private var audioService = AudioService()

    /// 取得第一筆使用者設定（通常只有一筆）
    private var settings: UserSettings? { allSettings.first }

    /// 主視圖內容，包含四個 Tab 頁籤：修行、記錄、經藏、設定
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
        .tint(BeadsTheme.Colors.accent)
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

    /// 將使用者設定同步至音訊服務
    /// - 設定音效開關、音量、背景音樂開關及曲目
    /// - 當背景音樂啟用時自動開始播放，停用時自動停止
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
