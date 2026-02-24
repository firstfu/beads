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
        var onSwipeUp: (() -> Void)?

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
            context.coordinator.onSwipeUp = onSwipeUp
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(onSwipeUp: onSwipeUp)
        }

        class Coordinator: NSObject {
            var onSwipeUp: (() -> Void)?

            init(onSwipeUp: (() -> Void)?) {
                self.onSwipeUp = onSwipeUp
            }
        }
    }

#else

    struct BeadSceneView: UIViewRepresentable {
        let sceneManager: BeadSceneManager
        var onSwipeUp: (() -> Void)?

        func makeUIView(context: Context) -> SCNView {
            let scnView = SCNView()
            scnView.scene = sceneManager.scene
            scnView.allowsCameraControl = false
            scnView.autoenablesDefaultLighting = false
            scnView.antialiasingMode = .multisampling4X
            scnView.backgroundColor = .black

            let swipeUp = UISwipeGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleSwipe(_:))
            )
            swipeUp.direction = .up
            scnView.addGestureRecognizer(swipeUp)

            let swipeLeft = UISwipeGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleSwipe(_:))
            )
            swipeLeft.direction = .left
            scnView.addGestureRecognizer(swipeLeft)

            return scnView
        }

        func updateUIView(_ uiView: SCNView, context: Context) {
            context.coordinator.onSwipeUp = onSwipeUp
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(onSwipeUp: onSwipeUp)
        }

        class Coordinator: NSObject {
            var onSwipeUp: (() -> Void)?

            init(onSwipeUp: (() -> Void)?) {
                self.onSwipeUp = onSwipeUp
            }

            @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
                onSwipeUp?()
            }
        }
    }

#endif
