import Testing
import Foundation
@testable import beads

struct DedicationTemplateTests {
    @Test func allCasesExist() async throws {
        #expect(DedicationTemplate.allCases.count == 5)
    }

    @Test func eachTemplateHasNameAndText() async throws {
        for template in DedicationTemplate.allCases {
            #expect(!template.name.isEmpty)
            #expect(!template.fullText.isEmpty)
        }
    }

    @Test func universalTemplateContent() async throws {
        let template = DedicationTemplate.universal
        #expect(template.name == "通用迴向文")
        #expect(template.fullText.contains("願以此功德"))
    }
}
