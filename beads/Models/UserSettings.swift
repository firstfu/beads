//
//  UserSettings.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

// MARK: - 檔案說明

/// UserSettings.swift
/// 使用者設定模型 - 管理佛珠外觀、音效、觸覺回饋、背景音樂等偏好設定
/// 模組：Models

import Foundation
import SwiftData

// MARK: - BeadDisplayMode

/// 佛珠顯示模式列舉
/// 定義 3D 佛珠在畫面上的排列方式
enum BeadDisplayMode: String, CaseIterable, Identifiable, Codable {
    /// 圓環式排列（佛珠排成環形）
    case circular = "圓環式"

    /// 直立式排列（佛珠排成直線）
    case vertical = "直立式"

    /// 用於 Identifiable 協定的唯一識別值
    var id: String { rawValue }
}

// MARK: - AmbientTrack

/// 背景音樂曲目列舉
/// 定義修行時可選用的各種背景環境音樂
enum AmbientTrack: String, CaseIterable, Identifiable {
    /// 冥想氛圍音樂 1
    case meditation1 = "meditation_1"

    /// 冥想氛圍音樂 2
    case meditation2 = "meditation_2"

    /// 梵唄誦經音樂 1
    case chanting1 = "chanting_1"

    /// 梵唄誦經音樂 2
    case chanting2 = "chanting_2"

    /// 自然之聲音樂 1
    case nature1 = "nature_1"

    /// 自然之聲音樂 2
    case nature2 = "nature_2"

    /// 靜心鋼琴音樂 1
    case piano1 = "piano_1"

    /// 靜心鋼琴音樂 2
    case piano2 = "piano_2"

    /// 唸佛經誦經 1（佛經唸誦）
    case sutraChanting1 = "sutra_chanting_1"

    /// 唸佛經誦經 2（唵誦經 Lo-Fi）
    case sutraChanting2 = "sutra_chanting_2"

    /// 唸佛經誦經 3（六字大明咒）
    case sutraChanting3 = "sutra_chanting_3"

    /// 用於 Identifiable 協定的唯一識別值
    var id: String { rawValue }

    /// 曲目的繁體中文顯示名稱
    /// - Returns: 適合在 UI 上顯示的曲目名稱
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
        case .sutraChanting1: return "唸佛經 1"
        case .sutraChanting2: return "唸佛經 2"
        case .sutraChanting3: return "唸佛經 3"
        }
    }

    /// 曲目所屬的音樂分類名稱
    /// - Returns: 分類名稱（禪修冥想、梵唄誦經、唸佛經、自然之聲、輕音樂）
    var category: String {
        switch self {
        case .meditation1, .meditation2: return "禪修冥想"
        case .chanting1, .chanting2: return "梵唄誦經"
        case .nature1, .nature2: return "自然之聲"
        case .piano1, .piano2: return "輕音樂"
        case .sutraChanting1, .sutraChanting2, .sutraChanting3: return "唸佛經"
        }
    }

    /// 依分類分組的曲目清單
    /// 將所有曲目按分類歸類，方便 UI 分組顯示
    /// - Returns: 包含分類名稱與對應曲目陣列的元組陣列
    static var groupedByCategory: [(category: String, tracks: [AmbientTrack])] {
        let categories = ["禪修冥想", "梵唄誦經", "唸佛經", "自然之聲", "輕音樂"]
        return categories.map { cat in
            (category: cat, tracks: allCases.filter { $0.category == cat })
        }
    }
}

// MARK: - UserSettings

/// 使用者偏好設定資料模型
/// 使用 SwiftData 進行持久化儲存，管理應用程式的所有使用者偏好設定
/// 包含佛珠樣式、音效開關、觸覺回饋、背景音樂選擇等設定項目
@Model
final class UserSettings {
    /// 當前佛珠材質樣式名稱（例如：「小葉紫檀」）
    var currentBeadStyle: String

    /// 每圈念珠數量（預設為 108）
    var beadsPerRound: Int

    /// 是否啟用音效（撥珠音效等）
    var soundEnabled: Bool

    /// 是否啟用觸覺回饋（震動等）
    var hapticEnabled: Bool

    /// 是否啟用背景環境音樂
    var ambientSoundEnabled: Bool

    /// 背景音樂音量（0.0 ~ 1.0）
    var ambientVolume: Float

    /// 音效音量（0.0 ~ 1.0）
    var sfxVolume: Float

    /// 是否保持螢幕常亮（修行期間防止螢幕自動關閉）
    var keepScreenOn: Bool

    /// 已選擇的背景音樂曲目識別碼（對應 AmbientTrack 的 rawValue）
    var selectedAmbientTrack: String

    /// 佛珠顯示模式（對應 BeadDisplayMode 的 rawValue，預設為「直立式」）
    var displayMode: String = "直立式"

    /// 是否啟用快速滾動模式（加速撥珠操作）
    var fastScrollMode: Bool = false

    /// 背景主題（對應 ZenBackgroundTheme 的 rawValue，預設為「水墨」）
    var backgroundTheme: String = "水墨"

    /// 初始化使用者設定，設定所有偏好項目的預設值
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
        self.displayMode = BeadDisplayMode.vertical.rawValue
        self.fastScrollMode = false
        self.backgroundTheme = ZenBackgroundTheme.inkWash.rawValue
    }
}
