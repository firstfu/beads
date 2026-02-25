//
//  DailyRecord.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

// MARK: - 檔案說明

/// DailyRecord.swift
/// 每日修行記錄模型 - 儲存每日的念珠計數、修行時長和場次統計
/// 模組：Models

import Foundation
import SwiftData

/// 每日修行記錄資料模型
/// 使用 SwiftData 進行持久化儲存，記錄每日的修行統計數據
/// 每筆記錄以日期為基準，彙總當日所有修行場次的計數與時長
@Model
final class DailyRecord {
    /// 記錄日期（已正規化為當日零時，僅保留年月日）
    var date: Date

    /// 當日累計念珠總數
    var totalCount: Int

    /// 當日累計修行總時長（單位：秒）
    var totalDuration: TimeInterval

    /// 當日修行場次數量
    var sessionCount: Int

    /// 初始化每日修行記錄
    /// - Parameter date: 記錄的日期（會自動正規化為當日零時）
    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
        self.totalCount = 0
        self.totalDuration = 0
        self.sessionCount = 0
    }

    /// 新增一次修行場次的統計數據
    /// 將本次修行的計數與時長累加至當日總計，並將場次數加一
    /// - Parameters:
    ///   - count: 本次念珠計數
    ///   - duration: 本次修行時長（秒）
    func addSession(count: Int, duration: TimeInterval) {
        totalCount += count
        totalDuration += duration
        sessionCount += 1
    }
}
