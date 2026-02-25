// MARK: - 檔案說明
/// VerticalBeadSceneManager.swift
/// 垂直佛珠 3D 場景管理器 - 負責建立和管理垂直排列的佛珠場景
/// 模組：Scene

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

/// 垂直佛珠場景管理器
/// 負責建立 SceneKit 3D 場景，包含佛珠垂直排列、材質設定、燈光配置、
/// 佛珠高亮顯示及手勢驅動的平移動畫
final class VerticalBeadSceneManager {
    /// 場景物件，包含所有 3D 節點
    let scene: SCNScene
    /// 所有佛珠節點的陣列
    private var beadNodes: [SCNNode] = []
    /// 佛珠總數（使用者指定，上限 108）
    private let beadCount: Int

    // MARK: - 排列參數

    /// 單顆佛珠半徑
    private let beadRadius: Float = 0.3
    /// 佛珠之間的間隙
    private let beadGap: Float = 0.15
    /// 每顆佛珠的間距（直徑加間隙）
    private var beadSpacing: Float { beadRadius * 2.0 + beadGap }

    /// 佛珠直列容器節點 - 沿 Y 軸平移此節點以模擬捲動效果
    private let beadColumnNode = SCNNode()

    /// 每顆佛珠的間距（供手勢處理使用）
    var spacingPerBead: Float { beadSpacing }

    /// 拖曳手勢累計平移量
    var panTranslation: Float = 0

    /// 目前高亮的佛珠索引，變更時自動觸發高亮更新
    var currentBeadIndex: Int = 0 {
        didSet { highlightCurrentBead() }
    }

    /// 目前佛珠材質類型，變更時自動套用新材質
    var materialType: BeadMaterialType = .zitan {
        didSet { applyMaterial() }
    }

    /// 初始化垂直佛珠場景管理器
    /// - Parameter beadCount: 佛珠總數，預設 108，上限 108
    init(beadCount: Int = 108) {
        self.beadCount = min(beadCount, 108)
        self.scene = SCNScene()

        setupScene()
    }

    /// 設定場景基礎元素
    /// 包含背景色、攝影機、環境光、主光源、補光燈，並呼叫建立佛珠和串線
    private func setupScene() {
        #if os(macOS)
            scene.background.contents = NSColor.black
        #else
            scene.background.contents = UIColor.black
        #endif

        // 攝影機 — 定位以完整呈現垂直佛珠列
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 45
        cameraNode.position = SCNVector3(0, 0, 6)
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

    /// 建立佛珠垂直排列
    /// 沿 Y 軸向下排列指定數量的佛珠節點，索引 0 在最上方
    private func createBeads() {
        // 將直列容器加入場景
        beadColumnNode.name = "bead_column"
        scene.rootNode.addChildNode(beadColumnNode)

        let beadGeometry = SCNSphere(radius: CGFloat(beadRadius))
        beadGeometry.segmentCount = 48

        let material = SCNMaterial()
        materialType.applyTo(material)
        beadGeometry.materials = [material]

        // 沿 Y 軸排列所有佛珠，索引 0 在頂部（y = 0），向下遞減
        for i in 0..<beadCount {
            let y = -Float(i) * beadSpacing

            let node = SCNNode(geometry: beadGeometry.copy() as? SCNGeometry)
            node.position = SCNVector3(0, y, 0)
            node.name = "bead_\(i)"
            beadColumnNode.addChildNode(node)
            beadNodes.append(node)
        }
    }

    /// 繪製串線
    /// 使用細圓柱體覆蓋整個可見區域，固定在場景根節點不隨佛珠列移動
    private func createString() {
        let visibleHeight = orthoScale * 2 + beadRadius * 4
        let cylinder = SCNCylinder(radius: 0.015, height: CGFloat(visibleHeight))

        let stringMaterial = SCNMaterial()
        #if os(macOS)
            stringMaterial.diffuse.contents = NSColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 1.0)
        #else
            stringMaterial.diffuse.contents = UIColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 1.0)
        #endif
        cylinder.materials = [stringMaterial]

