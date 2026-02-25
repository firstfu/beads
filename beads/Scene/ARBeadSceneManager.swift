// MARK: - 檔案說明
/// ARBeadSceneManager.swift
/// AR 佛珠場景管理器 - 使用 RealityKit 管理 AR 環境中的佛珠 Entity
/// 模組：Scene

//
//  ARBeadSceneManager.swift
//  beads
//
//  Created on 2026/2/26.
//

import Foundation
import Observation

#if os(iOS)
import RealityKit
import ARKit

/// AR 佛珠場景管理器
/// 負責在 RealityKit Entity 層級建立環形佛珠、管理材質切換與佛珠高亮
@Observable
@MainActor
final class ARBeadSceneManager {
    /// 所有佛珠 Entity 的陣列
    private var beadEntities: [ModelEntity] = []
    /// 佛珠總數（上限 108）
    private let beadCount: Int

    // MARK: - 排列參數（公尺，AR 真實尺度）

    /// 圓環半徑
    private let circleRadius: Float = 0.12
    /// 單顆佛珠半徑
    private let beadRadius: Float = 0.006
    /// 佛珠之間的間隙
    private let beadGap: Float = 0.002
    /// 實際顯示在圓環上的佛珠數量
    private(set) var displayCount: Int = 0

    /// 佛珠環容器 Entity
    let beadRingEntity = Entity()

    /// 每顆佛珠對應的角度步幅（弧度）
    private(set) var anglePerBead: Float = 0

    /// 目前高亮的佛珠索引
    var currentBeadIndex: Int = 0 {
        didSet { highlightCurrentBead() }
    }

    /// 目前佛珠材質類型
    var materialType: BeadMaterialType = .zitan {
        didSet { applyMaterial() }
    }

    /// 初始化 AR 佛珠場景管理器
    /// - Parameter beadCount: 佛珠總數，預設 108，上限 108
    init(beadCount: Int = 108) {
        self.beadCount = min(beadCount, 108)

        let circumference = 2.0 * Float.pi * circleRadius
        let beadDiameter = beadRadius * 2.0
        let spacePerBead = beadDiameter + beadGap
        self.displayCount = min(Int(circumference / spacePerBead), self.beadCount)
        self.anglePerBead = (Float.pi * 2.0) / Float(displayCount)

        createBeads()
    }

    /// 建立 AR 環形佛珠排列
    private func createBeads() {
        beadRingEntity.name = "ar_bead_ring"

        let beadMesh = MeshResource.generateSphere(radius: beadRadius)
        let material = materialType.createRealityKitMaterial()

        for i in 0..<displayCount {
            let angle = Float(i) / Float(displayCount) * Float.pi * 2 + Float.pi / 2
            let x = circleRadius * cos(angle)
            let z = circleRadius * sin(angle)

            let entity = ModelEntity(mesh: beadMesh, materials: [material])
            entity.position = SIMD3<Float>(x, 0, z)
            entity.name = "bead_\(i)"
            beadRingEntity.addChild(entity)
            beadEntities.append(entity)
        }

        // 母珠 — 較大顆
        let guruMesh = MeshResource.generateSphere(radius: beadRadius * 1.5)
        let guruEntity = ModelEntity(mesh: guruMesh, materials: [material])
        guruEntity.position = SIMD3<Float>(0, 0, circleRadius)
        guruEntity.name = "guru_bead"
        beadRingEntity.addChild(guruEntity)

        // 佛珠環整體向上抬高
        beadRingEntity.position = SIMD3<Float>(0, beadRadius + 0.005, 0)
    }

    /// 高亮顯示目前佛珠（放大至 1.3 倍）
    private func highlightCurrentBead() {
        let displayIndex = currentBeadIndex % displayCount
        for (i, entity) in beadEntities.enumerated() {
            let scale: Float = (i == displayIndex) ? 1.3 : 1.0
            entity.scale = SIMD3<Float>(repeating: scale)
        }
    }

    /// 套用材質至所有佛珠
    private func applyMaterial() {
        let newMaterial = materialType.createRealityKitMaterial()
        for entity in beadEntities {
            entity.model?.materials = [newMaterial]
        }
        if let guru = beadRingEntity.children.first(where: { $0.name == "guru_bead" }) as? ModelEntity {
            guru.model?.materials = [newMaterial]
        }
    }

    /// 旋轉佛珠環
    /// - Parameter deltaAngle: 旋轉角度差量（弧度）
    func rotateRing(by deltaAngle: Float) {
        let current = beadRingEntity.orientation
        let rotation = simd_quatf(angle: deltaAngle, axis: SIMD3<Float>(0, 1, 0))
        beadRingEntity.orientation = rotation * current
    }

    /// 動畫推進一顆佛珠
    func animateBeadForward() {
        let rotation = simd_quatf(angle: -anglePerBead, axis: SIMD3<Float>(0, 1, 0))
        let targetOrientation = rotation * beadRingEntity.orientation

        beadRingEntity.move(
            to: Transform(
                scale: beadRingEntity.scale,
                rotation: targetOrientation,
                translation: beadRingEntity.position
            ),
            relativeTo: beadRingEntity.parent,
            duration: 0.25,
            timingFunction: .easeInOut
        )
    }
}
#endif
