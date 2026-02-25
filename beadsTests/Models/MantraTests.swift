// MARK: - 檔案說明
/// MantraTests.swift
/// 咒語模型測試 - 驗證 Mantra 模型的建立和屬性初始化
/// 模組：beadsTests/Models

//
//  MantraTests.swift
//  beadsTests
//
//  Created by firstfu on 2026/2/24.
//

import Testing
import Foundation
@testable import beads

/// 咒語模型的單元測試
/// 測試 Mantra 模型的初始化和各屬性值的正確性
struct MantraTests {
    /// 測試建立咒語模型的初始狀態
    /// 驗證以完整參數建立的咒語，其名稱、分類和建議持誦次數皆正確
    @Test func createMantra() async throws {
        let mantra = Mantra(
            name: "南無阿彌陀佛",
            originalText: "南無阿彌陀佛",
            pinyinText: "Nā mó ā mí tuó fó",
            descriptionText: "淨土宗核心佛號",
            category: "淨土宗",
            suggestedCount: 108
        )
        #expect(mantra.name == "南無阿彌陀佛")
        #expect(mantra.category == "淨土宗")
        #expect(mantra.suggestedCount == 108)
    }
}
