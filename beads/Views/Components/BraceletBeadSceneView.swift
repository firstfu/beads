// MARK: - 檔案說明
/// BraceletBeadSceneView.swift
/// 手串佛珠 3D 場景視圖 - 將 SceneKit 手串場景橋接至 SwiftUI，處理手勢互動
/// 模組：Views/Components

//
//  BraceletBeadSceneView.swift
//  beads
//
//  Created by firstfu on 2026/2/27.
//

import SceneKit
import SwiftUI

#if os(macOS)

    /// 手串佛珠場景視圖（macOS 版本）
    /// 使用 NSViewRepresentable 將 SCNView 橋接至 SwiftUI
    struct BraceletBeadSceneView: NSViewRepresentable {
        /// 手串佛珠場景管理器，提供 3D 場景資料
        let sceneManager: BraceletBeadSceneManager
        /// 佛珠推進時的回呼閉包
        var onBeadAdvance: (() -> Void)?
        /// 是否啟用快速捲動模式（連續滑動多顆佛珠）
        var fastScrollMode: Bool = false

        /// 建立 macOS 原生 SCNView
        func makeNSView(context: Context) -> SCNView {
            let scnView = SCNView()
            scnView.scene = sceneManager.scene
            scnView.allowsCameraControl = false
            scnView.autoenablesDefaultLighting = false
            scnView.antialiasingMode = .multisampling2X
            scnView.backgroundColor = .clear
            return scnView
        }

        /// 更新 macOS 原生 SCNView 的狀態
        func updateNSView(_ nsView: SCNView, context: Context) {
            context.coordinator.onBeadAdvance = onBeadAdvance
            context.coordinator.fastScrollMode = fastScrollMode
        }

        /// 建立協調器
        func makeCoordinator() -> Coordinator {
            Coordinator(sceneManager: sceneManager, onBeadAdvance: onBeadAdvance, fastScrollMode: fastScrollMode)
        }

        /// 協調器（macOS 版本）
        class Coordinator: NSObject {
            let sceneManager: BraceletBeadSceneManager
            var onBeadAdvance: (() -> Void)?
            var fastScrollMode: Bool

            init(sceneManager: BraceletBeadSceneManager, onBeadAdvance: (() -> Void)?, fastScrollMode: Bool) {
                self.sceneManager = sceneManager
                self.onBeadAdvance = onBeadAdvance
                self.fastScrollMode = fastScrollMode
            }
        }
    }

