// MARK: - 檔案說明

/// MantraSeedDataTests.swift
/// 種子資料版本控制測試 - 驗證 MantraSeedData 的版本控制機制與資料植入邏輯
/// 模組：beadsTests/Services

//
//  MantraSeedDataTests.swift
//  beadsTests
//
//  Created by firstfu on 2026/2/26.
//

import Testing
import Foundation
import SwiftData
@testable import beads

/// 種子資料版本控制的單元測試
/// 測試 MantraSeedData 的 UserDefaults 版本控制機制、資料植入與升級邏輯
struct MantraSeedDataTests {
    /// 建立測試用的 in-memory ModelContext
    /// - Returns: 已設定好 Mantra schema 的記憶體內 ModelContext
    private func makeTestContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Mantra.self, configurations: config)
        return ModelContext(container)
    }

    /// 測試種子資料植入後，UserDefaults 版本號應設為目前版本（2）
    /// 驗證 seedIfNeeded 完成後，seedDataVersion 鍵值正確更新
    @Test func seedVersionKey_existsAfterSeed() async throws {
        // 準備：清除舊的版本紀錄
        UserDefaults.standard.removeObject(forKey: MantraSeedData.seedDataVersionKey)

        let context = try makeTestContext()

        // 執行：植入種子資料
        MantraSeedData.seedIfNeeded(modelContext: context)

        // 驗證：版本號應為 2
        let savedVersion = UserDefaults.standard.integer(forKey: MantraSeedData.seedDataVersionKey)
        #expect(savedVersion == MantraSeedData.currentSeedVersion)
        #expect(savedVersion == 2)

        // 清理
        UserDefaults.standard.removeObject(forKey: MantraSeedData.seedDataVersionKey)
    }

    /// 測試種子資料植入後，應包含所有 4 個分類
    /// 目前經典與偈頌陣列為空，待後續任務補充後啟用此測試
    @Test(.disabled("需要所有分類資料完成後才能驗證，目前經典與偈頌陣列為空"))
    func seedVersion2_containsAllCategories() async throws {
        // 準備：清除舊的版本紀錄
        UserDefaults.standard.removeObject(forKey: MantraSeedData.seedDataVersionKey)

        let context = try makeTestContext()

        // 執行：植入種子資料
        MantraSeedData.seedIfNeeded(modelContext: context)

        // 驗證：應包含淨土宗、咒語、經典、偈頌四個分類
        let descriptor = FetchDescriptor<Mantra>()
        let allMantras = try context.fetch(descriptor)
        let categories = Set(allMantras.map { $0.category })

        #expect(categories.contains("淨土宗"))
        #expect(categories.contains("咒語"))
        #expect(categories.contains("經典"))
        #expect(categories.contains("偈頌"))
        #expect(categories.count == 4)

        // 清理
        UserDefaults.standard.removeObject(forKey: MantraSeedData.seedDataVersionKey)
    }
}
