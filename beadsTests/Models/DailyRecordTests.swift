//
//  DailyRecordTests.swift
//  beadsTests
//
//  Created by firstfu on 2026/2/24.
//

import Testing
import Foundation
@testable import beads

struct DailyRecordTests {
    @Test func createDailyRecord() async throws {
        let record = DailyRecord(date: Date())
        #expect(record.totalCount == 0)
        #expect(record.totalDuration == 0)
        #expect(record.sessionCount == 0)
    }

    @Test func addSessionToRecord() async throws {
        let record = DailyRecord(date: Date())
        record.addSession(count: 108, duration: 300)
        #expect(record.totalCount == 108)
        #expect(record.totalDuration == 300)
        #expect(record.sessionCount == 1)
    }

    @Test func multipleSessions() async throws {
        let record = DailyRecord(date: Date())
        record.addSession(count: 108, duration: 300)
        record.addSession(count: 216, duration: 600)
        #expect(record.totalCount == 324)
        #expect(record.totalDuration == 900)
        #expect(record.sessionCount == 2)
    }
}
