//
//  PracticeSession.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

import Foundation
import SwiftData

@Model
final class PracticeSession {
    var mantraName: String
    var beadsPerRound: Int
    var count: Int
    var rounds: Int
    var startTime: Date?
    var endTime: Date?
    var isActive: Bool

    var currentBeadIndex: Int {
        count % beadsPerRound
    }

    var duration: TimeInterval {
        guard let start = startTime, let end = endTime else { return 0 }
        return end.timeIntervalSince(start)
    }

    init(mantraName: String, beadsPerRound: Int = 108) {
        self.mantraName = mantraName
        self.beadsPerRound = beadsPerRound
        self.count = 0
        self.rounds = 0
        self.isActive = false
    }

    func increment() {
        count += 1
        if count % beadsPerRound == 0 {
            rounds = count / beadsPerRound
        }
    }
}
