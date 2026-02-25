// MARK: - 檔案說明
/// StatsViewModel.swift
/// 統計畫面邏輯控制器 - 管理修行統計資料的載入與計算
/// 模組：ViewModels

//
//  StatsViewModel.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import Foundation
import SwiftData
import Observation

/// 統計功能的視圖模型
/// 負責載入並管理今日統計、每週趨勢、每月記錄和連續修行天數
/// 使用 @Observable 巨集提供 SwiftUI 的響應式資料綁定
@Observable
final class StatsViewModel {
    /// 今日累計念珠計數
    var todayCount: Int = 0
    /// 今日累計修行時長（秒）
    var todayDuration: TimeInterval = 0
    /// 今日修行場次數
    var todaySessions: Int = 0
    /// 連續修行天數
    var streakDays: Int = 0
    /// 最近一週的每日統計資料（日期與計數的元組陣列）
    var weeklyData: [(date: Date, count: Int)] = []
    /// 最近一個月的每日修行記錄
    var monthlyRecords: [DailyRecord] = []

    /// 載入所有統計資料
    /// 依序載入今日、每週、每月統計及連續修行天數
    /// - Parameter modelContext: SwiftData 模型上下文，用於查詢資料
    func load(modelContext: ModelContext) {
        loadToday(modelContext: modelContext)
        loadWeekly(modelContext: modelContext)
        loadMonthly(modelContext: modelContext)
        streakDays = calculateStreak(modelContext: modelContext)
    }

    /// 載入今日的修行統計資料
    /// 從資料庫取得今日的計數、時長和場次數
    /// - Parameter modelContext: SwiftData 模型上下文，用於查詢資料
    private func loadToday(modelContext: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.date == today }
        )
        if let record = try? modelContext.fetch(descriptor).first {
            todayCount = record.totalCount
            todayDuration = record.totalDuration
            todaySessions = record.sessionCount
        }
    }

    /// 載入最近一週的每日修行統計
    /// 取得過去七天（含今日）的每日計數資料，用於繪製趨勢圖表
    /// - Parameter modelContext: SwiftData 模型上下文，用於查詢資料
    private func loadWeekly(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return }

        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.date >= weekAgo },
            sortBy: [SortDescriptor(\.date)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []

        weeklyData = (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: weekAgo)!
            let dayStart = calendar.startOfDay(for: date)
            let count = records.first { calendar.startOfDay(for: $0.date) == dayStart }?.totalCount ?? 0
            return (date: date, count: count)
        }
    }

    /// 載入最近一個月的修行記錄
    /// 從資料庫取得過去一個月的每日記錄，按日期排序
    /// - Parameter modelContext: SwiftData 模型上下文，用於查詢資料
    private func loadMonthly(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: today) else { return }

        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.date >= monthAgo },
            sortBy: [SortDescriptor(\.date)]
        )
        monthlyRecords = (try? modelContext.fetch(descriptor)) ?? []
    }

    /// 計算連續修行天數
    /// 從今日往前逐日檢查是否有修行記錄，統計不間斷的連續天數
    /// - Parameter modelContext: SwiftData 模型上下文，用於查詢每日記錄
    /// - Returns: 連續修行的天數
    private func calculateStreak(modelContext: ModelContext) -> Int {
        let descriptor = FetchDescriptor<DailyRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let records = try? modelContext.fetch(descriptor), !records.isEmpty else { return 0 }

        var streak = 0
        var expectedDate = Calendar.current.startOfDay(for: Date())

        for record in records {
            let recordDate = Calendar.current.startOfDay(for: record.date)
            if recordDate == expectedDate && record.totalCount > 0 {
                streak += 1
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if recordDate < expectedDate {
                break
            }
        }
        return streak
    }
}
