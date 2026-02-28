// MARK: - 檔案說明
/// beadsApp.swift
/// 應用程式入口 - 負責初始化 SwiftData 容器並設定根視圖
/// 模組：App

//
//  beadsApp.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

import SwiftUI
import SwiftData

/// 佛珠念佛 App 的主入口結構體，負責配置資料持久化與根視圖
@main
struct beadsApp: App {
    /// 共用的 SwiftData 模型容器，管理所有資料模型的持久化存儲
    /// - Note: CloudKit 同步：PracticeSession、DailyRecord、UserSettings
    /// - Note: 本地存儲：Mantra（種子資料不同步）
    /// - Note: 若 Schema 遷移失敗，會自動刪除舊資料庫並重新建立
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PracticeSession.self,
            DailyRecord.self,
            Mantra.self,
            UserSettings.self,
        ])

        let cloudConfig = ModelConfiguration(
            schema: Schema([PracticeSession.self, DailyRecord.self, UserSettings.self]),
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        let localConfig = ModelConfiguration(
            "LocalMantra",
            schema: Schema([Mantra.self]),
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig, localConfig])
        } catch {
            // Schema 遷移失敗 — 刪除舊的資料庫檔案並重新建立
            let fileManager = FileManager.default
            for config in [cloudConfig, localConfig] {
                let url = config.url
                let storeDir = url.deletingLastPathComponent()
                let storeName = url.deletingPathExtension().lastPathComponent
                for suffix in ["", "-wal", "-shm"] {
                    let fileURL = storeDir.appendingPathComponent(storeName + ".store" + suffix)
                    try? fileManager.removeItem(at: fileURL)
                }
            }
            do {
                return try ModelContainer(for: schema, configurations: [cloudConfig, localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    /// 應用程式的主場景，設定根視圖為 ContentView 並注入模型容器
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    // 分拆 store 後 Mantra 遷移：若新 store 無資料則強制重新植入
                    let mantraDescriptor = FetchDescriptor<Mantra>()
                    let mantraCount = (try? context.fetchCount(mantraDescriptor)) ?? 0
                    if mantraCount == 0 {
                        UserDefaults.standard.set(0, forKey: MantraSeedData.seedDataVersionKey)
                    }
                    MantraSeedData.seedIfNeeded(modelContext: context)
                    // 確保 UserSettings 存在，讓首次開啟 app 時背景音樂能正常播放
                    let descriptor = FetchDescriptor<UserSettings>()
                    if (try? context.fetch(descriptor).first) == nil {
                        context.insert(UserSettings())
                        try? context.save()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
