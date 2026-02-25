// MARK: - 檔案說明
/// MantraListView.swift
/// 咒語列表畫面 - 以分類方式顯示所有咒語，支援搜尋與導航至詳情頁
/// 模組：Views/Scripture

//
//  MantraListView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI
import SwiftData

/// 分類的固定排序順序
private let categoryOrder: [String] = ["淨土宗", "咒語", "經典", "偈頌"]

/// 取得分類對應的 SF Symbol 圖示名稱
private func iconForCategory(_ category: String) -> String {
    switch category {
    case "淨土宗": return "figure.mind.and.body"
    case "咒語": return "wand.and.stars"
    case "經典": return "book.closed"
    case "偈頌": return "text.quote"
    default: return "list.bullet"
    }
}

/// 取得分類對應的強調色
private func colorForCategory(_ category: String) -> Color {
    switch category {
    case "淨土宗": return BeadsTheme.Colors.categoryPureLand
    case "咒語": return BeadsTheme.Colors.categoryMantra
    case "經典": return BeadsTheme.Colors.categoryClassic
    case "偈頌": return BeadsTheme.Colors.categoryVerse
    default: return BeadsTheme.Colors.textTertiary
    }
}

/// 咒語列表視圖
/// 將咒語按照分類分組顯示，支援搜尋功能
/// 點擊可導航至對應的咒語詳情頁面
struct MantraListView: View {
    /// 從資料庫查詢所有咒語，按排序順序排列
    @Query(sort: \Mantra.sortOrder) private var mantras: [Mantra]

    /// 搜尋文字
    @State private var searchText: String = ""

    /// 根據搜尋文字篩選後的咒語列表
    private var filteredMantras: [Mantra] {
        guard !searchText.isEmpty else { return mantras }
        let query = searchText.lowercased()
        return mantras.filter { mantra in
            mantra.name.lowercased().contains(query) ||
            mantra.pinyinText.lowercased().contains(query)
        }
    }

    /// 將篩選後的咒語按分類分組，並依固定順序排序
    private var sortedCategories: [(category: String, mantras: [Mantra])] {
        let grouped = Dictionary(grouping: filteredMantras, by: \.category)
        return categoryOrder.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category: category, mantras: items)
        } + grouped.keys
            .filter { !categoryOrder.contains($0) }
            .sorted()
            .compactMap { category in
                guard let items = grouped[category], !items.isEmpty else { return nil }
                return (category: category, mantras: items)
            }
    }

    /// 視圖主體
    var body: some View {
        Group {
            if filteredMantras.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(sortedCategories, id: \.category) { group in
                        Section {
                            ForEach(group.mantras, id: \.name) { mantra in
                                NavigationLink(destination: MantraDetailView(mantra: mantra)) {
                                    MantraRowView(
                                        mantra: mantra,
                                        accentColor: colorForCategory(group.category)
                                    )
                                }
                            }
                        } header: {
                            Label(group.category, systemImage: iconForCategory(group.category))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(colorForCategory(group.category))
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "搜尋經咒名稱或拼音")
    }
}

/// 咒語列表項目視圖
/// 顯示咒語名稱、拼音、簡短說明及建議持誦次數
private struct MantraRowView: View {
    let mantra: Mantra
    let accentColor: Color

    /// 取得說明文字的第一行作為預覽
    private var descriptionPreview: String? {
        let text = mantra.descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        return firstLine
    }

    var body: some View {
        HStack(spacing: 12) {
            // 分類色彩指示條
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 4, height: 44)

            // 主要資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(mantra.name)
                    .font(.body.weight(.medium))

                Text(mantra.pinyinText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let preview = descriptionPreview {
                    Text(preview)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 建議持誦次數標籤
            Text("\(mantra.suggestedCount) 遍")
                .font(.caption2.weight(.medium))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(accentColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}
