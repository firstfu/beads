//
//  BeadMaterials.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SceneKit

#if os(macOS)
    import AppKit
    typealias PlatformColor = NSColor
#else
    import UIKit
    typealias PlatformColor = UIColor
#endif

enum BeadMaterialType: String, CaseIterable, Identifiable {
    case zitan = "小葉紫檀"
    case bodhi = "菩提子"
    case starMoonBodhi = "星月菩提"
    case huanghuali = "黃花梨"
    case amber = "琥珀蜜蠟"

    var id: String { rawValue }

    var diffuseColor: PlatformColor {
        switch self {
        case .zitan: return PlatformColor(red: 0.35, green: 0.12, blue: 0.08, alpha: 1.0)
        case .bodhi: return PlatformColor(red: 0.85, green: 0.80, blue: 0.70, alpha: 1.0)
        case .starMoonBodhi: return PlatformColor(red: 0.90, green: 0.85, blue: 0.70, alpha: 1.0)
        case .huanghuali: return PlatformColor(red: 0.75, green: 0.58, blue: 0.28, alpha: 1.0)
        case .amber: return PlatformColor(red: 0.90, green: 0.65, blue: 0.20, alpha: 0.85)
        }
    }

    var roughness: CGFloat {
        switch self {
        case .zitan: return 0.3
        case .bodhi: return 0.6
        case .starMoonBodhi: return 0.5
        case .huanghuali: return 0.25
        case .amber: return 0.15
        }
    }

    var metalness: CGFloat {
        switch self {
        case .amber: return 0.05
        default: return 0.0
        }
    }

    func applyTo(_ material: SCNMaterial) {
        material.lightingModel = .physicallyBased
        material.diffuse.contents = diffuseColor
        material.roughness.contents = roughness
        material.metalness.contents = metalness
        if self == .amber {
            material.transparency = 0.85
            material.transparencyMode = .dualLayer
        }
    }
}
