// MARK: - 檔案說明
/// VerticalBeadSceneView.swift
/// 垂直佛珠 3D 場景視圖 - 將 SceneKit 垂直佛珠場景橋接至 SwiftUI，處理手勢互動
/// 模組：Views/Components

//
//  VerticalBeadSceneView.swift
//  beads
//
//  Created by firstfu on 2026/2/26.
//

import SceneKit
import SwiftUI

#if os(macOS)

    /// 垂直佛珠場景視圖（macOS 版本）
    /// 使用 NSViewRepresentable 將 SCNView 橋接至 SwiftUI
    struct VerticalBeadSceneView: NSViewRepresentable {
        /// 垂直佛珠場景管理器，提供 3D 場景資料
        let sceneManager: VerticalBeadSceneManager
        /// 佛珠推進時的回呼閉包
        var onBeadAdvance: (() -> Void)?
        /// 是否啟用快速捲動模式（連續滑動多顆佛珠）
        var fastScrollMode: Bool = false

        /// 建立 macOS 原生 SCNView
        /// - Parameter context: 視圖上下文
        /// - Returns: 設定好的 SCNView 實例
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
        /// - Parameters:
        ///   - nsView: 要更新的 SCNView
        ///   - context: 視圖上下文
        func updateNSView(_ nsView: SCNView, context: Context) {
            context.coordinator.onBeadAdvance = onBeadAdvance
            context.coordinator.fastScrollMode = fastScrollMode
        }

        /// 建立協調器，用於管理手勢與場景互動
        /// - Returns: Coordinator 實例
        func makeCoordinator() -> Coordinator {
            Coordinator(sceneManager: sceneManager, onBeadAdvance: onBeadAdvance, fastScrollMode: fastScrollMode)
        }

        /// 協調器（macOS 版本）
        /// 管理場景管理器的參考與回呼設定
        class Coordinator: NSObject {
            /// 垂直佛珠場景管理器
            let sceneManager: VerticalBeadSceneManager
            /// 佛珠推進時的回呼閉包
            var onBeadAdvance: (() -> Void)?
            /// 是否啟用快速捲動模式
            var fastScrollMode: Bool

            /// 初始化協調器
            /// - Parameters:
            ///   - sceneManager: 垂直佛珠場景管理器
            ///   - onBeadAdvance: 佛珠推進回呼
            ///   - fastScrollMode: 快速捲動模式開關
            init(sceneManager: VerticalBeadSceneManager, onBeadAdvance: (() -> Void)?, fastScrollMode: Bool) {
                self.sceneManager = sceneManager
                self.onBeadAdvance = onBeadAdvance
                self.fastScrollMode = fastScrollMode
            }
        }
    }

