//
//  Mantra.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

import Foundation
import SwiftData

@Model
final class Mantra {
    var name: String
    var originalText: String
    var pinyinText: String
    var descriptionText: String
    var category: String
    var suggestedCount: Int
    var sortOrder: Int

    init(
        name: String,
        originalText: String,
        pinyinText: String = "",
        descriptionText: String = "",
        category: String = "淨土宗",
        suggestedCount: Int = 108,
        sortOrder: Int = 0
    ) {
        self.name = name
        self.originalText = originalText
        self.pinyinText = pinyinText
        self.descriptionText = descriptionText
        self.category = category
        self.suggestedCount = suggestedCount
        self.sortOrder = sortOrder
    }
}
