//
//  PracticeSessionTests.swift
//  beadsTests
//
//  Created by firstfu on 2026/2/24.
//

import Testing
import Foundation
@testable import beads

struct PracticeSessionTests {
    @Test func createSession() async throws {
        let session = PracticeSession(mantraName: "南無阿彌陀佛", beadsPerRound: 108)
        #expect(session.mantraName == "南無阿彌陀佛")
        #expect(session.beadsPerRound == 108)
        #expect(session.count == 0)
        #expect(session.rounds == 0)
        #expect(session.isActive == false)
    }

    @Test func incrementCount() async throws {
        let session = PracticeSession(mantraName: "南無阿彌陀佛", beadsPerRound: 108)
        session.increment()
        #expect(session.count == 1)
        #expect(session.rounds == 0)
    }

    @Test func completesRound() async throws {
        let session = PracticeSession(mantraName: "南無阿彌陀佛", beadsPerRound: 3)
        session.increment()
        session.increment()
        session.increment()
        #expect(session.count == 3)
        #expect(session.rounds == 1)
    }

    @Test func currentBeadPosition() async throws {
        let session = PracticeSession(mantraName: "南無阿彌陀佛", beadsPerRound: 108)
        #expect(session.currentBeadIndex == 0)
        session.increment()
        #expect(session.currentBeadIndex == 1)
    }

    @Test func sessionDuration() async throws {
        let session = PracticeSession(mantraName: "南無阿彌陀佛", beadsPerRound: 108)
        session.startTime = Date().addingTimeInterval(-60)
        session.endTime = Date()
        #expect(session.duration >= 59 && session.duration <= 61)
    }
}
