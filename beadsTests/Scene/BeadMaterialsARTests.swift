import Testing
import Foundation
@testable import beads

#if os(iOS)
import RealityKit

@MainActor
struct BeadMaterialsARTests {
    @Test func createRealityKitMaterialExists() async throws {
        let material = BeadMaterialType.zitan.createRealityKitMaterial()
        #expect(material != nil)
    }

    @Test func allMaterialTypesCreateRealityKitMaterial() async throws {
        for type in BeadMaterialType.allCases {
            let material = type.createRealityKitMaterial()
            #expect(material != nil, "Material \(type.rawValue) should create RealityKit material")
        }
    }
}
#endif
