// MARK: - 檔案說明
/// ARBeadView.swift
/// AR 佛珠視圖 - 使用 ARView 在 AR 環境中顯示相機畫面與佛珠，支援平面偵測與手勢互動
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
/// 使用 ARView (UIKit) 顯示相機畫面，並將 3D 佛珠放置在偵測到的真實平面上
struct ARBeadView: View {
    /// AR 佛珠場景管理器
    let sceneManager: ARBeadSceneManager
    /// 佛珠推進時的回呼閉包
    var onBeadAdvance: (() -> Void)?
    /// 是否啟用快速捲動模式
    var fastScrollMode: Bool = false

    var body: some View {
        ARViewContainer(
            sceneManager: sceneManager,
            onBeadAdvance: onBeadAdvance,
            fastScrollMode: fastScrollMode
        )
        .ignoresSafeArea()
    }
}

// MARK: - ARView UIKit 包裝

/// 將 RealityKit 的 ARView 包裝為 SwiftUI 視圖
/// ARView 自動處理相機畫面渲染、AR session 管理與平面偵測
private struct ARViewContainer: UIViewRepresentable {
    let sceneManager: ARBeadSceneManager
    var onBeadAdvance: (() -> Void)?
    var fastScrollMode: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // 關閉自動配置，避免覆蓋我們的平面偵測設定
        arView.automaticallyConfigureSession = false

        // 配置 AR session — 水平面偵測 + 環境光估算
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        arView.session.run(config)

        // 加入 Apple 標準的平面偵測引導覆蓋層
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)

        // 建立錨點，偵測到水平面時自動放置佛珠
        let anchor = AnchorEntity(
            .plane(
                .horizontal,
                classification: .any,
                minimumBounds: SIMD2<Float>(0.05, 0.05)
            )
        )
        anchor.addChild(sceneManager.beadRingEntity)

        // 環境光
        let pointLight = PointLight()
        pointLight.light.intensity = 1000
        pointLight.position = SIMD3<Float>(0, 0.5, 0)
        anchor.addChild(pointLight)

        arView.scene.addAnchor(anchor)

        // 設定手勢
        let tapRecognizer = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        let panRecognizer = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        arView.addGestureRecognizer(tapRecognizer)
        arView.addGestureRecognizer(panRecognizer)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.fastScrollMode = fastScrollMode
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(sceneManager: sceneManager, onBeadAdvance: onBeadAdvance, fastScrollMode: fastScrollMode)
    }

    // MARK: - Coordinator（手勢處理）

    @MainActor
    class Coordinator: NSObject {
        let sceneManager: ARBeadSceneManager
        var onBeadAdvance: (() -> Void)?
        var fastScrollMode: Bool
        private var isAnimating = false

        init(sceneManager: ARBeadSceneManager, onBeadAdvance: (() -> Void)?, fastScrollMode: Bool) {
            self.sceneManager = sceneManager
            self.onBeadAdvance = onBeadAdvance
            self.fastScrollMode = fastScrollMode
        }

        /// 點擊手勢 — 推進一顆佛珠
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard !isAnimating else { return }
            isAnimating = true
            sceneManager.animateBeadForward()
            onBeadAdvance?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
                self?.isAnimating = false
            }
        }

        /// 拖曳手勢 — 旋轉佛珠環或輕撥推進
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)

            switch gesture.state {
            case .changed:
                if fastScrollMode {
                    let delta = Float(-translation.y / 300) * sceneManager.anglePerBead
                    sceneManager.rotateRing(by: delta)
                    gesture.setTranslation(.zero, in: gesture.view)
                }
            case .ended:
                if fastScrollMode {
                    let totalSteps = Int(abs(translation.y) / 30)
                    for _ in 0..<totalSteps {
                        onBeadAdvance?()
                    }
                } else if abs(translation.y) > 30 && !isAnimating {
                    isAnimating = true
                    sceneManager.animateBeadForward()
                    onBeadAdvance?()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
                        self?.isAnimating = false
                    }
                }
            default:
                break
            }
        }
    }
}
#endif
