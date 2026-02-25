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

    // Layout parameters
    private let circleRadius: Float = 2.0
    private let beadRadius: Float = 0.18
    private let beadGap: Float = 0.06  // gap between beads
    private var displayCount: Int = 0

    /// Container node that holds all beads — rotated to simulate sliding
    private let beadRingNode = SCNNode()

    /// Angle per bead step (radians)
    private(set) var anglePerBead: Float = 0

    /// Accumulated rotation from pan gesture (radians)
    var panRotation: Float = 0

    var currentBeadIndex: Int = 0 {
        didSet { highlightCurrentBead() }
    }

    var materialType: BeadMaterialType = .zitan {
        didSet { applyMaterial() }
    }

    init(beadCount: Int = 108) {
        self.beadCount = min(beadCount, 108)
        self.scene = SCNScene()

        // Calculate how many beads fit in the circle without overlapping
        let circumference = 2.0 * Float.pi * circleRadius
        let beadDiameter = beadRadius * 2.0
        let spacePerBead = beadDiameter + beadGap
        self.displayCount = min(Int(circumference / spacePerBead), beadCount)
        self.anglePerBead = (Float.pi * 2.0) / Float(displayCount)

        setupScene()
    }

    private func setupScene() {
        #if os(macOS)
            scene.background.contents = NSColor.black
        #else
            scene.background.contents = UIColor.black
        #endif

        // Camera — positioned to frame the bead circle nicely
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 55
        cameraNode.position = SCNVector3(0, 0, 8.5)
        cameraNode.name = "camera"
        scene.rootNode.addChildNode(cameraNode)

        // Ambient light — soft overall illumination
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 400
        #if os(macOS)
            ambientLight.light?.color = NSColor(white: 0.9, alpha: 1.0)
        #else
            ambientLight.light?.color = UIColor(white: 0.9, alpha: 1.0)
        #endif
        scene.rootNode.addChildNode(ambientLight)

        // Key light — main directional light with shadows
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 800
        keyLight.light?.castsShadow = true
        keyLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
        scene.rootNode.addChildNode(keyLight)

        // Fill light — soften shadows
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.intensity = 300
        fillLight.eulerAngles = SCNVector3(-Float.pi / 6, -Float.pi / 3, 0)
        scene.rootNode.addChildNode(fillLight)

        createBeads()
        createString()
    }

    private func createBeads() {
        // Add the ring container to the scene
        beadRingNode.name = "bead_ring"
        scene.rootNode.addChildNode(beadRingNode)

        let beadGeometry = SCNSphere(radius: CGFloat(beadRadius))
        beadGeometry.segmentCount = 48

        let material = SCNMaterial()
        materialType.applyTo(material)
        beadGeometry.materials = [material]

        // Place beads evenly around the circle inside the ring container
        for i in 0..<displayCount {
            let angle = Float(i) / Float(displayCount) * Float.pi * 2 + Float.pi / 2
            let x = circleRadius * cos(angle)
            let y = circleRadius * sin(angle)

            let node = SCNNode(geometry: beadGeometry.copy() as? SCNGeometry)
            node.position = SCNVector3(x, y, 0)
            node.name = "bead_\(i)"
            beadRingNode.addChildNode(node)
            beadNodes.append(node)
        }

        // Guru bead — larger, at the top (starting position)
        let guruGeometry = SCNSphere(radius: CGFloat(beadRadius * 1.5))
        guruGeometry.segmentCount = 48
        let guruMaterial = SCNMaterial()
        materialType.applyTo(guruMaterial)
        guruGeometry.materials = [guruMaterial]

        let guruNode = SCNNode(geometry: guruGeometry)
        guruNode.position = SCNVector3(0, circleRadius, 0)
        guruNode.name = "guru_bead"
        beadRingNode.addChildNode(guruNode)
    }

    /// Draw a thin torus as the string connecting the beads
    private func createString() {
        let torus = SCNTorus(ringRadius: CGFloat(circleRadius), pipeRadius: 0.015)
        let stringMaterial = SCNMaterial()
        #if os(macOS)
            stringMaterial.diffuse.contents = NSColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 1.0)
        #else
            stringMaterial.diffuse.contents = UIColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 1.0)
        #endif
        torus.materials = [stringMaterial]

        let stringNode = SCNNode(geometry: torus)
        stringNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        stringNode.name = "string"
        // String stays in scene root (doesn't rotate with beads)
        scene.rootNode.addChildNode(stringNode)
    }

    private func highlightCurrentBead() {
        let displayIndex = currentBeadIndex % displayCount

        for (i, node) in beadNodes.enumerated() {
            let scale: Float = (i == displayIndex) ? 1.3 : 1.0
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.15
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
        if let guru = beadRingNode.childNode(withName: "guru_bead", recursively: false),
           let material = guru.geometry?.materials.first
        {
            materialType.applyTo(material)
        }
    }

    // MARK: - Ring Rotation (real bead sliding feel)

    /// Rotate the entire bead ring by a delta angle (called during pan gesture)
    func rotateRing(by deltaAngle: Float) {
        panRotation += deltaAngle
        beadRingNode.eulerAngles = SCNVector3(0, 0, panRotation)
    }

    /// Snap the ring to the nearest bead position and advance the count
    /// Returns the number of bead steps moved (can be 0)
    @discardableResult
    func snapToNearestBead() -> Int {
        // Calculate how many full bead steps we've moved
        let steps = Int(round(panRotation / anglePerBead))
        let snappedAngle = Float(steps) * anglePerBead

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.2
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        beadRingNode.eulerAngles = SCNVector3(0, 0, snappedAngle)
        SCNTransaction.commit()

        panRotation = snappedAngle
        return steps
    }

    /// Animate advancing by one bead: rotate the ring + spin the current bead
    func animateBeadForward() {
        let targetAngle = panRotation - anglePerBead
        let index = currentBeadIndex % displayCount
        guard index < beadNodes.count else { return }
        let node = beadNodes[index]

        // Rotate the whole ring by one bead step
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        beadRingNode.eulerAngles = SCNVector3(0, 0, targetAngle)

        // Roll the individual bead on its own axis (tangent direction)
        let rollAngle = Float.pi * 2.0 // one full spin
        let currentEuler = node.eulerAngles
        node.eulerAngles = SCNVector3(currentEuler.x + rollAngle, currentEuler.y, currentEuler.z)

        SCNTransaction.commit()

        panRotation = targetAngle
    }
}
