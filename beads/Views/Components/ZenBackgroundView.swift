// MARK: - 檔案說明
/// ZenBackgroundView.swift
/// 禪意背景視圖 - 使用 Canvas 繪製漸層、水墨紋理、漂浮粒子與蓮花裝飾
/// 模組：Views/Components

//
//  ZenBackgroundView.swift
//  beads
//
//  Created by firstfu on 2026/2/26.
//

import SwiftUI

// MARK: - ZenBackgroundTheme

/// 禪意背景主題列舉
/// 提供 5 種主題配色，營造不同的修行氛圍
enum ZenBackgroundTheme: String, CaseIterable, Identifiable, Codable {
    /// 水墨（預設深色主題）
    case inkWash = "水墨"
    /// 午夜深藍
    case midnight = "午夜"
    /// 寺廟金棕
    case temple = "寺廟"
    /// 蓮花粉紫
    case lotus = "蓮花"
    /// 竹林翠綠
    case forest = "竹林"

    var id: String { rawValue }
}

// MARK: - ZenColors

/// 禪意配色方案
/// 每個主題包含五層顏色，用於繪製漸層、紋理和裝飾元素
private struct ZenColors {
    let primary: Color
    let secondary: Color
    let accent: Color
    let highlight: Color
    let glow: Color

    static func colors(for theme: ZenBackgroundTheme) -> ZenColors {
        switch theme {
        case .inkWash:
            return ZenColors(
                primary: Color(red: 0.10, green: 0.10, blue: 0.10),
                secondary: Color(red: 0.18, green: 0.18, blue: 0.18),
                accent: Color(red: 0.29, green: 0.29, blue: 0.29),
                highlight: Color(red: 0.55, green: 0.55, blue: 0.55),
                glow: Color(red: 0.83, green: 0.66, blue: 0.29)
            )
        case .midnight:
            return ZenColors(
                primary: Color(red: 0.05, green: 0.11, blue: 0.16),
                secondary: Color(red: 0.11, green: 0.15, blue: 0.23),
                accent: Color(red: 0.25, green: 0.35, blue: 0.47),
                highlight: Color(red: 0.47, green: 0.55, blue: 0.66),
                glow: Color(red: 0.29, green: 0.56, blue: 0.85)
            )
        case .temple:
            return ZenColors(
                primary: Color(red: 0.11, green: 0.08, blue: 0.06),
                secondary: Color(red: 0.18, green: 0.13, blue: 0.09),
                accent: Color(red: 0.36, green: 0.24, blue: 0.18),
                highlight: Color(red: 0.72, green: 0.53, blue: 0.04),
                glow: Color(red: 0.83, green: 0.66, blue: 0.29)
            )
        case .lotus:
            return ZenColors(
                primary: Color(red: 0.10, green: 0.08, blue: 0.13),
                secondary: Color(red: 0.18, green: 0.15, blue: 0.21),
                accent: Color(red: 0.35, green: 0.29, blue: 0.42),
                highlight: Color(red: 0.85, green: 0.66, blue: 0.77),
                glow: Color(red: 0.91, green: 0.71, blue: 0.83)
            )
        case .forest:
            return ZenColors(
                primary: Color(red: 0.04, green: 0.08, blue: 0.06),
                secondary: Color(red: 0.08, green: 0.15, blue: 0.13),
                accent: Color(red: 0.16, green: 0.29, blue: 0.23),
                highlight: Color(red: 0.29, green: 0.54, blue: 0.35),
                glow: Color(red: 0.42, green: 0.75, blue: 0.48)
            )
        }
    }
}

// MARK: - ZenBackgroundView

/// 禪意背景視圖
/// 使用 TimelineView + Canvas 繪製動態禪意背景，
/// 包含多層漸層、水墨紋理、漂浮粒子和蓮花裝飾
struct ZenBackgroundView: View {
    /// 背景主題
    var theme: ZenBackgroundTheme = .inkWash
    /// 是否啟用漂浮粒子動畫
    var enableParticles: Bool = true
    /// 是否啟用蓮花裝飾
    var enableLotusDecoration: Bool = true

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let colors = ZenColors.colors(for: theme)
                let time = timeline.date.timeIntervalSinceReferenceDate
                // 20 秒為一個完整動畫循環
                let animationValue = time.truncatingRemainder(dividingBy: 20.0) / 20.0

                drawGradientBackground(context: context, size: size, colors: colors)
                drawInkTexture(context: context, size: size, colors: colors)
                drawCloudPattern(context: context, size: size, colors: colors)

                if enableParticles {
                    drawFloatingParticles(
                        context: context, size: size, colors: colors,
                        animationValue: animationValue
                    )
                }

                if enableLotusDecoration {
                    drawCornerLotus(context: context, size: size, colors: colors)
                }

                drawEdgeGlow(context: context, size: size, colors: colors)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - 繪製主漸層背景