#else

    /// 手串佛珠場景視圖（iOS 版本）
    /// 使用 UIViewRepresentable 將 SCNView 橋接至 SwiftUI，
    /// 支援拖曳手勢（滑動佛珠）及點擊手勢（推進一顆佛珠）
    struct BraceletBeadSceneView: UIViewRepresentable {
        /// 手串佛珠場景管理器，提供 3D 場景資料
        let sceneManager: BraceletBeadSceneManager
        /// 佛珠推進時的回呼閉包
        var onBeadAdvance: (() -> Void)?
        /// 是否啟用快速捲動模式（連續滑動多顆佛珠）
        var fastScrollMode: Bool = false

        /// 建立 iOS 原生 SCNView，並設定拖曳與點擊手勢
        func makeUIView(context: Context) -> SCNView {
            let scnView = SCNView()
            scnView.scene = sceneManager.scene
            scnView.allowsCameraControl = false
            scnView.autoenablesDefaultLighting = false
            scnView.antialiasingMode = .multisampling2X
            scnView.backgroundColor = .clear

            // 拖曳手勢 — 自然的佛珠滑動操作
            let pan = UIPanGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePan(_:))
            )
            scnView.addGestureRecognizer(pan)

            // 點擊手勢 — 快速推進單顆佛珠
            let tap = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap(_:))
            )
            scnView.addGestureRecognizer(tap)

            return scnView
        }

        /// 更新 iOS 原生 SCNView 的狀態
        func updateUIView(_ uiView: SCNView, context: Context) {
            context.coordinator.onBeadAdvance = onBeadAdvance
            context.coordinator.fastScrollMode = fastScrollMode
        }

        /// 建立協調器
        func makeCoordinator() -> Coordinator {
            Coordinator(sceneManager: sceneManager, onBeadAdvance: onBeadAdvance, fastScrollMode: fastScrollMode)
        }

        /// 協調器（iOS 版本）
        /// 處理拖曳和點擊手勢，驅動手串佛珠場景的旋轉與推進動畫
        class Coordinator: NSObject {
            let sceneManager: BraceletBeadSceneManager
            var onBeadAdvance: (() -> Void)?
            var fastScrollMode: Bool

            /// 連續模式下追蹤單次拖曳手勢中的累計步數
            private var lastPanAngle: Float = 0
            /// 連續模式下已累計的佛珠步數
            private var accumulatedSteps: Int = 0

            /// 輕撥模式狀態：本次手勢是否已推進佛珠
            private var hasAdvancedThisGesture: Bool = false
            /// 輕撥模式狀態：是否正在播放動畫
            private var isAnimating: Bool = false
            /// 輕撥模式觸發門檻（像素）
            private let flickThreshold: CGFloat = 30.0

            init(sceneManager: BraceletBeadSceneManager, onBeadAdvance: (() -> Void)?, fastScrollMode: Bool) {
                self.sceneManager = sceneManager
                self.onBeadAdvance = onBeadAdvance
                self.fastScrollMode = fastScrollMode
            }

            /// 處理拖曳手勢
            @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
                if fastScrollMode {
                    handleContinuousPan(gesture)
                } else {
                    handleFlickPan(gesture)
                }
            }

            /// 連續模式處理拖曳手勢
            private func handleContinuousPan(_ gesture: UIPanGestureRecognizer) {
                guard let view = gesture.view else { return }
                let translation = gesture.translation(in: view)
                let viewHeight = view.bounds.height

                let sensitivity: Float = 3.0
                let panAngle = Float(-translation.y / viewHeight) * Float.pi * sensitivity

                switch gesture.state {
                case .began:
                    lastPanAngle = 0
                    accumulatedSteps = 0

                case .changed:
                    let delta = panAngle - lastPanAngle
                    lastPanAngle = panAngle
                    sceneManager.rotateRing(by: delta)

                    let totalSteps = Int(round(panAngle / sceneManager.anglePerBead))
                    let newSteps = totalSteps - accumulatedSteps
                    if newSteps > 0 {
                        for _ in 0..<newSteps {
                            onBeadAdvance?()
                        }
                        accumulatedSteps = totalSteps
                    }

                case .ended, .cancelled:
                    sceneManager.snapToNearestBead()

                default:
                    break
                }
            }

            /// 輕撥模式處理拖曳手勢
            private func handleFlickPan(_ gesture: UIPanGestureRecognizer) {
                guard let view = gesture.view else { return }
                let translation = gesture.translation(in: view)

                switch gesture.state {
                case .began:
                    hasAdvancedThisGesture = false

                case .changed:
                    if !hasAdvancedThisGesture && !isAnimating {
                        if -translation.y >= flickThreshold {
                            // 往上撥 → 佛珠往上（前進），觸發計數
                            hasAdvancedThisGesture = true
                            isAnimating = true
                            sceneManager.animateBeadForward()
                            onBeadAdvance?()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
                                self?.isAnimating = false
                            }
                        } else if translation.y >= flickThreshold {
                            // 往下撥 → 佛珠往下（退回），僅視覺移動不計數
                            hasAdvancedThisGesture = true
                            isAnimating = true
                            sceneManager.animateBeadBackward()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
                                self?.isAnimating = false
                            }
                        }
                    }

                case .ended, .cancelled:
                    break

                default:
                    break
                }
            }

            /// 處理點擊手勢
            @objc func handleTap(_ gesture: UITapGestureRecognizer) {
                guard gesture.state == .ended else { return }
                guard !isAnimating else { return }
                isAnimating = true
                sceneManager.animateBeadForward()
                onBeadAdvance?()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
                    self?.isAnimating = false
                }
            }
        }
    }

#endif
