//
//  Mantra.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

// MARK: - 檔案說明

/// Mantra.swift
/// 咒語/佛號資料模型 - 定義修行時可選用的咒語與佛號資訊
/// 模組：Models

import Foundation
import SwiftData

/// 咒語/佛號資料模型
/// 使用 SwiftData 進行持久化儲存，包含咒語名稱、原文、拼音、說明等完整資訊
/// 可供使用者在修行時選擇念誦的經文或佛號
@Model
final class Mantra {
    /// 咒語/佛號的顯示名稱（例如：「南無阿彌陀佛」）
    var name: String

    /// 咒語/佛號的原始經文內容
    var originalText: String

    /// 咒語/佛號的拼音標註，方便使用者正確發音
    var pinyinText: String

    /// 咒語/佛號的功德說明與介紹文字
    var descriptionText: String

    /// 咒語/佛號所屬分類（例如：「淨土宗」、「咒語」）
    var category: String

    /// 建議每輪念誦次數（例如：108 遍）
    var suggestedCount: Int

    /// 排序順序，用於列表顯示時的排列依據
    var sortOrder: Int

    /// 初始化咒語/佛號資料
    /// - Parameters:
    ///   - name: 咒語/佛號的顯示名稱
    ///   - originalText: 原始經文內容
    ///   - pinyinText: 拼音標註（預設為空字串）
    ///   - descriptionText: 功德說明與介紹（預設為空字串）
    ///   - category: 所屬分類（預設為「淨土宗」）
    ///   - suggestedCount: 建議每輪念誦次數（預設為 108）
    ///   - sortOrder: 排序順序（預設為 0）
    init(
        name: String,
        originalText: String,
        pinyinText: String = "",
        descriptionText: String = "",
        category: String = "淨土宗",
        suggestedCount: Int = 108,
        sortOrder: Int = 0
    ) {
        self.name = name
        self.originalText = originalText
        self.pinyinText = pinyinText
        self.descriptionText = descriptionText
        self.category = category
        self.suggestedCount = suggestedCount
        self.sortOrder = sortOrder
    }
}
