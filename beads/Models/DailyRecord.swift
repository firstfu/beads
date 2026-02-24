//
//  DailyRecord.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

import Foundation
import SwiftData

@Model
final class DailyRecord {
    var date: Date
    var totalCount: Int
    var totalDuration: TimeInterval
    var sessionCount: Int

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
        self.totalCount = 0
        self.totalDuration = 0
        self.sessionCount = 0
    }

    func addSession(count: Int, duration: TimeInterval) {
        totalCount += count
        totalDuration += duration
        sessionCount += 1
    }
}
