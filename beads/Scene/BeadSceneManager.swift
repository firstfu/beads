// MARK: - 檔案說明
/// BeadSceneManager.swift
/// 環形佛珠 3D 場景管理器 - 負責建立和管理環形排列的佛珠場景
/// 模組：Scene

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

/// 環形佛珠場景管理器
/// 負責建立 SceneKit 3D 場景，包含佛珠環形排列、材質設定、燈光配置、
/// 母珠標記、佛珠高亮顯示及手勢驅動的旋轉動畫
final class BeadSceneManager {
    /// 場景物件，包含所有 3D 節點
    let scene: SCNScene
    /// 所有佛珠節點的陣列
    private var beadNodes: [SCNNode] = []
    /// 佛珠總數（使用者指定，上限 108）
    private let beadCount: Int

    // MARK: - 排列參數

    /// 圓環半徑
    private let circleRadius: Float = 2.0
    /// 單顆佛珠半徑
    private let beadRadius: Float = 0.18
    /// 佛珠之間的間隙
    private let beadGap: Float = 0.06
    /// 實際顯示在圓環上的佛珠數量（受圓周長限制）
    private var displayCount: Int = 0

    /// 佛珠環容器節點 - 旋轉此節點以模擬佛珠滑動效果
    private let beadRingNode = SCNNode()

    /// 每顆佛珠對應的角度步幅（弧度），供手勢處理使用
    private(set) var anglePerBead: Float = 0

    /// 拖曳手勢累計旋轉量（弧度）
    var panRotation: Float = 0

    /// 目前高亮的佛珠索引，變更時自動觸發高亮更新
    var currentBeadIndex: Int = 0 {
        didSet { highlightCurrentBead() }
    }

    /// 目前佛珠材質類型，變更時自動套用新材質
    var materialType: BeadMaterialType = .zitan {
        didSet { applyMaterial() }
    }

    /// 初始化環形佛珠場景管理器
    /// - Parameter beadCount: 佛珠總數，預設 108，上限 108
    init(beadCount: Int = 108) {
        self.beadCount = min(beadCount, 108)
        self.scene = SCNScene()

        // 根據圓周長計算可容納的佛珠數量，避免重疊
        let circumference = 2.0 * Float.pi * circleRadius
        let beadDiameter = beadRadius * 2.0
        let spacePerBead = beadDiameter + beadGap
        self.displayCount = min(Int(circumference / spacePerBead), beadCount)
        self.anglePerBead = (Float.pi * 2.0) / Float(displayCount)

        setupScene()
    }

    /// 設定場景基礎元素
    /// 包含背景色、攝影機、環境光、主光源、補光燈，並呼叫建立佛珠和串線
    private func setupScene() {
        #if os(macOS)
            scene.background.contents = NSColor.clear
        #else
            scene.background.contents = UIColor.clear
        #endif

        // 攝影機 — 定位以完整呈現佛珠圓環
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 55
        cameraNode.position = SCNVector3(0, 0, 10.0)
        cameraNode.name = "camera"
        scene.rootNode.addChildNode(cameraNode)

        // 環境光 — 柔和的整體照明
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

        // 主光源 — 帶陰影的方向光
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 800
        keyLight.light?.castsShadow = true
        keyLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
        scene.rootNode.addChildNode(keyLight)

        // 補光燈 — 柔化陰影
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.intensity = 300
        fillLight.eulerAngles = SCNVector3(-Float.pi / 6, -Float.pi / 3, 0)
        scene.rootNode.addChildNode(fillLight)

        createBeads()
        createString()
    }

    /// 建立佛珠環形排列
    /// 在圓形軌道上均勻排列佛珠節點，並在頂部建立較大的母珠
    private func createBeads() {
        // 將環形容器加入場景
        beadRingNode.name = "bead_ring"
        scene.rootNode.addChildNode(beadRingNode)

        let beadGeometry = SCNSphere(radius: CGFloat(beadRadius))
        beadGeometry.segmentCount = 48

        let material = SCNMaterial()
        materialType.applyTo(material)
        beadGeometry.materials = [material]

        // 將佛珠均勻分布在圓環容器內
        for i in 0..<displayCount {
            let angle = Float(i) / Float(displayCount) * Float.pi * 2 + Float.pi / 2
            let x = circleRadius * cos(angle)
            let y = circleRadius * sin(angle)

            let node = SCNNode(geometry: beadGeometry.copy() as? SCNGeometry)
            node.position = SCNVector3(x, y, 0)
            node.name = "bead_\(i)"
            beadRingNode.addChildNode(node)
            beadNodes.append(node)

            // 母珠使用刻印卍字材質
            if i == 0 {
                let guruMaterial = SCNMaterial()
                materialType.applyTo(guruMaterial, isGuruBead: true)
                node.geometry?.materials = [guruMaterial]
            }
        }

    }

    /// 繪製串線
    /// 使用細環面（Torus）作為連接佛珠的串線，串線不隨佛珠旋轉
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
        // 串線留在場景根節點（不隨佛珠旋轉）
        scene.rootNode.addChildNode(stringNode)
    }

    /// 高亮顯示目前佛珠
    private func highlightCurrentBead() {
        // 不做放大效果
    }

    /// 套用材質至所有佛珠
    /// 將目前 materialType 的屬性套用到所有佛珠，母珠（bead_0）使用刻印卍字材質
    private func applyMaterial() {
        for (index, node) in beadNodes.enumerated() {
            if let geometry = node.geometry, let material = geometry.materials.first {
                materialType.applyTo(material, isGuruBead: index == 0)
            }
        }
    }

    // MARK: - 佛珠環旋轉（真實滑動感）

    /// 旋轉整個佛珠環
    /// 在拖曳手勢期間呼叫，將佛珠環沿 Z 軸旋轉指定的角度差量
    /// - Parameter deltaAngle: 旋轉角度差量（弧度）
    func rotateRing(by deltaAngle: Float) {
        panRotation += deltaAngle
        beadRingNode.eulerAngles = SCNVector3(0, 0, panRotation)
    }

    /// 吸附至最近的佛珠位置
    /// 手勢結束時呼叫，將佛珠環旋轉對齊到最近的佛珠格位，帶緩出動畫
    /// - Returns: 移動的佛珠步數（可能為 0）
    @discardableResult
    func snapToNearestBead() -> Int {
        // 計算已移動多少個完整的佛珠步數
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

    /// 動畫推進一顆佛珠
    /// 將佛珠環旋轉一個步幅，同時讓目前佛珠自轉一圈，帶緩入緩出動畫
    func animateBeadForward() {
        let targetAngle = panRotation - anglePerBead
        let index = currentBeadIndex % displayCount
        guard index < beadNodes.count else { return }
        let node = beadNodes[index]

        // 將整個佛珠環旋轉一個步幅
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        beadRingNode.eulerAngles = SCNVector3(0, 0, targetAngle)

        // 讓單顆佛珠沿切線方向自轉（完整一圈）
        let rollAngle = Float.pi * 2.0
        let currentEuler = node.eulerAngles
        node.eulerAngles = SCNVector3(currentEuler.x + rollAngle, currentEuler.y, currentEuler.z)

        SCNTransaction.commit()

        panRotation = targetAngle
    }
}
