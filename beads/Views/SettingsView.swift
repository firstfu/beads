//
//  SettingsView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var settings: UserSettings?

    @State private var currentBeadStyle: String = "小葉紫檀"
    @State private var beadsPerRound: Int = 108
    @State private var soundEnabled: Bool = true
    @State private var hapticEnabled: Bool = true
    @State private var ambientSoundEnabled: Bool = true
    @State private var ambientVolume: Float = 0.5
    @State private var sfxVolume: Float = 0.8
    @State private var keepScreenOn: Bool = true
    @State private var displayMode: String = BeadDisplayMode.circular.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section("顯示模式") {
                    Picker("佛珠排列", selection: $displayMode) {
                        ForEach(BeadDisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("佛珠樣式") {
                    Picker("材質", selection: $currentBeadStyle) {
                        ForEach(BeadMaterialType.allCases) { material in
                            Text(material.rawValue).tag(material.rawValue)
                        }
                    }
                }

                Section("計數設定") {
                    Picker("每圈珠數", selection: $beadsPerRound) {
                        Text("18 顆").tag(18)
                        Text("21 顆").tag(21)
                        Text("36 顆").tag(36)
                        Text("54 顆").tag(54)
                        Text("108 顆").tag(108)
                    }
                }

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

                Section("顯示") {
                    Toggle("修行時螢幕常亮", isOn: $keepScreenOn)
                }

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
            .onChange(of: displayMode) { saveSettings() }
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
        displayMode = s.displayMode
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
        s.displayMode = displayMode
        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserSettings.self, inMemory: true)
}
