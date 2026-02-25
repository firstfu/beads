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
            let sceneManager: BeadSceneManager
            var onBeadAdvance: (() -> Void)?

            init(sceneManager: BeadSceneManager, onBeadAdvance: (() -> Void)?) {
                self.sceneManager = sceneManager
                self.onBeadAdvance = onBeadAdvance
            }
        }
    }

#else

    struct BeadSceneView: UIViewRepresentable {
        let sceneManager: BeadSceneManager
        var onBeadAdvance: (() -> Void)?

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
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(sceneManager: sceneManager, onBeadAdvance: onBeadAdvance)
        }

        class Coordinator: NSObject {
            let sceneManager: BeadSceneManager
            var onBeadAdvance: (() -> Void)?

            /// Track cumulative bead steps during a single pan gesture
            private var lastPanAngle: Float = 0
            private var accumulatedSteps: Int = 0

            init(sceneManager: BeadSceneManager, onBeadAdvance: (() -> Void)?) {
                self.sceneManager = sceneManager
                self.onBeadAdvance = onBeadAdvance
            }

            @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
                guard let view = gesture.view else { return }
                let translation = gesture.translation(in: view)
                let viewHeight = view.bounds.height

                // Convert vertical pan distance to rotation angle
                // Swipe up = positive rotation (beads move forward)
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

                    // Check if we've crossed a bead boundary
                    let totalSteps = Int(round(panAngle / sceneManager.anglePerBead))
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
