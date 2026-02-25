// MARK: - 檔案說明

/// AudioService.swift
/// 音訊服務 - 管理撥珠音效與背景環境音樂的播放、停止及音量控制
/// 模組：Services

import AVFoundation
import Observation

/// 音訊服務管理類別
/// 負責處理應用程式中所有音訊相關功能，包含：
/// - 撥珠點擊音效（SFX）
/// - 完成一圈提示音效
/// - 背景環境音樂的播放、停止與淡出
/// 使用 `@Observable` 巨集支援 SwiftUI 的響應式更新
@Observable
final class AudioService {
    /// 背景環境音樂播放器（標記為 @ObservationIgnored 避免不必要的 UI 更新）
    @ObservationIgnored private var ambientPlayer: AVAudioPlayer?

    /// 音效播放器（標記為 @ObservationIgnored 避免不必要的 UI 更新）
    @ObservationIgnored private var sfxPlayer: AVAudioPlayer?

    /// 是否啟用音效（撥珠音效、完成提示音等）
    var isSFXEnabled: Bool = true

    /// 是否啟用背景環境音樂
    var isAmbientEnabled: Bool = true

    /// 背景音樂音量（0.0 ~ 1.0），變更時即時同步至播放器
    var ambientVolume: Float = 0.5 {
        didSet { ambientPlayer?.volume = ambientVolume }
    }

    /// 音效音量（0.0 ~ 1.0）
    var sfxVolume: Float = 0.8

    /// 目前正在播放的背景音樂曲目名稱（未播放時為 nil）
    private(set) var currentAmbientTrack: String?

    /// 初始化音訊服務，配置 AVAudioSession
    init() {
        configureAudioSession()
    }

    /// 配置 AVAudioSession
    /// 設定為 playback 類別並允許與其他音訊混合播放，確保背景音樂能正常運作
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    /// 播放撥珠點擊音效
    /// 若音效已停用則不執行任何動作
    func playBeadClick() {
        guard isSFXEnabled else { return }
        playSound(named: "bead_click", volume: sfxVolume)
    }

    /// 播放完成一圈的提示音效
    /// 若音效已停用則不執行任何動作
    func playRoundComplete() {
        guard isSFXEnabled else { return }
        playSound(named: "round_complete", volume: sfxVolume)
    }

    /// 開始播放指定的背景環境音樂
    /// 若背景音樂已停用或正在播放相同曲目則不執行任何動作
    /// 音樂會設定為無限循環播放
    /// - Parameter name: 音樂檔案名稱（不含副檔名，檔案格式為 mp3）
    func startAmbient(named name: String) {
        guard isAmbientEnabled else { return }
        // Don't restart if already playing the same track
        if currentAmbientTrack == name, ambientPlayer?.isPlaying == true {
            return
        }
        stopAmbient()
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "ambient")
                ?? Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("Ambient file not found: \(name).mp3")
            return
        }
        do {
            ambientPlayer = try AVAudioPlayer(contentsOf: url)
            ambientPlayer?.numberOfLoops = -1
            ambientPlayer?.volume = ambientVolume
            ambientPlayer?.play()
            currentAmbientTrack = name
        } catch {
            print("Ambient audio error: \(error)")
        }
    }

    /// 立即停止背景環境音樂播放
    /// 釋放播放器資源並清除當前曲目紀錄
    func stopAmbient() {
        ambientPlayer?.stop()
        ambientPlayer = nil
        currentAmbientTrack = nil
    }

    /// 漸弱淡出背景環境音樂
    /// 在指定時間內逐步降低音量至靜音後停止播放
    /// - Parameter duration: 淡出持續時間（單位：秒，預設為 1.0 秒）
    func fadeOutAmbient(duration: TimeInterval = 1.0) {
        guard let player = ambientPlayer else { return }
        let steps = 20
        let interval = duration / Double(steps)
        let volumeStep = player.volume / Float(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                player.volume -= volumeStep
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.ambientPlayer?.stop()
            self?.ambientPlayer = nil
            self?.currentAmbientTrack = nil
        }
    }

    /// 播放指定名稱的音效檔案
    /// 支援 wav 和 mp3 兩種格式，優先尋找 wav 檔案
    /// - Parameters:
    ///   - name: 音效檔案名稱（不含副檔名）
    ///   - volume: 播放音量（0.0 ~ 1.0）
    private func playSound(named name: String, volume: Float) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") ??
                        Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            sfxPlayer = try AVAudioPlayer(contentsOf: url)
            sfxPlayer?.volume = volume
            sfxPlayer?.play()
        } catch {
            print("SFX error: \(error)")
        }
    }
}
