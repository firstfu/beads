//
//  MantraSeedData.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

// MARK: - 檔案說明

/// MantraSeedData.swift
/// 咒語種子資料 - 提供應用程式首次啟動時的預設咒語/佛號資料
/// 採用 UserDefaults 版本控制機制，支援資料遷移與升級
/// 模組：Services

import Foundation
import SwiftData

/// 咒語種子資料結構
/// 負責在應用程式首次啟動或版本升級時，將預設的咒語與佛號資料寫入資料庫
/// 使用 UserDefaults 記錄種子資料版本，確保資料可隨版本演進而更新
struct MantraSeedData {
    // MARK: - 版本控制常數

    /// UserDefaults 中儲存種子資料版本的鍵值
    static let seedDataVersionKey = "seedDataVersion"

    /// 目前種子資料版本號
    /// - v1: 初始版本，包含淨土宗佛號與截斷的咒語
    /// - v2: 修正截斷咒語，補齊完整全文，新增經典與偈頌分類
    static let currentSeedVersion = 2

    // MARK: - 種子資料陣列

    /// 淨土宗佛號資料
    /// 包含常見的淨土宗佛菩薩聖號
    static let pureAndSectMantras: [(String, String, String, String, String, Int, Int)] = [
        ("南無阿彌陀佛", "南無阿彌陀佛", "Nā mó ā mí tuó fó", "淨土宗核心佛號。稱念阿彌陀佛名號，祈願往生西方極樂世界。", "淨土宗", 108, 0),
        ("南無觀世音菩薩", "南無觀世音菩薩", "Nā mó guān shì yīn pú sà", "觀世音菩薩大慈大悲，救苦救難，聞聲救苦。", "淨土宗", 108, 1),
        ("南無地藏王菩薩", "南無地藏王菩薩", "Nā mó dì zàng wáng pú sà", "地藏菩薩發願「地獄不空，誓不成佛」。", "淨土宗", 108, 2),
        ("南無藥師琉璃光如來", "南無藥師琉璃光如來", "Nā mó yào shī liú lí guāng rú lái", "藥師佛為東方淨琉璃世界教主，消災延壽。", "淨土宗", 108, 3),
    ]

    /// 咒語資料
    /// 包含各類常用咒語與真言
    static let mantraMantras: [(String, String, String, String, String, Int, Int)] = [
        ("六字大明咒", "嗡嘛呢唄美吽", "Ǎn ma ní bēi měi hōng", "觀世音菩薩心咒，蘊含諸佛無盡的慈悲與加持。", "咒語", 108, 4),
    ]

    /// 經典資料
    /// 包含常見佛教經典（待後續任務補充）
    static let sutraMantras: [(String, String, String, String, String, Int, Int)] = []

    /// 偈頌資料
    /// 包含常見佛教偈頌（待後續任務補充）
    static let verseMantras: [(String, String, String, String, String, Int, Int)] = []

    // MARK: - 公開方法

    /// 檢查種子資料版本並執行必要的植入或升級
    /// 根據 UserDefaults 中記錄的版本號，判斷是否需要植入新資料或升級既有資料
    /// - Parameter modelContext: SwiftData 模型上下文，用於資料庫讀寫操作
    static func seedIfNeeded(modelContext: ModelContext) {
        let savedVersion = UserDefaults.standard.integer(forKey: seedDataVersionKey)
        guard savedVersion < currentSeedVersion else { return }

        if savedVersion < 1 {
            // 全新安裝：植入所有種子資料
            seedAllData(modelContext: modelContext)
        }

        if savedVersion < 2 {
            // 從 v1 升級至 v2：修正截斷咒語，補充新分類
            upgradeToV2(modelContext: modelContext)
        }

        // 更新版本號並儲存
        UserDefaults.standard.set(currentSeedVersion, forKey: seedDataVersionKey)
        try? modelContext.save()
    }

    // MARK: - 私有方法

    /// 植入所有種子資料（全新安裝時使用）
    /// 將淨土宗佛號、咒語、經典、偈頌等所有分類的資料一次寫入資料庫
    /// - Parameter modelContext: SwiftData 模型上下文
    private static func seedAllData(modelContext: ModelContext) {
        let allMantras = pureAndSectMantras + mantraMantras + sutraMantras + verseMantras
        for mantraData in allMantras {
            insertMantra(mantraData, into: modelContext)
        }
    }

    /// 從 v1 升級至 v2
    /// 刪除含有截斷標記「⋯⋯」的咒語，重新植入完整版本，並新增經典與偈頌分類資料
    /// - Parameter modelContext: SwiftData 模型上下文
    private static func upgradeToV2(modelContext: ModelContext) {
        // 刪除含有截斷標記的咒語資料
        let descriptor = FetchDescriptor<Mantra>()
        if let existingMantras = try? modelContext.fetch(descriptor) {
            for mantra in existingMantras {
                if mantra.originalText.contains("⋯⋯") {
                    modelContext.delete(mantra)
                }
            }
        }

        // 重新植入完整的咒語資料
        for mantraData in mantraMantras {
            insertMantra(mantraData, into: modelContext)
        }

        // 植入新分類資料（經典與偈頌）
        for mantraData in sutraMantras {
            insertMantra(mantraData, into: modelContext)
        }
        for mantraData in verseMantras {
            insertMantra(mantraData, into: modelContext)
        }
    }

    /// 將單筆咒語資料插入資料庫
    /// - Parameters:
    ///   - data: 咒語資料元組，依序為 (名稱, 原文, 拼音, 說明, 分類, 建議次數, 排序順序)
    ///   - context: SwiftData 模型上下文
    private static func insertMantra(_ data: (String, String, String, String, String, Int, Int), into context: ModelContext) {
        let (name, text, pinyin, desc, category, count, order) = data
        let mantra = Mantra(
            name: name,
            originalText: text,
            pinyinText: pinyin,
            descriptionText: desc,
            category: category,
            suggestedCount: count,
            sortOrder: order
        )
        context.insert(mantra)
    }
}
