//
//  VerticalBeadSceneManager.swift
//  beads
//
//  Created by firstfu on 2026/2/26.
//

import SceneKit

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

final class VerticalBeadSceneManager {
    let scene: SCNScene
    private var beadNodes: [SCNNode] = []
    private let beadCount: Int

    // Layout parameters
    private let beadRadius: Float = 0.3
    private let beadGap: Float = 0.15
    private var beadSpacing: Float { beadRadius * 2.0 + beadGap }

    /// Container node that holds all beads — translated along Y to simulate scrolling
    private let beadColumnNode = SCNNode()

    /// Computed spacing per bead step (used by gesture handling)
    var spacingPerBead: Float { beadSpacing }

    /// Accumulated translation from pan gesture
    var panTranslation: Float = 0

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

        // Camera — positioned to frame the vertical bead column
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 45
        cameraNode.position = SCNVector3(0, 0, 6)
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
        // Add the column container to the scene
        beadColumnNode.name = "bead_column"
        scene.rootNode.addChildNode(beadColumnNode)

        let beadGeometry = SCNSphere(radius: CGFloat(beadRadius))
        beadGeometry.segmentCount = 48

        let material = SCNMaterial()
        materialType.applyTo(material)
        beadGeometry.materials = [material]

        // Place all beads along the Y axis in a vertical column
        // Bead 0 at top (y = 0), subsequent beads going downward
        for i in 0..<beadCount {
            let y = -Float(i) * beadSpacing

            let node = SCNNode(geometry: beadGeometry.copy() as? SCNGeometry)
            node.position = SCNVector3(0, y, 0)
            node.name = "bead_\(i)"
            beadColumnNode.addChildNode(node)
            beadNodes.append(node)
        }
    }

    /// Draw a thin cylinder as the string running through all beads vertically
    private func createString() {
        let totalLength = Float(beadCount - 1) * beadSpacing + beadRadius * 2.0
        let cylinder = SCNCylinder(radius: 0.015, height: CGFloat(totalLength))

        let stringMaterial = SCNMaterial()
        #if os(macOS)
            stringMaterial.diffuse.contents = NSColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 1.0)
        #else
            stringMaterial.diffuse.contents = UIColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 1.0)
        #endif
        cylinder.materials = [stringMaterial]

        let stringNode = SCNNode(geometry: cylinder)
        // Center the cylinder so it spans from top bead to bottom bead
        let centerY = -Float(beadCount - 1) * beadSpacing / 2.0
        stringNode.position = SCNVector3(0, centerY, 0)
        stringNode.name = "string"
        // String moves with the column so it stays aligned with beads
        beadColumnNode.addChildNode(stringNode)
    }

    private func highlightCurrentBead() {
        for (i, node) in beadNodes.enumerated() {
            let scale: Float = (i == currentBeadIndex) ? 1.3 : 1.0
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
    }

    // MARK: - Column Translation (real bead sliding feel)

    /// Translate the entire bead column by a delta along Y (called during pan gesture)
    func translateColumn(by deltaY: Float) {
        panTranslation += deltaY
        beadColumnNode.position = SCNVector3(0, panTranslation, 0)
    }

    /// Snap the column to the nearest bead position and advance the count
    /// Returns the number of bead steps moved (can be 0)
    @discardableResult
    func snapToNearestBead() -> Int {
        // Calculate how many full bead steps we've moved
        let steps = Int(round(panTranslation / beadSpacing))
        let snappedY = Float(steps) * beadSpacing

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.2
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        beadColumnNode.position = SCNVector3(0, snappedY, 0)
        SCNTransaction.commit()

        panTranslation = snappedY
        return steps
    }

    /// Animate advancing by one bead: translate the column up + spin the current bead
    func animateBeadForward() {
        let targetY = panTranslation + beadSpacing
        let index = currentBeadIndex
        guard index < beadNodes.count else { return }
        let node = beadNodes[index]

        // Translate the whole column up by one bead step
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        beadColumnNode.position = SCNVector3(0, targetY, 0)

        // Roll the individual bead on its own axis
        let rollAngle = Float.pi * 2.0 // one full spin
        let currentEuler = node.eulerAngles
        node.eulerAngles = SCNVector3(currentEuler.x + rollAngle, currentEuler.y, currentEuler.z)

        SCNTransaction.commit()

        panTranslation = targetY
    }
}
