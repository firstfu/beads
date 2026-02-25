//
//  BeadSceneManager.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SceneKit

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

final class BeadSceneManager {
    let scene: SCNScene
    private var beadNodes: [SCNNode] = []
    private let beadCount: Int
    private let radius: Float = 2.2
    private let beadRadius: Float = 0.2

    var currentBeadIndex: Int = 0 {
        didSet { highlightCurrentBead() }
    }

    var materialType: BeadMaterialType = .zitan {
        didSet { applyMaterial() }
    }

    init(beadCount: Int = 108) {
        self.beadCount = min(beadCount, 108)
        self.scene = SCNScene()
        setupScene()
    }

    private func setupScene() {
        #if os(macOS)
            scene.background.contents = NSColor.black
        #else
            scene.background.contents = UIColor.black
        #endif

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 50
        cameraNode.position = SCNVector3(0, 0, 7)
        cameraNode.name = "camera"
        scene.rootNode.addChildNode(cameraNode)

        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 300
        #if os(macOS)
            ambientLight.light?.color = NSColor(white: 0.8, alpha: 1.0)
        #else
            ambientLight.light?.color = UIColor(white: 0.8, alpha: 1.0)
        #endif
        scene.rootNode.addChildNode(ambientLight)

        // Key light
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 800
        keyLight.light?.castsShadow = true
        keyLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
        scene.rootNode.addChildNode(keyLight)

        // Fill light
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.intensity = 400
        fillLight.eulerAngles = SCNVector3(-Float.pi / 6, -Float.pi / 3, 0)
        scene.rootNode.addChildNode(fillLight)

        createBeads()
    }

    private func createBeads() {
        let displayCount = min(beadCount, 54)
        let beadGeometry = SCNSphere(radius: CGFloat(beadRadius))
        beadGeometry.segmentCount = 48

        let material = SCNMaterial()
        materialType.applyTo(material)
        beadGeometry.materials = [material]

        for i in 0..<displayCount {
            let angle = Float(i) / Float(displayCount) * Float.pi * 2 - Float.pi / 2
            let x = radius * cos(angle)
            let y = radius * sin(angle)

            let node = SCNNode(geometry: beadGeometry.copy() as? SCNGeometry)
            node.position = SCNVector3(x, y, 0)
            node.name = "bead_\(i)"
            scene.rootNode.addChildNode(node)
            beadNodes.append(node)
        }

        // Guru bead (larger, at top)
        let guruGeometry = SCNSphere(radius: CGFloat(beadRadius * 1.4))
        guruGeometry.segmentCount = 48
        let guruMaterial = SCNMaterial()
        materialType.applyTo(guruMaterial)
        guruGeometry.materials = [guruMaterial]

        let guruNode = SCNNode(geometry: guruGeometry)
        guruNode.position = SCNVector3(0, -radius, 0)
        guruNode.name = "guru_bead"
        scene.rootNode.addChildNode(guruNode)
    }

    private func highlightCurrentBead() {
        let displayCount = min(beadCount, 54)
        let displayIndex = currentBeadIndex % displayCount

        for (i, node) in beadNodes.enumerated() {
            let scale: Float = (i == displayIndex) ? 1.3 : 1.0
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.2
            node.scale = SCNVector3(scale, scale, scale)
            SCNTransaction.commit()
        }
    }

    private func applyMaterial() {
        for node in beadNodes {
            if let geometry = node.geometry, let material = geometry.materials.first {
                materialType.applyTo(material)
            }
        }
        if let guru = scene.rootNode.childNode(withName: "guru_bead", recursively: false),
           let material = guru.geometry?.materials.first
        {
            materialType.applyTo(material)
        }
    }

    func animateBeadForward() {
        let displayCount = min(beadCount, 54)
        let index = currentBeadIndex % displayCount
        guard index < beadNodes.count else { return }
        let node = beadNodes[index]

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        node.scale = SCNVector3(1.5, 1.5, 1.5)
        SCNTransaction.completionBlock = {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.15
            node.scale = SCNVector3(1.0, 1.0, 1.0)
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
    }
}
