//
//  UserSettingsARTests.swift
//  beadsTests
//
//  Created by firstfu on 2026/2/26.
//

import Testing
import Foundation
@testable import beads

struct UserSettingsARTests {
    @Test func arDisplayModeExists() async throws {
        let mode = BeadDisplayMode.ar
        #expect(mode.rawValue == "AR 實境")
    }

    @Test func arDisplayModeIdentifiable() async throws {
        let mode = BeadDisplayMode.ar
        #expect(mode.id == "AR 實境")
    }

    @Test func allCasesIncludesAR() async throws {
        #expect(BeadDisplayMode.allCases.contains(.ar))
        #expect(BeadDisplayMode.allCases.count == 3)
    }
}
