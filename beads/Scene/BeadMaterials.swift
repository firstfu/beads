// MARK: - 檔案說明
/// BeadMaterials.swift
/// 佛珠材質定義 - 提供不同佛珠材質的外觀屬性（顏色、粗糙度、金屬度等）
/// 模組：Scene

//
//  BeadMaterials.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SceneKit

#if os(iOS)
    import RealityKit
#endif

#if os(macOS)
    import AppKit
    /// 跨平台顏色型別別名，macOS 使用 NSColor
    typealias PlatformColor = NSColor
    /// 跨平台圖片型別別名，macOS 使用 NSImage
    typealias PlatformImage = NSImage
#else
    import UIKit
    /// 跨平台顏色型別別名，iOS 使用 UIColor
    typealias PlatformColor = UIColor
    /// 跨平台圖片型別別名，iOS 使用 UIImage
    typealias PlatformImage = UIImage
#endif

/// 佛珠材質類型列舉
/// 定義各種佛珠材質，包含小葉紫檀、菩提子、星月菩提、黃花梨、琥珀蜜蠟等
/// 每種材質提供對應的漫反射顏色、粗糙度及金屬度屬性
enum BeadMaterialType: String, CaseIterable, Identifiable {
    /// 小葉紫檀 - 深紅棕色，質感光滑
    case zitan = "小葉紫檀"
    /// 菩提子 - 淺米色，質感粗糙
    case bodhi = "菩提子"
    /// 星月菩提 - 淡黃白色，質感中等
    case starMoonBodhi = "星月菩提"
    /// 黃花梨 - 金黃棕色，質感較光滑
    case huanghuali = "黃花梨"
    /// 琥珀蜜蠟 - 橙黃色半透明，帶微弱金屬質感
    case amber = "琥珀蜜蠟"

    /// 唯一識別碼，使用 rawValue（材質中文名稱）
    var id: String { rawValue }

    /// 漫反射顏色
    /// 根據不同材質回傳對應的基礎顏色
    var diffuseColor: PlatformColor {
        switch self {
        case .zitan: return PlatformColor(red: 0.28, green: 0.08, blue: 0.05, alpha: 1.0)
        case .bodhi: return PlatformColor(red: 0.55, green: 0.42, blue: 0.28, alpha: 1.0)
        case .starMoonBodhi: return PlatformColor(red: 0.88, green: 0.83, blue: 0.68, alpha: 1.0)
        case .huanghuali: return PlatformColor(red: 0.72, green: 0.52, blue: 0.25, alpha: 1.0)
        case .amber: return PlatformColor(red: 0.85, green: 0.60, blue: 0.18, alpha: 0.85)
        }
    }

    /// 粗糙度
    /// 值越大表面越粗糙，值越小越光滑（範圍 0.0 ~ 1.0）
    var roughness: CGFloat {
        switch self {
        case .zitan: return 0.25          // 紫檀盤玩後油潤光滑
        case .bodhi: return 0.65          // 菩提子天然粗糙表面
        case .starMoonBodhi: return 0.4   // 星月菩提打磨後較光滑
        case .huanghuali: return 0.2      // 黃花梨拋光後光澤好
        case .amber: return 0.1           // 琥珀蜜蠟非常光滑通透
        }
    }

    /// 金屬度
    /// 僅琥珀蜜蠟具有微弱金屬質感，其餘材質為非金屬（範圍 0.0 ~ 1.0）
    var metalness: CGFloat {
        switch self {
        case .zitan: return 0.02          // 紫檀有微弱的油脂光澤
        case .amber: return 0.03          // 琥珀有微弱的樹脂光澤
        default: return 0.0
        }
    }

    /// 漫反射貼圖名稱
    /// 對應 Asset Catalog 中的 Textures 資料夾內的 diffuse 貼圖
    var diffuseTextureName: String {
        switch self {
        case .zitan: return "zitan_diffuse"
        case .bodhi: return "bodhi_diffuse"
        case .starMoonBodhi: return "starMoonBodhi_diffuse"
        case .huanghuali: return "huanghuali_diffuse"
        case .amber: return "amber_diffuse"
        }
    }

    /// 法線貼圖名稱
    /// 對應 Asset Catalog 中的 Textures 資料夾內的 normal map 貼圖
    var normalTextureName: String {
        switch self {
        case .zitan: return "zitan_normal"
        case .bodhi: return "bodhi_normal"
        case .starMoonBodhi: return "starMoonBodhi_normal"
        case .huanghuali: return "huanghuali_normal"
        case .amber: return "amber_normal"
        }
    }

    /// 將材質屬性套用至 SceneKit 材質物件
    /// 設定物理基礎渲染模型、漫反射貼圖（fallback 至純色）、法線貼圖、粗糙度、金屬度，
    /// 若為琥珀蜜蠟則額外設定透明度與雙層透明模式
    /// - Parameter material: 要套用屬性的 SCNMaterial 物件
    func applyTo(_ material: SCNMaterial) {
        material.lightingModel = .physicallyBased

        // Diffuse: prefer texture, fallback to solid color
        if let diffuseImage = PlatformImage(named: diffuseTextureName) {
            material.diffuse.contents = diffuseImage
        } else {
            material.diffuse.contents = diffuseColor
        }

        // Normal map: apply if available
        if let normalImage = PlatformImage(named: normalTextureName) {
            material.normal.contents = normalImage
        }

        material.roughness.contents = roughness
        material.metalness.contents = metalness

        if self == .amber {
            material.transparency = 0.85
            material.transparencyMode = .dualLayer
        }
    }

    // MARK: - RealityKit 材質

    #if os(iOS)
    /// 建立 RealityKit PhysicallyBasedMaterial
    /// 將現有 PBR 屬性轉換為 RealityKit 材質系統
    /// - Returns: 設定好的 PhysicallyBasedMaterial
    @MainActor
    func createRealityKitMaterial() -> any RealityKit.Material {
        var material = PhysicallyBasedMaterial()

        // 漫反射色
        let color = diffuseColor
        material.baseColor = .init(tint: color)

        // 嘗試載入漫反射貼圖
        if let diffuseImage = UIImage(named: diffuseTextureName),
           let cgImage = diffuseImage.cgImage,
           let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .color))
        {
            material.baseColor = .init(texture: .init(texture))
        }

        // 嘗試載入法線貼圖
        if let normalImage = UIImage(named: normalTextureName),
           let cgImage = normalImage.cgImage,
           let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .normal))
        {
            material.normal = .init(texture: .init(texture))
        }

        // PBR 屬性
        material.roughness = .init(floatLiteral: Float(roughness))
        material.metallic = .init(floatLiteral: Float(metalness))

        // 琥珀蜜蠟半透明效果
        if self == .amber {
            material.blending = .transparent(opacity: .init(floatLiteral: 0.85))
        }

        return material
    }
    #endif
}