#else

    /// 垂直佛珠場景視圖（iOS 版本）
    /// 使用 UIViewRepresentable 將 SCNView 橋接至 SwiftUI，
    /// 支援拖曳手勢（上下滑動佛珠）及點擊手勢（推進一顆佛珠）
    struct VerticalBeadSceneView: UIViewRepresentable {
        /// 垂直佛珠場景管理器，提供 3D 場景資料
        let sceneManager: VerticalBeadSceneManager
        /// 佛珠推進時的回呼閉包
        var onBeadAdvance: (() -> Void)?
        /// 是否啟用快速捲動模式（連續滑動多顆佛珠）
        var fastScrollMode: Bool = false

        /// 建立 iOS 原生 SCNView，並設定拖曳與點擊手勢
        /// - Parameter context: 視圖上下文
        /// - Returns: 設定好的 SCNView 實例
        func makeUIView(context: Context) -> SCNView {
            let scnView = SCNView()
            scnView.scene = sceneManager.scene
            scnView.allowsCameraControl = false
            scnView.autoenablesDefaultLighting = false
            scnView.antialiasingMode = .multisampling2X
            scnView.backgroundColor = .clear

            // 拖曳手勢 — 自然的垂直佛珠滑動操作
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
        /// - Parameters:
        ///   - uiView: 要更新的 SCNView
        ///   - context: 視圖上下文
        func updateUIView(_ uiView: SCNView, context: Context) {
            context.coordinator.onBeadAdvance = onBeadAdvance
            context.coordinator.fastScrollMode = fastScrollMode
        }

        /// 建立協調器，用於管理手勢與場景互動
        /// - Returns: Coordinator 實例
        func makeCoordinator() -> Coordinator {
            Coordinator(sceneManager: sceneManager, onBeadAdvance: onBeadAdvance, fastScrollMode: fastScrollMode)
        }

        /// 協調器（iOS 版本）
        /// 處理拖曳和點擊手勢，驅動垂直佛珠場景的平移與推進動畫
        class Coordinator: NSObject {
            /// 垂直佛珠場景管理器
            let sceneManager: VerticalBeadSceneManager
            /// 佛珠推進時的回呼閉包
            var onBeadAdvance: (() -> Void)?
            /// 是否啟用快速捲動模式
            var fastScrollMode: Bool

            /// 連續模式下追蹤單次拖曳手勢中的累計距離
            private var lastPanDistance: Float = 0
            /// 連續模式下已累計的佛珠步數
            private var accumulatedSteps: Int = 0

            /// 拖曳至平移的靈敏度倍率
            private let sensitivity: Float = 4.0

            /// 輕撥模式狀態：本次手勢是否已推進佛珠
            private var hasAdvancedThisGesture: Bool = false
            /// 輕撥模式狀態：是否正在播放動畫
            private var isAnimating: Bool = false
            /// 輕撥模式觸發門檻（像素）
            private let flickThreshold: CGFloat = 30.0

            /// 初始化協調器
            /// - Parameters:
            ///   - sceneManager: 垂直佛珠場景管理器
            ///   - onBeadAdvance: 佛珠推進回呼
            ///   - fastScrollMode: 快速捲動模式開關
            init(sceneManager: VerticalBeadSceneManager, onBeadAdvance: (() -> Void)?, fastScrollMode: Bool) {
                self.sceneManager = sceneManager
                self.onBeadAdvance = onBeadAdvance
                self.fastScrollMode = fastScrollMode
            }

            /// 處理拖曳手勢
            /// 根據快速捲動模式切換連續滑動或輕撥模式
            /// - Parameter gesture: 拖曳手勢辨識器
            @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
                if fastScrollMode {
                    handleContinuousPan(gesture)
                } else {
                    handleFlickPan(gesture)
                }
            }

            /// 連續模式處理拖曳手勢
            /// 手指滑動時持續平移佛珠列，可一次滑過多顆佛珠
            /// - Parameter gesture: 拖曳手勢辨識器
            private func handleContinuousPan(_ gesture: UIPanGestureRecognizer) {
                guard let view = gesture.view else { return }
                let translation = gesture.translation(in: view)
                let viewHeight = view.bounds.height

                let panDistance = Float(-translation.y / viewHeight) * sensitivity

                switch gesture.state {
                case .began:
                    lastPanDistance = 0
                    accumulatedSteps = 0

                case .changed:
                    let delta = panDistance - lastPanDistance
                    lastPanDistance = panDistance
                    sceneManager.translateColumn(by: delta)

                    let totalSteps = Int(round(panDistance / sceneManager.spacingPerBead))
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
            /// 每次手勢僅推進一顆佛珠，手指必須抬起後才能進行下一次推進
            /// - Parameter gesture: 拖曳手勢辨識器
            private func handleFlickPan(_ gesture: UIPanGestureRecognizer) {
                guard let view = gesture.view else { return }
                let translation = gesture.translation(in: view)

                switch gesture.state {
                case .began:
                    hasAdvancedThisGesture = false

                case .changed:
                    let distance = abs(translation.y)
                    if distance >= flickThreshold && !hasAdvancedThisGesture && !isAnimating {
                        hasAdvancedThisGesture = true
                        isAnimating = true
                        sceneManager.animateBeadForward()
                        onBeadAdvance?()

                        // 冷卻時間略長於動畫時長（0.25 秒）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
                            self?.isAnimating = false
                        }
                    }

                case .ended, .cancelled:
                    break

                default:
                    break
                }
            }

            /// 處理點擊手勢
            /// 點擊時推進一顆佛珠並播放動畫，動畫期間不接受重複點擊
            /// - Parameter gesture: 點擊手勢辨識器
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
