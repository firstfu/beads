// MARK: - 檔案說明

/// HapticService.swift
/// 觸覺回饋服務 - 管理撥珠與完成一圈時的震動回饋效果
/// 模組：Services

import CoreHaptics
import UIKit

/// 觸覺回饋服務管理類別
/// 負責處理應用程式中所有觸覺回饋（Haptic Feedback）功能
/// 使用 CoreHaptics 框架提供精細的震動模式，當裝置不支援時降級使用 UIKit 的基礎回饋
final class HapticService {
    /// CoreHaptics 觸覺引擎實例
    private var engine: CHHapticEngine?

    /// 是否啟用觸覺回饋功能
    var isEnabled: Bool = true

    /// 初始化觸覺回饋服務，啟動觸覺引擎
    init() {
        setupEngine()
    }

    /// 設定並啟動 CoreHaptics 觸覺引擎
    /// 若裝置不支援觸覺功能則跳過設定
    /// 同時註冊引擎重置處理器，確保引擎在異常停止後能自動重新啟動
    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            print("Haptic engine error: \(error)")
        }
    }

    /// 播放撥珠點擊的觸覺回饋
    /// 使用 UIImpactFeedbackGenerator 產生輕量級的撞擊感回饋
    /// 若觸覺回饋已停用則不執行任何動作
    func playBeadTap() {
        guard isEnabled else { return }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    /// 播放完成一圈的觸覺回饋
    /// 使用 CoreHaptics 產生三次連續的震動模式（間隔 0.15 秒），營造完成感
    /// 若裝置不支援 CoreHaptics，則降級使用 UINotificationFeedbackGenerator 的成功回饋
    /// 若觸覺回饋已停用則不執行任何動作
    func playRoundComplete() {
        guard isEnabled else { return }
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics, let engine else {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
            return
        }

        do {
            /// 觸覺銳利度參數（0.5 為中等銳利）
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)

            /// 觸覺強度參數（1.0 為最大強度）
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)

            /// 第一次震動事件（時間點 0 秒）
            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)

            /// 第二次震動事件（時間點 0.15 秒）
            let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.15)

            /// 第三次震動事件（時間點 0.3 秒）
            let event3 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.3)

            let pattern = try CHHapticPattern(events: [event1, event2, event3], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic pattern error: \(error)")
        }
    }
}
