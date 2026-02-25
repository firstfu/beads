//
//  BeadSceneView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SceneKit
import SwiftUI

#if os(macOS)

    struct BeadSceneView: NSViewRepresentable {
        let sceneManager: BeadSceneManager
        var onBeadAdvance: (() -> Void)?
        var fastScrollMode: Bool = false

        func makeNSView(context: Context) -> SCNView {
            let scnView = SCNView()
            scnView.scene = sceneManager.scene
            scnView.allowsCameraControl = false
            scnView.autoenablesDefaultLighting = false
            scnView.antialiasingMode = .multisampling4X
            scnView.backgroundColor = .black
            return scnView
        }

        func updateNSView(_ nsView: SCNView, context: Context) {
            context.coordinator.onBeadAdvance = onBeadAdvance
            context.coordinator.fastScrollMode = fastScrollMode
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(sceneManager: sceneManager, onBeadAdvance: onBeadAdvance, fastScrollMode: fastScrollMode)
        }

        class Coordinator: NSObject {
            let sceneManager: BeadSceneManager
            var onBeadAdvance: (() -> Void)?
            var fastScrollMode: Bool

            init(sceneManager: BeadSceneManager, onBeadAdvance: (() -> Void)?, fastScrollMode: Bool) {
                self.sceneManager = sceneManager
                self.onBeadAdvance = onBeadAdvance
                self.fastScrollMode = fastScrollMode
            }
        }
    }

#else

    struct BeadSceneView: UIViewRepresentable {
        let sceneManager: BeadSceneManager
        var onBeadAdvance: (() -> Void)?
        var fastScrollMode: Bool = false

        func makeUIView(context: Context) -> SCNView {
            let scnView = SCNView()
            scnView.scene = sceneManager.scene
            scnView.allowsCameraControl = false
            scnView.autoenablesDefaultLighting = false
            scnView.antialiasingMode = .multisampling4X
            scnView.backgroundColor = .black

            // Pan gesture for natural bead sliding
            let pan = UIPanGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePan(_:))
            )
            scnView.addGestureRecognizer(pan)

            // Also support tap for quick single bead advance
            let tap = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap(_:))
            )
            scnView.addGestureRecognizer(tap)

            return scnView
        }

        func updateUIView(_ uiView: SCNView, context: Context) {
            context.coordinator.onBeadAdvance = onBeadAdvance
            context.coordinator.fastScrollMode = fastScrollMode
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(sceneManager: sceneManager, onBeadAdvance: onBeadAdvance, fastScrollMode: fastScrollMode)
        }

        class Coordinator: NSObject {
            let sceneManager: BeadSceneManager
            var onBeadAdvance: (() -> Void)?
            var fastScrollMode: Bool

            /// Track cumulative bead steps during a single pan gesture (continuous mode)
            private var lastPanAngle: Float = 0
            private var accumulatedSteps: Int = 0

            /// Flick mode state
            private var hasAdvancedThisGesture: Bool = false
            private var isAnimating: Bool = false
            private let flickThreshold: CGFloat = 30.0

            init(sceneManager: BeadSceneManager, onBeadAdvance: (() -> Void)?, fastScrollMode: Bool) {
                self.sceneManager = sceneManager
                self.onBeadAdvance = onBeadAdvance
                self.fastScrollMode = fastScrollMode
            }

            @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
                if fastScrollMode {
                    handleContinuousPan(gesture)
                } else {
                    handleFlickPan(gesture)
                }
            }

            /// Continuous mode: original behavior — sliding across multiple beads
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

            /// Flick mode: one bead per gesture — finger must lift before next advance
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

                        // Cooldown slightly longer than animation duration (0.25s)
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
