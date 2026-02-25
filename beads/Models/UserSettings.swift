//
//  UserSettings.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

import Foundation
import SwiftData

enum BeadDisplayMode: String, CaseIterable, Identifiable, Codable {
    case circular = "圓環式"
    case vertical = "直立式"

    var id: String { rawValue }
}

enum AmbientTrack: String, CaseIterable, Identifiable {
    case meditation1 = "meditation_1"
    case meditation2 = "meditation_2"
    case chanting1 = "chanting_1"
    case chanting2 = "chanting_2"
    case nature1 = "nature_1"
    case nature2 = "nature_2"
    case piano1 = "piano_1"
    case piano2 = "piano_2"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .meditation1: return "冥想氛圍 1"
        case .meditation2: return "冥想氛圍 2"
        case .chanting1: return "梵唄誦經 1"
        case .chanting2: return "梵唄誦經 2"
        case .nature1: return "自然之聲 1"
        case .nature2: return "自然之聲 2"
        case .piano1: return "靜心鋼琴 1"
        case .piano2: return "靜心鋼琴 2"
        }
    }

    var category: String {
        switch self {
        case .meditation1, .meditation2: return "禪修冥想"
        case .chanting1, .chanting2: return "梵唄誦經"
        case .nature1, .nature2: return "自然之聲"
        case .piano1, .piano2: return "輕音樂"
        }
    }

    static var groupedByCategory: [(category: String, tracks: [AmbientTrack])] {
        let categories = ["禪修冥想", "梵唄誦經", "自然之聲", "輕音樂"]
        return categories.map { cat in
            (category: cat, tracks: allCases.filter { $0.category == cat })
        }
    }
}

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
    var selectedAmbientTrack: String
    var displayMode: String = "圓環式"
    var fastScrollMode: Bool = false

    init() {
        self.currentBeadStyle = "小葉紫檀"
        self.beadsPerRound = 108
        self.soundEnabled = true
        self.hapticEnabled = true
        self.ambientSoundEnabled = true
        self.ambientVolume = 0.5
        self.sfxVolume = 0.8
        self.keepScreenOn = true
        self.selectedAmbientTrack = AmbientTrack.meditation1.rawValue
        self.displayMode = BeadDisplayMode.circular.rawValue
        self.fastScrollMode = false
    }
}
