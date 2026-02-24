//
//  StatsViewModel.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import Foundation
import SwiftData
import Observation

@Observable
final class StatsViewModel {
    var todayCount: Int = 0
    var todayDuration: TimeInterval = 0
    var todaySessions: Int = 0
    var streakDays: Int = 0
    var weeklyData: [(date: Date, count: Int)] = []
    var monthlyRecords: [DailyRecord] = []

    func load(modelContext: ModelContext) {
        loadToday(modelContext: modelContext)
        loadWeekly(modelContext: modelContext)
        loadMonthly(modelContext: modelContext)
        streakDays = calculateStreak(modelContext: modelContext)
    }

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
