//
//  VerticalBeadSceneView.swift
//  beads
//
//  Created by firstfu on 2026/2/26.
//

import SceneKit
import SwiftUI

#if os(macOS)

    struct VerticalBeadSceneView: NSViewRepresentable {
        let sceneManager: VerticalBeadSceneManager
        var onBeadAdvance: (() -> Void)?

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
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(sceneManager: sceneManager, onBeadAdvance: onBeadAdvance)
        }

        class Coordinator: NSObject {
            let sceneManager: VerticalBeadSceneManager
            var onBeadAdvance: (() -> Void)?

            init(sceneManager: VerticalBeadSceneManager, onBeadAdvance: (() -> Void)?) {
                self.sceneManager = sceneManager
                self.onBeadAdvance = onBeadAdvance
            }
        }
    }

#else

    struct VerticalBeadSceneView: UIViewRepresentable {
        let sceneManager: VerticalBeadSceneManager
        var onBeadAdvance: (() -> Void)?

        func makeUIView(context: Context) -> SCNView {
            let scnView = SCNView()
            scnView.scene = sceneManager.scene
            scnView.allowsCameraControl = false
            scnView.autoenablesDefaultLighting = false
            scnView.antialiasingMode = .multisampling4X
            scnView.backgroundColor = .black

            // Pan gesture for natural vertical bead sliding
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
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(sceneManager: sceneManager, onBeadAdvance: onBeadAdvance)
        }

        class Coordinator: NSObject {
            let sceneManager: VerticalBeadSceneManager
            var onBeadAdvance: (() -> Void)?

            /// Track cumulative bead steps during a single pan gesture
            private var lastPanDistance: Float = 0
            private var accumulatedSteps: Int = 0

            /// Sensitivity multiplier for pan-to-translation mapping
            private let sensitivity: Float = 4.0

            init(sceneManager: VerticalBeadSceneManager, onBeadAdvance: (() -> Void)?) {
                self.sceneManager = sceneManager
                self.onBeadAdvance = onBeadAdvance
            }

            @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
                guard let view = gesture.view else { return }
                let translation = gesture.translation(in: view)
                let viewHeight = view.bounds.height

                // Convert vertical pan distance to column translation
                // Swipe up (negative translation.y) = advance beads (positive deltaY on container)
                let panDistance = Float(-translation.y / viewHeight) * sensitivity

                switch gesture.state {
                case .began:
                    lastPanDistance = 0
                    accumulatedSteps = 0

                case .changed:
                    let delta = panDistance - lastPanDistance
                    lastPanDistance = panDistance
                    sceneManager.translateColumn(by: delta)

                    // Check if we've crossed a bead boundary
                    let totalSteps = Int(round(panDistance / sceneManager.spacingPerBead))
                    let newSteps = totalSteps - accumulatedSteps
                    if newSteps > 0 {
                        for _ in 0..<newSteps {
                            onBeadAdvance?()
                        }
                        accumulatedSteps = totalSteps
                    }

                case .ended, .cancelled:
                    // Snap to nearest bead position
                    sceneManager.snapToNearestBead()

                default:
                    break
                }
            }

            @objc func handleTap(_ gesture: UITapGestureRecognizer) {
                guard gesture.state == .ended else { return }
                sceneManager.animateBeadForward()
                onBeadAdvance?()
            }
        }
    }

#endif
