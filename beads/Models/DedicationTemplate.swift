// MARK: - 檔案說明
/// DedicationTemplate.swift
/// 預設迴向文模板 - 提供常見的佛教迴向文供使用者選擇
/// 模組：Models

//
//  DedicationTemplate.swift
//  beads
//
//  Created by firstfu on 2026/2/27.
//

import Foundation

/// 預設迴向文模板
/// 提供常見的佛教迴向文供使用者選擇
enum DedicationTemplate: String, CaseIterable, Identifiable {
    case universal = "通用迴向文"
    case pureLand = "淨土迴向文"
    case allBeings = "眾生迴向文"
    case ancestors = "祖先迴向文"
    case sickness = "消業迴向文"

    var id: String { rawValue }

    var name: String { rawValue }

    var fullText: String {
        switch self {
        case .universal:
            return "願以此功德，莊嚴佛淨土，上報四重恩，下濟三途苦，若有見聞者，悉發菩提心，盡此一報身，同生極樂國。"
        case .pureLand:
            return "願以此功德，迴向西方極樂世界。願生淨土中，九品蓮花為父母，花開見佛悟無生，不退菩薩為伴侶。"
        case .allBeings:
            return "願以此功德，普及於一切，我等與眾生，皆共成佛道。"
        case .ancestors:
            return "願以此功德，迴向歷代祖先、累世父母，離苦得樂，往生善處。"
        case .sickness:
            return "願以此功德，迴向法界眾生，業障消除，身心康泰，福慧增長。"
        }
    }
}
