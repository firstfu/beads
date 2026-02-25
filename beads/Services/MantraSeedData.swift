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

import SwiftData

/// 咒語種子資料結構
/// 負責在應用程式首次啟動時，將預設的咒語與佛號資料寫入資料庫
/// 包含淨土宗常見佛號與各類常用咒語
struct MantraSeedData {
    /// 檢查並植入預設咒語資料
    /// 若資料庫中尚無任何咒語記錄，則自動植入預設的佛號與咒語清單
    /// 包含 9 筆預設資料，涵蓋淨土宗佛號及常見咒語
    /// - Parameter modelContext: SwiftData 模型上下文，用於資料庫讀寫操作
    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Mantra>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        /// 預設咒語資料陣列
        /// 每筆資料依序為：(名稱, 原文, 拼音, 說明, 分類, 建議次數, 排序順序)
        let mantras: [(String, String, String, String, String, Int, Int)] = [
            ("南無阿彌陀佛", "南無阿彌陀佛", "Nā mó ā mí tuó fó", "淨土宗核心佛號。稱念阿彌陀佛名號，祈願往生西方極樂世界。", "淨土宗", 108, 0),
            ("南無觀世音菩薩", "南無觀世音菩薩", "Nā mó guān shì yīn pú sà", "觀世音菩薩大慈大悲，救苦救難，聞聲救苦。", "淨土宗", 108, 1),
            ("南無地藏王菩薩", "南無地藏王菩薩", "Nā mó dì zàng wáng pú sà", "地藏菩薩發願「地獄不空，誓不成佛」。", "淨土宗", 108, 2),
            ("南無藥師琉璃光如來", "南無藥師琉璃光如來", "Nā mó yào shī liú lí guāng rú lái", "藥師佛為東方淨琉璃世界教主，消災延壽。", "淨土宗", 108, 3),
            ("六字大明咒", "嗡嘛呢唄美吽", "Ǎn ma ní bēi měi hōng", "觀世音菩薩心咒，蘊含諸佛無盡的慈悲與加持。", "咒語", 108, 4),
            ("大悲咒", "南無喝囉怛那哆囉夜耶⋯⋯", "Nā mó hé là dá nā duō là yè yē...", "千手千眼觀世音菩薩廣大圓滿無礙大悲心陀羅尼。全咒共84句。", "咒語", 84, 5),
            ("往生咒", "南無阿彌多婆夜⋯⋯", "Nā mó ā mí duō pó yè...", "拔一切業障根本得生淨土陀羅尼。", "咒語", 21, 6),
            ("藥師灌頂真言", "南謨薄伽伐帝⋯⋯", "Nā mó bó qié fá dì...", "藥師琉璃光如來本願功德經中的核心咒語。", "咒語", 108, 7),
            ("準提神咒", "稽首皈依蘇悉帝⋯⋯", "Jī shǒu guī yī sū xī dì...", "準提菩薩咒，能滅十惡五逆一切罪障。", "咒語", 108, 8),
        ]

        for (name, text, pinyin, desc, category, count, order) in mantras {
            let mantra = Mantra(
                name: name,
                originalText: text,
                pinyinText: pinyin,
                descriptionText: desc,
                category: category,
                suggestedCount: count,
                sortOrder: order
            )
            modelContext.insert(mantra)
        }
        try? modelContext.save()
    }
}
