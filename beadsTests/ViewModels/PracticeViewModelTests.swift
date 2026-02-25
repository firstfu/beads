//
//  PracticeViewModelTests.swift
//  beadsTests
//
//  Created by firstfu on 2026/2/24.
//

import Testing
import Foundation
@testable import beads

struct PracticeViewModelTests {
    @Test func initialState() async throws {
        let vm = PracticeViewModel()
        #expect(vm.count == 0)
        #expect(vm.rounds == 0)
        #expect(vm.currentBeadIndex == 0)
        #expect(vm.isActive == false)
        #expect(vm.beadsPerRound == 108)
    }

    @Test func startSession() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "南無阿彌陀佛")
        #expect(vm.isActive == true)
        #expect(vm.mantraName == "南無阿彌陀佛")
    }

    @Test func incrementBead() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "南無阿彌陀佛")
        vm.incrementBead()
        #expect(vm.count == 1)
        #expect(vm.currentBeadIndex == 1)
    }

    @Test func roundCompletion() async throws {
        let vm = PracticeViewModel()
        vm.beadsPerRound = 3
        vm.startSession(mantraName: "test")
        vm.incrementBead()
        vm.incrementBead()
        vm.incrementBead()
        #expect(vm.rounds == 1)
        #expect(vm.didCompleteRound == true)
    }

    @Test func undoLastIncrement() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "test")
        vm.incrementBead()
        vm.incrementBead()
        vm.incrementBead()
        vm.undo()
        #expect(vm.count == 2)
    }

    @Test func undoLimit() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "test")
        vm.incrementBead()
        vm.undo()
        vm.undo()
        #expect(vm.count == 0)
    }

    @Test func todayCount() async throws {
        let vm = PracticeViewModel()
        #expect(vm.todayCount == 0)
    }

    @Test func streakDays() async throws {
        let vm = PracticeViewModel()
        #expect(vm.streakDays == 0)
    }
}
