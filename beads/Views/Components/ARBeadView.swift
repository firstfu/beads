// MARK: - 檔案說明
/// ARBeadView.swift
/// AR 佛珠視圖 - 使用 RealityView 在 AR 環境中顯示佛珠，支援平面偵測與手勢互動
/// 模組：Views/Components

//
//  ARBeadView.swift
//  beads
//
//  Created on 2026/2/26.
//

import SwiftUI

#if os(iOS)
import RealityKit
import ARKit

/// AR 佛珠視圖
/// 使用 RealityView 將 3D 佛珠放置在偵測到的真實平面上
struct ARBeadView: View {
    /// AR 佛珠場景管理器
    let sceneManager: ARBeadSceneManager
    /// 佛珠推進時的回呼閉包
    var onBeadAdvance: (() -> Void)?
    /// 是否啟用快速捲動模式
    var fastScrollMode: Bool = false

    /// 是否已將佛珠錨定至平面
    @State private var isAnchored = false
    /// 提示文字
    @State private var instructionText = "將相機對準平面以放置佛珠"
    /// 輕撥手勢狀態
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // AR 場景
            RealityView { content in
                let anchor = AnchorEntity(
                    .plane(
                        .horizontal,
                        classification: .any,
                        minimumBounds: SIMD2<Float>(0.1, 0.1)
                    )
                )
                anchor.addChild(sceneManager.beadRingEntity)
                content.add(anchor)

                // 環境光
                let pointLight = PointLight()
                pointLight.light.intensity = 1000
                pointLight.position = SIMD3<Float>(0, 0.5, 0)
                anchor.addChild(pointLight)
            }
            .gesture(tapGesture)
            .gesture(dragGesture)
            .ignoresSafeArea()

            // 指示文字覆蓋層
            if !isAnchored {
                VStack {
                    Spacer()
                    Text(instructionText)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    isAnchored = true
                }
            }
        }
    }

    // MARK: - 手勢

    /// 點擊手勢 - 推進一顆佛珠
    private var tapGesture: some Gesture {
        TapGesture()
            .onEnded { _ in
                guard !isAnimating else { return }
                isAnimating = true
                sceneManager.animateBeadForward()
                onBeadAdvance?()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    isAnimating = false
                }
            }
    }

    /// 拖曳手勢 - 旋轉佛珠環或輕撥推進
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if fastScrollMode {
                    let delta = Float(-value.translation.height / 300) * sceneManager.anglePerBead
                    sceneManager.rotateRing(by: delta)
                }
            }
            .onEnded { value in
                if fastScrollMode {
                    let totalSteps = Int(abs(value.translation.height) / 30)
                    for _ in 0 ..< totalSteps {
                        onBeadAdvance?()
                    }
                } else if abs(value.translation.height) > 30 && !isAnimating {
                    isAnimating = true
                    sceneManager.animateBeadForward()
                    onBeadAdvance?()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                        isAnimating = false
                    }
                }
            }
    }
}
#endif
