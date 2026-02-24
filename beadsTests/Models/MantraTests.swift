//
//  MantraTests.swift
//  beadsTests
//
//  Created by firstfu on 2026/2/24.
//

import Testing
import Foundation
@testable import beads

struct MantraTests {
    @Test func createMantra() async throws {
        let mantra = Mantra(
            name: "南無阿彌陀佛",
            originalText: "南無阿彌陀佛",
            pinyinText: "Nā mó ā mí tuó fó",
            descriptionText: "淨土宗核心佛號",
            category: "淨土宗",
            suggestedCount: 108
        )
        #expect(mantra.name == "南無阿彌陀佛")
        #expect(mantra.category == "淨土宗")
        #expect(mantra.suggestedCount == 108)
    }
}
