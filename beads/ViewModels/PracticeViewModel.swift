//
//  PracticeViewModel.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

import Foundation
import SwiftData
import Observation

@Observable
final class PracticeViewModel {
    var count: Int = 0
    var rounds: Int = 0
    var beadsPerRound: Int = 108
    var isActive: Bool = false
    var mantraName: String = "南無阿彌陀佛"
    var didCompleteRound: Bool = false
    var todayCount: Int = 0
    var streakDays: Int = 0

    private var undoStack: [Int] = []
    private let maxUndoCount = 5
    private var sessionStartTime: Date?

    var currentBeadIndex: Int {
        count % beadsPerRound
    }

    func startSession(mantraName: String) {
        self.mantraName = mantraName
        self.isActive = true
        self.sessionStartTime = Date()
        self.didCompleteRound = false
    }

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

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        count = previous
        rounds = count / beadsPerRound
        didCompleteRound = false
    }

    func endSession(modelContext: ModelContext) {
        guard isActive else { return }
        isActive = false
        let endTime = Date()

        let session = PracticeSession(mantraName: mantraName, beadsPerRound: beadsPerRound)
        session.count = count
        session.rounds = rounds
        session.startTime = sessionStartTime
        session.endTime = endTime
        session.isActive = false
        modelContext.insert(session)

        updateDailyRecord(modelContext: modelContext, count: count, duration: endTime.timeIntervalSince(sessionStartTime ?? endTime))
        try? modelContext.save()
    }

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

    func resetCount() {
        count = 0
        rounds = 0
        undoStack.removeAll()
        didCompleteRound = false
    }
}
