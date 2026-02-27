//
//  PracticeSession.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

// MARK: - 檔案說明

/// PracticeSession.swift
/// 修行場次模型 - 記錄單次修行的念珠計數、圈數與時間資訊
/// 模組：Models

import Foundation
import SwiftData

/// 單次修行場次資料模型
/// 使用 SwiftData 進行持久化儲存，追蹤一次修行的完整狀態
/// 包含念誦的咒語名稱、計數進度、圈數及起訖時間
@Model
final class PracticeSession {
    /// 本次修行所念誦的咒語/佛號名稱
    var mantraName: String

    /// 每圈（每輪）的念珠顆數（預設為 108）
    var beadsPerRound: Int

    /// 目前累計念珠計數
    var count: Int

    /// 已完成的圈數（每達到 beadsPerRound 即完成一圈）
    var rounds: Int

    /// 修行開始時間（尚未開始時為 nil）
    var startTime: Date?

    /// 修行結束時間（尚未結束時為 nil）
    var endTime: Date?

    /// 修行場次是否正在進行中
    var isActive: Bool

    /// 迴向文內容（使用者選擇的迴向文模板全文）
    var dedicationText: String?

    /// 迴向對象（使用者自由輸入的迴向對象）
    var dedicationTarget: String?

    /// 是否已完成迴向
    var hasDedication: Bool = false

    /// 當前念珠在本圈中的索引位置（0 到 beadsPerRound-1）
    /// 透過計數取餘數計算，用於 3D 佛珠動畫的定位
    var currentBeadIndex: Int {
        count % beadsPerRound
    }

    /// 本次修行的總時長（單位：秒）
    /// 根據開始與結束時間計算，若任一時間為 nil 則回傳 0
    var duration: TimeInterval {
        guard let start = startTime, let end = endTime else { return 0 }
        return end.timeIntervalSince(start)
    }

    /// 初始化修行場次
    /// - Parameters:
    ///   - mantraName: 念誦的咒語/佛號名稱
    ///   - beadsPerRound: 每圈念珠數量（預設為 108）
    init(mantraName: String, beadsPerRound: Int = 108) {
        self.mantraName = mantraName
        self.beadsPerRound = beadsPerRound
        self.count = 0
        self.rounds = 0
        self.isActive = false
    }

    /// 遞增念珠計數
    /// 每次呼叫將計數加一，並在達到每圈數量時自動更新圈數
    func increment() {
        count += 1
        if count % beadsPerRound == 0 {
            rounds = count / beadsPerRound
        }
    }
}
