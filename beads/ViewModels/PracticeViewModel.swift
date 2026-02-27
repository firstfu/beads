// MARK: - 檔案說明
/// PracticeViewModel.swift
/// 修行畫面邏輯控制器 - 管理念珠計數、回合追蹤和修行狀態
/// 模組：ViewModels

//
//  PracticeViewModel.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

import Foundation
import SwiftData
import Observation

/// 修行功能的視圖模型
/// 管理修行過程中的計數、回合、撤銷操作和每日統計
/// 使用 @Observable 巨集提供 SwiftUI 的響應式資料綁定
@Observable
final class PracticeViewModel {
    /// 目前累計的念珠計數
    var count: Int = 0
    /// 已完成的回合數
    var rounds: Int = 0
    /// 每回合的念珠數量，預設為 108 顆
    var beadsPerRound: Int = 108
    /// 修行場次是否正在進行中
    var isActive: Bool = false
    /// 目前持誦的咒語名稱
    var mantraName: String = "南無阿彌陀佛"
    /// 是否剛完成一個回合（用於觸發完成動畫或提示）
    var didCompleteRound: Bool = false
    /// 今日累計念珠計數
    var todayCount: Int = 0
    /// 連續修行天數
    var streakDays: Int = 0

    /// 撤銷操作的歷史堆疊，記錄先前的計數值
    private var undoStack: [Int] = []
    /// 撤銷堆疊的最大容量限制
    private let maxUndoCount = 5
    /// 本次修行場次的開始時間
    private var sessionStartTime: Date?

    /// 目前念珠在本回合中的位置索引
    /// - Returns: 當前計數對每回合數量取餘數的結果
    var currentBeadIndex: Int {
        count % beadsPerRound
    }

    /// 開始新的修行場次
    /// 設定咒語名稱、啟動修行狀態並記錄開始時間
    /// - Parameter mantraName: 本次修行要持誦的咒語名稱
    func startSession(mantraName: String) {
        self.mantraName = mantraName
        self.isActive = true
        self.sessionStartTime = Date()
        self.didCompleteRound = false
    }

    /// 撥動一顆念珠，計數加一
    /// 將當前計數存入撤銷堆疊後遞增，並檢查是否完成新的回合
    func incrementBead() {
        guard isActive else { return }
        undoStack.append(count)
        if undoStack.count > maxUndoCount {
            undoStack.removeFirst()
        }
        count += 1
        let newRounds = count / beadsPerRound
        if newRounds > rounds {
            rounds = newRounds
            didCompleteRound = true
        } else {
            didCompleteRound = false
        }
    }

    /// 撤銷上一次的念珠撥動操作
    /// 從撤銷堆疊中恢復先前的計數值，並重新計算回合數
    func undo() {
        guard let previous = undoStack.popLast() else { return }
        count = previous
        rounds = count / beadsPerRound
        didCompleteRound = false
    }

    /// 結束當前修行場次
    /// 儲存修行記錄到資料庫，並更新每日統計資料
    /// - Parameters:
    ///   - modelContext: SwiftData 模型上下文，用於資料持久化
    ///   - dedicationText: 迴向文內容（選填）
    ///   - dedicationTarget: 迴向對象（選填）
    func endSession(modelContext: ModelContext, dedicationText: String? = nil, dedicationTarget: String? = nil) {
        guard isActive, count > 0 else {
            isActive = false
            return
        }
        isActive = false
        let endTime = Date()

        let session = PracticeSession(mantraName: mantraName, beadsPerRound: beadsPerRound)
        session.count = count
        session.rounds = rounds
        session.startTime = sessionStartTime
        session.endTime = endTime
        session.isActive = false

        if let dedicationText {
            session.dedicationText = dedicationText
            session.dedicationTarget = dedicationTarget
            session.hasDedication = true
        }

        modelContext.insert(session)

        updateDailyRecord(modelContext: modelContext, count: count, duration: endTime.timeIntervalSince(sessionStartTime ?? endTime))
        try? modelContext.save()
    }

    /// 結束修行並重置，開始新的修行場次
    /// 用於使用者主動點擊「結束修行」時的完整流程
    /// - Parameters:
    ///   - modelContext: SwiftData 模型上下文
    ///   - dedicationText: 迴向文內容（選填）
    ///   - dedicationTarget: 迴向對象（選填）
    func endSessionAndRestart(modelContext: ModelContext, dedicationText: String? = nil, dedicationTarget: String? = nil) {
        endSession(modelContext: modelContext, dedicationText: dedicationText, dedicationTarget: dedicationTarget)
        resetCount()
        startSession(mantraName: mantraName)
        loadTodayStats(modelContext: modelContext)
    }

    /// 載入今日的修行統計資料
    /// 從資料庫取得今日的念珠計數和連續修行天數
    /// - Parameter modelContext: SwiftData 模型上下文，用於查詢資料
    func loadTodayStats(modelContext: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.date == today }
        )
        if let record = try? modelContext.fetch(descriptor).first {
            todayCount = record.totalCount
        } else {
            todayCount = 0
        }
        streakDays = calculateStreak(modelContext: modelContext)
    }

    /// 更新每日修行記錄
    /// 若今日已有記錄則累加，否則建立新的每日記錄
    /// - Parameters:
    ///   - modelContext: SwiftData 模型上下文，用於查詢和寫入資料
    ///   - count: 本次修行的念珠計數
    ///   - duration: 本次修行的持續時間（秒）
    private func updateDailyRecord(modelContext: ModelContext, count: Int, duration: TimeInterval) {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.date == today }
        )
        let record: DailyRecord
        if let existing = try? modelContext.fetch(descriptor).first {
            record = existing
        } else {
            record = DailyRecord(date: today)
            modelContext.insert(record)
        }
        record.addSession(count: count, duration: duration)
        todayCount = record.totalCount
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

    /// 重置計數狀態
    /// 將計數、回合數歸零，清空撤銷堆疊並重置回合完成標記
    func resetCount() {
        count = 0
        rounds = 0
        undoStack.removeAll()
        didCompleteRound = false
    }

    /// 更新每圈珠數並重置計數狀態
    /// - Parameter count: 新的每圈珠數
    func updateBeadsPerRound(_ count: Int) {
        beadsPerRound = count
        resetCount()
    }
}