        let stringNode = SCNNode(geometry: cylinder)
        stringNode.position = SCNVector3(0, 0, 0)
        stringNode.name = "string"
        scene.rootNode.addChildNode(stringNode)
    }

    /// 高亮顯示目前佛珠
    /// 將目前佛珠放大至 1.3 倍，其餘佛珠恢復原始大小，帶 0.15 秒動畫
    private func highlightCurrentBead() {
        for (i, node) in beadNodes.enumerated() {
            let scale: Float = (i == currentBeadIndex) ? 1.3 : 1.0
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.15
            node.scale = SCNVector3(scale, scale, scale)
            SCNTransaction.commit()
        }
    }

    /// 套用材質至所有佛珠
    /// 將目前 materialType 的屬性套用到所有佛珠節點
    private func applyMaterial() {
        for node in beadNodes {
            if let geometry = node.geometry, let material = geometry.materials.first {
                materialType.applyTo(material)
            }
        }
    }

    // MARK: - 佛珠列平移（真實滑動感）

    /// 平移整個佛珠列
    /// 在拖曳手勢期間呼叫，將佛珠列沿 Y 軸平移指定的差量，並重新定位佛珠以實現無限循環
    /// - Parameter deltaY: Y 軸平移差量
    func translateColumn(by deltaY: Float) {
        panTranslation += deltaY
        beadColumnNode.position = SCNVector3(0, panTranslation, 0)
        repositionBeadsForWrapping()
    }

    /// 吸附至最近的佛珠位置
    /// 手勢結束時呼叫，將佛珠列對齊到最近的佛珠格位，帶緩出動畫
    /// - Returns: 移動的佛珠步數（可能為 0）
    @discardableResult
    func snapToNearestBead() -> Int {
        // 計算已移動多少個完整的佛珠步數
        let steps = Int(round(panTranslation / beadSpacing))
        let snappedY = Float(steps) * beadSpacing

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.2
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        beadColumnNode.position = SCNVector3(0, snappedY, 0)
        SCNTransaction.commit()

        panTranslation = snappedY
        repositionBeadsForWrapping()
        return steps
    }

    /// 動畫推進一顆佛珠
    /// 將佛珠列向上平移一個間距，同時讓目前佛珠自轉一圈，帶緩入緩出動畫
    func animateBeadForward() {
        let targetY = panTranslation + beadSpacing
        let index = currentBeadIndex
        guard index < beadNodes.count else { return }
        let node = beadNodes[index]

        // 將整個佛珠列向上平移一個間距
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        beadColumnNode.position = SCNVector3(0, targetY, 0)

        // 讓單顆佛珠沿自身軸心自轉（完整一圈）
        let rollAngle = Float.pi * 2.0
        let currentEuler = node.eulerAngles
        node.eulerAngles = SCNVector3(currentEuler.x + rollAngle, currentEuler.y, currentEuler.z)

        SCNTransaction.commit()

        panTranslation = targetY
        repositionBeadsForWrapping()
    }

    // MARK: - 無限循環滾動

    /// 重新定位佛珠以實現無限循環滾動
    /// 將滾出可見區域的佛珠環繞到另一端，使 108 顆佛珠形成無縫循環
    /// 利用模數算術讓每顆佛珠始終出現在最接近相機中心的位置
    private func repositionBeadsForWrapping() {
        let totalLength = Float(beadCount) * beadSpacing
        let cameraLocalY = -panTranslation

        for (i, node) in beadNodes.enumerated() {
            let baseY = -Float(i) * beadSpacing
            let offset = round((cameraLocalY - baseY) / totalLength)
            let wrappedY = baseY + offset * totalLength
            node.position = SCNVector3(0, wrappedY, 0)
        }
    }
}
