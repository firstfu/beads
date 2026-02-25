import AVFoundation
import Observation

@Observable
final class AudioService {
    @ObservationIgnored private var ambientPlayer: AVAudioPlayer?
    @ObservationIgnored private var sfxPlayer: AVAudioPlayer?

    var isSFXEnabled: Bool = true
    var isAmbientEnabled: Bool = true
    var ambientVolume: Float = 0.5 {
        didSet { ambientPlayer?.volume = ambientVolume }
    }
    var sfxVolume: Float = 0.8
    private(set) var currentAmbientTrack: String?

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    func playBeadClick() {
        guard isSFXEnabled else { return }
        playSound(named: "bead_click", volume: sfxVolume)
    }

    func playRoundComplete() {
        guard isSFXEnabled else { return }
        playSound(named: "round_complete", volume: sfxVolume)
    }

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

    func stopAmbient() {
        ambientPlayer?.stop()
        ambientPlayer = nil
        currentAmbientTrack = nil
    }

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
