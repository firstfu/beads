// MARK: - 檔案說明
/// BraceletBeadSceneManager.swift
/// 手串佛珠 3D 場景管理器 - 負責建立和管理垂直懸掛式佛珠場景
/// 模組：Scene

//
//  BraceletBeadSceneManager.swift
//  beads
//
//  Created by firstfu on 2026/2/27.
//

import SceneKit

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

/// 手串佛珠場景管理器
/// 負責建立 SceneKit 3D 場景，佛珠環形排列在 XY 平面上垂直懸掛，
/// 相機從正前方近距離觀看，產生強烈的 3D 透視效果。
/// 材質設定、燈光配置、佛珠高亮顯示及手勢驅動的旋轉動畫
final class BraceletBeadSceneManager {
    /// 場景物件，包含所有 3D 節點
    let scene: SCNScene
    /// 所有佛珠節點的陣列
    private var beadNodes: [SCNNode] = []
    /// 佛珠總數（使用者指定，上限 108）
    private let beadCount: Int

    // MARK: - 排列參數

    /// 圓環半徑
    private let circleRadius: Float = 2.5
    /// 單顆佛珠半徑
    private let beadRadius: Float = 0.40
    /// 佛珠之間的間隙
    private let beadGap: Float = 0.10
    /// 實際顯示在圓環上的佛珠數量（受圓周長限制）
    private var displayCount: Int = 0

    /// 傾斜容器節點 - 負責 Y 軸傾斜 + X 軸偏移置中
    private let tiltNode = SCNNode()
    /// 佛珠環容器節點 - 只負責 Z 軸旋轉（撥珠滑動）
    private let beadRingNode = SCNNode()

    /// Y 軸旋轉角度（大角度側視產生強透視效果）
    private let yTilt: Float = 70.0 * Float.pi / 180.0

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

    /// 初始化手串佛珠場景管理器
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

        // 攝影機 — 正前方近距離，強透視效果
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 75
        cameraNode.position = SCNVector3(0, 0, 6.5)
        cameraNode.eulerAngles = SCNVector3(0, 0, 0)
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

        // 主光源 — 帶陰影的方向光（更陡角度加強深度感）
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 1000
        keyLight.light?.castsShadow = true
        keyLight.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(keyLight)

        // 補光燈 — 降低強度增加明暗對比
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.intensity = 200
        fillLight.eulerAngles = SCNVector3(-Float.pi / 6, -Float.pi / 3, 0)
        scene.rootNode.addChildNode(fillLight)

        // Rim light — 從後方微弱打光，勾勒前排佛珠輪廓
        let rimLight = SCNNode()
        rimLight.light = SCNLight()
        rimLight.light?.type = .directional
        rimLight.light?.intensity = 150
        rimLight.eulerAngles = SCNVector3(0, Float.pi, 0)
        scene.rootNode.addChildNode(rimLight)

        createBeads()
        createString()
    }

    /// 建立佛珠環形排列
    /// 在圓形軌道上均勻排列佛珠節點，並在頂部建立較大的母珠
    /// Y 軸微傾增加立體感
    private func createBeads() {
        // tiltNode 負責 Y 軸傾斜 + X 軸偏移置中
        tiltNode.name = "tilt_container"
        tiltNode.eulerAngles = SCNVector3(0, yTilt, 0)
        tiltNode.position = SCNVector3(0.5, 0, 0)
        scene.rootNode.addChildNode(tiltNode)

        // beadRingNode 只負責 Z 軸旋轉（撥珠滑動）
        beadRingNode.name = "bead_ring"
        beadRingNode.eulerAngles = SCNVector3(0, 0, 0)
        tiltNode.addChildNode(beadRingNode)

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
        }
    }

    /// 繪製串線
    /// 使用細環面（Torus）作為連接佛珠的串線，放入 beadRingNode 確保與佛珠同平面
    private func createString() {
        let torus = SCNTorus(ringRadius: CGFloat(circleRadius), pipeRadius: 0.018)
        let stringMaterial = SCNMaterial()
        #if os(macOS)
            stringMaterial.diffuse.contents = NSColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 1.0)
        #else
            stringMaterial.diffuse.contents = UIColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 1.0)
        #endif
        torus.materials = [stringMaterial]

        let stringNode = SCNNode(geometry: torus)
        // 在 beadRingNode 局部座標中，Torus 從 XZ 平面旋轉至 XY 平面即可
        stringNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        stringNode.name = "string"
        beadRingNode.addChildNode(stringNode)
    }

    /// 高亮顯示目前佛珠
    private func highlightCurrentBead() {
        // 不做放大效果（與環形模式一致）
    }

    /// 套用材質至所有佛珠
    /// 將目前 materialType 的屬性套用到所有佛珠，母珠（bead_0）使用刻印卍字材質
    private func applyMaterial() {
        for node in beadNodes {
            if let geometry = node.geometry, let material = geometry.materials.first {
                materialType.applyTo(material)
            }
        }
    }

    // MARK: - 佛珠環旋轉（真實滑動感）

    /// 旋轉整個佛珠環
    /// 在拖曳手勢期間呼叫，將佛珠環沿局部 Z 軸旋轉指定的角度差量
    /// 圓環繞 Z 軸旋轉，佛珠沿圓環垂直循環
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
    /// 將佛珠環旋轉一個步幅，帶緩入緩出動畫
    func animateBeadForward() {
        let targetAngle = panRotation - anglePerBead
        let index = currentBeadIndex % displayCount
        guard index < beadNodes.count else { return }

        // 將整個佛珠環旋轉一個步幅
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        beadRingNode.eulerAngles = SCNVector3(0, 0, targetAngle)
        SCNTransaction.commit()

        panRotation = targetAngle
    }
}