    private func drawGradientBackground(
        context: GraphicsContext, size: CGSize, colors: ZenColors
    ) {
        let rect = CGRect(origin: .zero, size: size)

        // 線性漸層（上→下）
        let gradient = Gradient(stops: [
            .init(color: colors.primary, location: 0.0),
            .init(color: colors.secondary, location: 0.5),
            .init(color: colors.primary.opacity(0.95), location: 1.0),
        ])

        context.fill(
            Path(rect),
            with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: size.width / 2, y: 0),
                endPoint: CGPoint(x: size.width / 2, y: size.height)
            )
        )

        // 徑向光暈（中心偏上方）
        let glowCenter = CGPoint(x: size.width / 2, y: size.height * 0.35)
        let glowGradient = Gradient(stops: [
            .init(color: colors.glow.opacity(0.08), location: 0.0),
            .init(color: colors.accent.opacity(0.03), location: 0.5),
            .init(color: .clear, location: 1.0),
        ])

        context.fill(
            Path(rect),
            with: .radialGradient(
                glowGradient,
                center: glowCenter,
                startRadius: 0,
                endRadius: size.height * 0.6
            )
        )
    }

    // MARK: - 繪製水墨紋理

    private func drawInkTexture(
        context: GraphicsContext, size: CGSize, colors: ZenColors
    ) {
        // 使用固定種子模擬隨機水墨暈染
        let positions: [(Double, Double, Double)] = [
            (0.15, 0.20, 80), (0.70, 0.10, 120), (0.40, 0.55, 100),
            (0.85, 0.40, 90), (0.25, 0.75, 110), (0.60, 0.85, 70),
            (0.10, 0.50, 130), (0.90, 0.70, 95),
        ]

        for (xRatio, yRatio, radius) in positions {
            let x = size.width * xRatio
            let y = size.height * yRatio
            var blurContext = context
            blurContext.addFilter(.blur(radius: 50))

            let circle = Path(
                ellipseIn: CGRect(
                    x: x - radius, y: y - radius,
                    width: radius * 2, height: radius * 2
                )
            )
            blurContext.fill(circle, with: .color(colors.accent.opacity(0.05)))
        }
    }

    // MARK: - 繪製裝飾性雲紋

    private func drawCloudPattern(
        context: GraphicsContext, size: CGSize, colors: ZenColors
    ) {
        // 頂部雲紋
        var topCloud = Path()
        topCloud.move(to: CGPoint(x: 0, y: 0))
        topCloud.addQuadCurve(
            to: CGPoint(x: size.width * 0.4, y: size.height * 0.05),
            control: CGPoint(x: size.width * 0.2, y: size.height * 0.1)
        )
        topCloud.addQuadCurve(
            to: CGPoint(x: size.width * 0.8, y: size.height * 0.08),
            control: CGPoint(x: size.width * 0.6, y: 0)
        )
        topCloud.addQuadCurve(
            to: CGPoint(x: size.width, y: size.height * 0.05),
            control: CGPoint(x: size.width * 0.9, y: size.height * 0.12)
        )
        topCloud.addLine(to: CGPoint(x: size.width, y: 0))
        topCloud.closeSubpath()

        context.fill(topCloud, with: .color(colors.highlight.opacity(0.03)))

        // 底部雲紋
        var bottomCloud = Path()
        bottomCloud.move(to: CGPoint(x: 0, y: size.height))
        bottomCloud.addQuadCurve(
            to: CGPoint(x: size.width * 0.5, y: size.height * 0.95),
            control: CGPoint(x: size.width * 0.3, y: size.height * 0.92)
        )
        bottomCloud.addQuadCurve(
            to: CGPoint(x: size.width, y: size.height * 0.9),
            control: CGPoint(x: size.width * 0.7, y: size.height * 0.98)
        )
        bottomCloud.addLine(to: CGPoint(x: size.width, y: size.height))
        bottomCloud.closeSubpath()

        context.fill(bottomCloud, with: .color(colors.highlight.opacity(0.03)))
    }

    // MARK: - 繪製漂浮粒子

    private func drawFloatingParticles(
        context: GraphicsContext, size: CGSize, colors: ZenColors,
        animationValue: Double
    ) {
        // 固定種子的粒子位置與速度
        let particles: [(Double, Double, Double, Double)] = [
            (0.05, 0.10, 1.5, 0.6), (0.12, 0.30, 2.0, 0.7), (0.20, 0.55, 1.2, 0.5),
            (0.28, 0.80, 2.5, 0.8), (0.35, 0.15, 1.8, 0.6), (0.42, 0.45, 1.0, 0.9),
            (0.50, 0.70, 2.2, 0.7), (0.58, 0.25, 1.3, 0.5), (0.65, 0.60, 2.8, 0.8),
            (0.72, 0.90, 1.6, 0.6), (0.78, 0.35, 2.0, 0.7), (0.85, 0.50, 1.4, 0.9),
            (0.92, 0.20, 2.3, 0.5), (0.08, 0.65, 1.7, 0.8), (0.18, 0.85, 2.1, 0.6),
            (0.30, 0.40, 1.1, 0.7), (0.45, 0.95, 2.6, 0.5), (0.55, 0.05, 1.9, 0.8),
            (0.62, 0.75, 1.3, 0.6), (0.75, 0.55, 2.4, 0.7), (0.82, 0.15, 1.5, 0.9),
            (0.90, 0.45, 2.0, 0.5), (0.15, 0.70, 1.8, 0.8), (0.38, 0.25, 2.2, 0.6),
            (0.52, 0.85, 1.4, 0.7), (0.68, 0.10, 2.7, 0.5), (0.88, 0.60, 1.6, 0.8),
            (0.25, 0.50, 2.0, 0.6), (0.48, 0.35, 1.2, 0.9), (0.70, 0.80, 2.5, 0.7),
        ]

        for (i, (xRatio, yRatio, particleSize, speed)) in particles.enumerated() {
            let baseX = size.width * xRatio
            let baseY = size.height * yRatio

            // 向上漂浮
            let offsetY = animationValue * speed * size.height
            let y = (baseY - offsetY).truncatingRemainder(dividingBy: size.height)
            let adjustedY = y < 0 ? y + size.height : y

            // 水平輕微擺動
            let swayAmount = sin(animationValue * .pi * 2 + Double(i)) * 10
            let x = baseX + swayAmount

            // 透明度隨高度變化
            let alphaFactor = 1.0 - (adjustedY / size.height)
            let alpha = 0.1 + alphaFactor * 0.2

            let circle = Path(
                ellipseIn: CGRect(
                    x: x - particleSize / 2, y: adjustedY - particleSize / 2,
                    width: particleSize, height: particleSize
                )
            )
            context.fill(circle, with: .color(colors.glow.opacity(alpha)))
        }
    }

    // MARK: - 繪製角落蓮花裝飾

    private func drawCornerLotus(
        context: GraphicsContext, size: CGSize, colors: ZenColors
    ) {
        // 右下角蓮花
        drawDecorativeLotus(
            context: context,
            center: CGPoint(x: size.width - 60, y: size.height - 100),
            petalSize: 50,
            color: colors.highlight.opacity(0.08)
        )

        // 左上角小蓮花
        drawDecorativeLotus(
            context: context,
            center: CGPoint(x: 40, y: 80),
            petalSize: 30,
            color: colors.highlight.opacity(0.05)
        )
    }

    private func drawDecorativeLotus(
        context: GraphicsContext, center: CGPoint, petalSize: Double, color: Color
    ) {
        let petalCount = 6

        for i in 0..<petalCount {
            let angle = (2 * .pi * Double(i) / Double(petalCount)) - .pi / 2

            var petalPath = Path()
            petalPath.move(to: .zero)
            petalPath.addQuadCurve(
                to: CGPoint(x: 0, y: -petalSize * 0.8),
                control: CGPoint(x: petalSize * 0.3, y: -petalSize * 0.5)
            )
            petalPath.addQuadCurve(
                to: .zero,
                control: CGPoint(x: -petalSize * 0.3, y: -petalSize * 0.5)
            )

            let transform = CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: angle)
            let transformedPath = petalPath.applying(transform)

            context.fill(transformedPath, with: .color(color))
        }

        // 中心點
        let centerDot = Path(
            ellipseIn: CGRect(
                x: center.x - petalSize * 0.15, y: center.y - petalSize * 0.15,
                width: petalSize * 0.3, height: petalSize * 0.3
            )
        )
        context.fill(centerDot, with: .color(color.opacity(0.5)))
    }

    // MARK: - 繪製邊緣光暈

    private func drawEdgeGlow(
        context: GraphicsContext, size: CGSize, colors: ZenColors
    ) {
        // 頂部邊緣光
        let topGlowRect = CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.3)
        let topGlowGradient = Gradient(stops: [
            .init(color: colors.glow.opacity(0.1), location: 0.0),
            .init(color: .clear, location: 1.0),
        ])

        context.fill(
            Path(topGlowRect),
            with: .linearGradient(
                topGlowGradient,
                startPoint: CGPoint(x: size.width / 2, y: 0),
                endPoint: CGPoint(x: size.width / 2, y: size.height * 0.3)
            )
        )

        // 邊框微光
        let borderRect = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)
        let borderGradient = Gradient(stops: [
            .init(color: colors.highlight.opacity(0.05), location: 0.0),
            .init(color: .clear, location: 0.5),
            .init(color: colors.highlight.opacity(0.05), location: 1.0),
        ])

        context.stroke(
            Path(borderRect),
            with: .linearGradient(
                borderGradient,
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)
            ),
            lineWidth: 1
        )
    }
}

#Preview {
    ZStack {
        ZenBackgroundView(theme: .inkWash)
        Text("禪意背景")
            .font(.largeTitle)
            .foregroundStyle(.white)
    }
}
