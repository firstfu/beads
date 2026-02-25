//
//  MantraSeedData.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

// MARK: - 檔案說明

/// MantraSeedData.swift
/// 咒語種子資料 - 提供應用程式首次啟動時的預設咒語/佛號資料
/// 模組：Services
///
/// 架構：使用 extension 分拆至 SeedData/ 目錄下的多個檔案
/// - MantraSeedData+PureLand.swift     淨土宗佛號
/// - MantraSeedData+Mantras.swift      咒語
/// - MantraSeedData+ShortSutras.swift  短篇經典
/// - MantraSeedData+AmitabhaSutra.swift 佛說阿彌陀經
/// - MantraSeedData+UniversalGate.swift 普門品
/// - MantraSeedData+MedicineBuddhaSutra.swift 藥師經
/// - MantraSeedData+DiamondSutra.swift 金剛經
/// - MantraSeedData+KsitigarbhaSutra.swift 地藏經
/// - MantraSeedData+InfiniteLifeSutra.swift 無量壽經
/// - MantraSeedData+Verses.swift       偈頌

import Foundation
import SwiftData

/// 咒語種子資料結構
/// 負責在應用程式首次啟動時，將預設的咒語與佛號資料寫入資料庫
/// 包含淨土宗佛號、咒語、經典、偈頌等四大分類
struct MantraSeedData {
    /// 種子資料元組型別
    /// (名稱, 原文, 拼音, 說明, 分類, 建議次數, 排序順序)
    typealias SeedEntry = (name: String, originalText: String, pinyinText: String, descriptionText: String, category: String, suggestedCount: Int, sortOrder: Int)

    /// 當前種子資料版本
    private static let currentVersion = 2

    /// UserDefaults 儲存版本號的 key
    private static let versionKey = "seedDataVersion"

    // MARK: - 公開方法

    /// 檢查並植入或升級預設咒語資料
    /// - 全新安裝：植入所有資料
    /// - v1 使用者（版本號為 0）：升級至 v2（補齊截斷咒語 + 新增經典偈頌）
    /// - 已是最新版本：不做任何事
    /// - Parameter modelContext: SwiftData 模型上下文
    static func seedIfNeeded(modelContext: ModelContext) {
        let savedVersion = UserDefaults.standard.integer(forKey: versionKey)

        if savedVersion == 0 {
            let descriptor = FetchDescriptor<Mantra>()
            let count = (try? modelContext.fetchCount(descriptor)) ?? 0

            if count == 0 {
                seedAllData(modelContext: modelContext)
            } else {
                upgradeToV2(modelContext: modelContext)
            }
        } else if savedVersion < currentVersion {
            if savedVersion < 2 {
                upgradeToV2(modelContext: modelContext)
            }
        }
    }

    // MARK: - 全新安裝

    /// 植入所有種子資料（全新安裝用）
    private static func seedAllData(modelContext: ModelContext) {
        let allEntries: [SeedEntry] =
            pureLandEntries
            + mantraEntries
            + shortSutraEntries
            + amitabhaSutraEntries
            + universalGateEntries
            + medicineBuddhaSutraEntries
            + diamondSutraEntries
            + ksitigarbhaSutraEntries
            + infiniteLifeSutraEntries
            + verseEntries

        insertEntries(allEntries, into: modelContext)
        UserDefaults.standard.set(currentVersion, forKey: versionKey)
    }

    // MARK: - v1 → v2 升級

    /// 從 v1 升級至 v2
    /// 1. 更新 4 筆被截斷的咒語（大悲咒、往生咒、藥師灌頂真言、準提神咒）
    /// 2. 新增經典與偈頌類別的所有資料
    private static func upgradeToV2(modelContext: ModelContext) {
        // 取得所有現有咒語，用於比對更新
        let descriptor = FetchDescriptor<Mantra>()
        let existingMantras = (try? modelContext.fetch(descriptor)) ?? []
        let existingNames = Set(existingMantras.map(\.name))

        // 更新截斷的咒語
        let truncatedNames: Set<String> = ["大悲咒", "往生咒", "藥師灌頂真言", "準提神咒"]
        for entry in mantraEntries where truncatedNames.contains(entry.name) {
            if let existing = existingMantras.first(where: { $0.name == entry.name }) {
                existing.originalText = entry.originalText
                existing.pinyinText = entry.pinyinText
                existing.descriptionText = entry.descriptionText
            }
        }

        // 新增所有不存在的資料
        let newEntries: [SeedEntry] =
            (pureLandEntries + mantraEntries + shortSutraEntries
            + amitabhaSutraEntries + universalGateEntries
            + medicineBuddhaSutraEntries + diamondSutraEntries
            + ksitigarbhaSutraEntries + infiniteLifeSutraEntries
            + verseEntries)
            .filter { !existingNames.contains($0.name) }

        insertEntries(newEntries, into: modelContext)
        UserDefaults.standard.set(currentVersion, forKey: versionKey)
    }

    // MARK: - 輔助方法

    /// 將 SeedEntry 陣列批次插入資料庫
    private static func insertEntries(_ entries: [SeedEntry], into modelContext: ModelContext) {
        for entry in entries {
            let mantra = Mantra(
                name: entry.name,
                originalText: entry.originalText,
                pinyinText: entry.pinyinText,
                descriptionText: entry.descriptionText,
                category: entry.category,
                suggestedCount: entry.suggestedCount,
                sortOrder: entry.sortOrder
            )
            modelContext.insert(mantra)
        }
        try? modelContext.save()
    }
}
