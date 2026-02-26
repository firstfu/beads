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

import CoreText
import SceneKit

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
    /// 沉香 - 深褐色，細膩木紋，層次深度
    case agarwood = "沉香"
    /// 檀香 - 淺桃/奶油色，光滑溫潤質感
    case sandalwood = "檀香"
    /// 金絲楠木 - 金橙色，可見紋理線條
    case goldenNanmu = "金絲楠木"
    /// 黑檀 - 極深色近黑，細膩紋理
    case ebony = "黑檀"

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
        case .agarwood: return PlatformColor(red: 0.30, green: 0.18, blue: 0.10, alpha: 1.0)
        case .sandalwood: return PlatformColor(red: 0.82, green: 0.68, blue: 0.50, alpha: 1.0)
        case .goldenNanmu: return PlatformColor(red: 0.75, green: 0.55, blue: 0.25, alpha: 1.0)
        case .ebony: return PlatformColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1.0)
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
        case .agarwood: return 0.3        // 沉香含油脂，較光滑
        case .sandalwood: return 0.35     // 檀香木質溫潤
        case .goldenNanmu: return 0.25    // 金絲楠木拋光後光澤佳
        case .ebony: return 0.2           // 黑檀非常緻密光滑
        }
    }

    /// 金屬度
    /// 僅琥珀蜜蠟具有微弱金屬質感，其餘材質為非金屬（範圍 0.0 ~ 1.0）
    var metalness: CGFloat {
        switch self {
        case .zitan: return 0.02          // 紫檀有微弱的油脂光澤
        case .amber: return 0.03          // 琥珀有微弱的樹脂光澤
        case .agarwood: return 0.02       // 沉香有微弱油脂光澤
        case .ebony: return 0.01          // 黑檀有微弱光澤
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
        case .agarwood: return "agarwood_diffuse"
        case .sandalwood: return "sandalwood_diffuse"
        case .goldenNanmu: return "goldenNanmu_diffuse"
        case .ebony: return "ebony_diffuse"
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
        case .agarwood: return "agarwood_normal"
        case .sandalwood: return "sandalwood_normal"
        case .goldenNanmu: return "goldenNanmu_normal"
        case .ebony: return "ebony_normal"
        }
    }

    /// 將材質屬性套用至 SceneKit 材質物件
    /// 設定物理基礎渲染模型、漫反射貼圖（fallback 至純色）、法線貼圖、粗糙度、金屬度，
    /// 若為琥珀蜜蠟則額外設定透明度與雙層透明模式
    /// - Parameters:
    ///   - material: 要套用屬性的 SCNMaterial 物件
    ///   - isGuruBead: 是否為母珠，若為 true 則使用合成刻印卍字的漫反射貼圖
    func applyTo(_ material: SCNMaterial, isGuruBead: Bool = false) {
        material.lightingModel = .physicallyBased

        // Diffuse: guru bead 使用刻印紋理，一般佛珠使用原始貼圖或純色
        if isGuruBead, let engravedTexture = BeadDecoration.engravedDiffuseTexture(for: self) {
            material.diffuse.contents = engravedTexture
        } else if let diffuseImage = PlatformImage(named: diffuseTextureName) {
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

}

/// 佛珠裝飾工具
/// 提供將佛教符號（如卍字）合成到佛珠漫反射貼圖中的功能，
/// 模擬燒印/刻印在木頭表面上的自然效果
enum BeadDecoration {

    /// 紋理快取，避免每次材質變更時重新合成
    private static var textureCache: [String: PlatformImage] = [:]
    /// 卍字遮罩快取
    private static var maskCache: CGImage?

    /// 取得帶有燒印卍字的漫反射貼圖
    /// 將卍字刻印效果合成到指定材質的漫反射貼圖中
    /// - Parameter materialType: 佛珠材質類型
    /// - Returns: 合成後的漫反射貼圖
    static func engravedDiffuseTexture(for materialType: BeadMaterialType) -> PlatformImage? {
        let cacheKey = "engraved_\(materialType.rawValue)"
        if let cached = textureCache[cacheKey] {
            return cached
        }

        let textureSize: CGFloat = 1024

        // 取得基底貼圖（優先使用貼圖，fallback 至純色）
        let baseImage: PlatformImage
        if let tex = PlatformImage(named: materialType.diffuseTextureName) {
            baseImage = tex
        } else {
            guard let solid = createSolidColorImage(color: materialType.diffuseColor, size: textureSize) else {
                return nil
            }
            baseImage = solid
        }

        // 取得卍字遮罩（快取）
        let mask: CGImage
        if let cached = maskCache {
            mask = cached
        } else {
            guard let newMask = createSwastikaMask(size: textureSize) else { return nil }
            maskCache = newMask
            mask = newMask
        }

        // 合成刻印紋理
        guard let result = createEngravedDiffuseTexture(baseImage: baseImage, mask: mask, size: textureSize) else {
            return nil
        }

        textureCache[cacheKey] = result
        return result
    }

    /// 建立卍字遮罩圖（白色卍字在黑色背景上）
    /// 使用 Core Text 繪製卍字到灰階 CGContext，作為紋理合成的遮罩
    /// - Parameter size: 遮罩圖尺寸（像素，正方形）
    /// - Returns: 灰階 CGImage 遮罩
    private static func createSwastikaMask(size: CGFloat) -> CGImage? {
        let width = Int(size)
        let height = Int(size)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let ctx = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width,
            space: colorSpace, bitmapInfo: 0
        ) else { return nil }

        // 黑色背景
        ctx.setFillColor(gray: 0, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

        // 白色卍字 — 使用 Core Text 繪製，跨平台一致
        let fontSize = size * 0.35
        let font = CTFontCreateWithName("HiraginoSans-W6" as CFString, fontSize, nil)
        let cfStr = "卍" as CFString
        let attrStr = CFAttributedStringCreateMutable(nil, 0)!
        CFAttributedStringReplaceString(attrStr, CFRange(location: 0, length: 0), cfStr)
        let range = CFRange(location: 0, length: CFStringGetLength(cfStr))
        CFAttributedStringSetAttribute(attrStr, range, kCTFontAttributeName, font)
        CFAttributedStringSetAttribute(attrStr, range, kCTForegroundColorAttributeName, CGColor(gray: 1, alpha: 1))

        let line = CTLineCreateWithAttributedString(attrStr)
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        let lineWidth = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))

        // 置中繪製：紋理中心 (0.5, 0.5) 對應球體正前方
        let x = (size - lineWidth) / 2
        let y = (size - ascent + descent) / 2
        ctx.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, ctx)

        return ctx.makeImage()
    }

    /// 將卍字遮罩合成到漫反射貼圖中
    /// 在遮罩區域內暗化基底貼圖並加入微弱金色色調，模擬燒印/刻印效果
    /// - Parameters:
    ///   - baseImage: 基底漫反射貼圖
    ///   - mask: 卍字灰階遮罩
    ///   - size: 輸出紋理尺寸
    /// - Returns: 合成後的漫反射貼圖
    private static func createEngravedDiffuseTexture(baseImage: PlatformImage, mask: CGImage, size: CGFloat) -> PlatformImage? {
        let width = Int(size)
        let height = Int(size)
        let fullRect = CGRect(x: 0, y: 0, width: size, height: size)

        guard let baseCGImage = cgImage(from: baseImage) else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // 1. 繪製基底木紋貼圖
        ctx.draw(baseCGImage, in: fullRect)

        // 2. 設定 clip to mask（卍字遮罩區域）
        ctx.saveGState()
        ctx.clip(to: fullRect, mask: mask)

        // 3. 在遮罩區域內填充深色半透明色（模擬刻痕陰影）
        ctx.setFillColor(PlatformColor(red: 0.05, green: 0.03, blue: 0.02, alpha: 0.4).cgColor)
        ctx.fill(fullRect)

        // 4. 以 softLight 混合模式加入微弱金色（模擬金漆填刻）
        ctx.setBlendMode(.softLight)
        ctx.setFillColor(PlatformColor(red: 0.85, green: 0.65, blue: 0.15, alpha: 0.3).cgColor)
        ctx.fill(fullRect)

        ctx.restoreGState()

        // 5. 結果作為 guru bead 的 material.diffuse.contents
        guard let resultCGImage = ctx.makeImage() else { return nil }
        return platformImage(from: resultCGImage, size: size)
    }

    /// 為無貼圖的 fallback 顏色建立純色圖片
    /// - Parameters:
    ///   - color: 填充顏色
    ///   - size: 圖片尺寸（像素，正方形）
    /// - Returns: 純色圖片
    private static func createSolidColorImage(color: PlatformColor, size: CGFloat) -> PlatformImage? {
        let width = Int(size)
        let height = Int(size)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.setFillColor(color.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

        guard let cgImg = ctx.makeImage() else { return nil }
        return platformImage(from: cgImg, size: size)
    }

    // MARK: - 跨平台圖片轉換

    private static func cgImage(from image: PlatformImage) -> CGImage? {
        #if os(macOS)
            return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
            return image.cgImage
        #endif
    }

    private static func platformImage(from cgImage: CGImage, size: CGFloat) -> PlatformImage {
        #if os(macOS)
            return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
        #else
            return UIImage(cgImage: cgImage)
        #endif
    }
}
