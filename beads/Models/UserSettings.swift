//
//  UserSettings.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

import Foundation
import SwiftData

@Model
final class UserSettings {
    var currentBeadStyle: String
    var beadsPerRound: Int
    var soundEnabled: Bool
    var hapticEnabled: Bool
    var ambientSoundEnabled: Bool
    var ambientVolume: Float
    var sfxVolume: Float
    var keepScreenOn: Bool

    init() {
        self.currentBeadStyle = "小葉紫檀"
        self.beadsPerRound = 108
        self.soundEnabled = true
        self.hapticEnabled = true
        self.ambientSoundEnabled = true
        self.ambientVolume = 0.5
        self.sfxVolume = 0.8
        self.keepScreenOn = true
    }
}
