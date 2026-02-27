// MARK: - 檔案說明
/// SettingsView.swift
/// 設定畫面 - 提供佛珠樣式、計數、音效、顯示等各項偏好設定的使用者介面
/// 模組：Views

//
//  SettingsView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI
import SwiftData

/// 設定視圖，讓使用者調整佛珠顯示模式、材質、計數、音效、背景音樂等偏好設定
struct SettingsView: View {
    /// SwiftData 模型上下文，用於讀取和儲存使用者設定
    @Environment(\.modelContext) private var modelContext
    /// 目前載入的使用者設定物件
    @State private var settings: UserSettings?

    /// 目前選擇的佛珠材質樣式名稱
    @State private var currentBeadStyle: String = "小葉紫檀"
    /// 每圈的珠子數量
    @State private var beadsPerRound: Int = 108
    /// 是否啟用撥珠音效
    @State private var soundEnabled: Bool = true
    /// 是否啟用觸感回饋
    @State private var hapticEnabled: Bool = true
    /// 是否啟用背景音樂
    @State private var ambientSoundEnabled: Bool = true
    /// 背景音樂音量（0.0 ~ 1.0）
    @State private var ambientVolume: Float = 0.5
    /// 目前選擇的背景音樂曲目識別碼
    @State private var selectedAmbientTrack: String = AmbientTrack.sutraChanting1.rawValue
    /// 音效音量（0.0 ~ 1.0）
    @State private var sfxVolume: Float = 0.8
    /// 是否在修行時保持螢幕常亮
    @State private var keepScreenOn: Bool = true
    /// 佛珠顯示模式的原始值（環形或直列）
    @State private var displayMode: String = BeadDisplayMode.vertical.rawValue
    /// 是否啟用快速撥珠模式
    @State private var fastScrollMode: Bool = false
    /// 背景主題的原始值
    @State private var backgroundTheme: String = ZenBackgroundTheme.inkWash.rawValue
    /// 是否顯示清除資料確認對話框
    @State private var showDeleteConfirmation = false
    /// 是否顯示清除成功提示
    @State private var showDeleteSuccess = false

    /// 目前的背景主題列舉值
    private var currentBackgroundTheme: ZenBackgroundTheme {
        ZenBackgroundTheme(rawValue: backgroundTheme) ?? .inkWash
    }

    /// 主視圖內容，以表單形式呈現各項設定區段
    var body: some View {
        NavigationStack {
            ZStack {
                ZenBackgroundView(theme: currentBackgroundTheme, enableLotusDecoration: false)
            Form {
                // MARK: - 顯示模式設定
                Section("顯示模式") {
                    Picker("佛珠排列", selection: $displayMode) {
                        ForEach(BeadDisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: - 撥珠手勢設定
                Section("撥珠手勢") {
                    Toggle("快速撥珠模式", isOn: $fastScrollMode)
                    Text("開啟後滑動可連續撥多顆珠，關閉時每次滑動只撥一顆")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: - 背景主題設定
                Section("背景主題") {
                    Picker("主題", selection: $backgroundTheme) {
                        ForEach(ZenBackgroundTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: - 佛珠樣式設定
                Section("佛珠樣式") {
                    Picker("材質", selection: $currentBeadStyle) {
                        ForEach(BeadMaterialType.allCases) { material in
                            Text(material.rawValue).tag(material.rawValue)
                        }
                    }
                }

                // MARK: - 計數設定
                Section("計數設定") {
                    Picker("每圈珠數", selection: $beadsPerRound) {
                        Text("18 顆").tag(18)
                        Text("27 顆").tag(27)
                        Text("36 顆").tag(36)
                        Text("54 顆").tag(54)
                        Text("108 顆").tag(108)
                    }
                }

                // MARK: - 音效設定
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
                    VStack(alignment: .leading) {
                        Text("音效音量")
                            .font(.caption)
                        Slider(value: $sfxVolume, in: 0...1)
                    }
                }

                // MARK: - 顯示設定
                Section("顯示") {
                    Toggle("修行時螢幕常亮", isOn: $keepScreenOn)
                }

                // MARK: - 資料管理
                Section("資料管理") {
                    Button("清除所有修行紀錄", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
                .alert("確認清除所有資料", isPresented: $showDeleteConfirmation) {
                    Button("取消", role: .cancel) { }
                    Button("清除", role: .destructive) { deleteAllData() }
                } message: {
                    Text("此操作將刪除所有修行紀錄、迴向紀錄及統計資料，且無法復原。設定不會被清除。")
                }

                // MARK: - 關於
                Section("關於") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    NavigationLink("隱私權政策") {
                        PrivacyPolicyView()
                    }
                    NavigationLink("使用條款") {
                        TermsOfServiceView()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .alert("清除完成", isPresented: $showDeleteSuccess) {
                Button("確定", role: .cancel) { }
            } message: {
                Text("所有修行紀錄已清除。")
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
            .onChange(of: selectedAmbientTrack) { saveSettings() }
            .onChange(of: sfxVolume) { saveSettings() }
            .onChange(of: keepScreenOn) { saveSettings() }
            .onChange(of: displayMode) { saveSettings() }
            .onChange(of: fastScrollMode) { saveSettings() }
            .onChange(of: backgroundTheme) { saveSettings() }
        }
    }

    /// 從 SwiftData 載入使用者設定
    /// - 若已有設定資料則直接使用，否則建立新的預設設定並存入資料庫
    /// - 載入後將各欄位值同步至本地 @State 屬性
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
        selectedAmbientTrack = s.selectedAmbientTrack
        sfxVolume = s.sfxVolume
        keepScreenOn = s.keepScreenOn
        displayMode = s.displayMode
        fastScrollMode = s.fastScrollMode
        backgroundTheme = s.backgroundTheme
    }

    /// 清除所有修行紀錄與每日統計資料
    private func deleteAllData() {
        do {
            try modelContext.delete(model: PracticeSession.self)
            try modelContext.delete(model: DailyRecord.self)
            try modelContext.save()
            showDeleteSuccess = true
        } catch {
            print("清除資料失敗: \(error)")
        }
    }

    /// 將目前本地 @State 屬性的值寫回 SwiftData 使用者設定物件並儲存
    private func saveSettings() {
        guard let s = settings else { return }
        s.currentBeadStyle = currentBeadStyle
        s.beadsPerRound = beadsPerRound
        s.soundEnabled = soundEnabled
        s.hapticEnabled = hapticEnabled
        s.ambientSoundEnabled = ambientSoundEnabled
        s.ambientVolume = ambientVolume
        s.selectedAmbientTrack = selectedAmbientTrack
        s.sfxVolume = sfxVolume
        s.keepScreenOn = keepScreenOn
        s.displayMode = displayMode
        s.fastScrollMode = fastScrollMode
        s.backgroundTheme = backgroundTheme
        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserSettings.self, inMemory: true)
}
