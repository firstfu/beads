// MARK: - 檔案說明
/// DedicationHistoryView.swift
/// 迴向歷史列表 - 按日期分組顯示所有迴向紀錄，支援搜尋
/// 模組：Views

//
//  DedicationHistoryView.swift
//  beads
//
//  Created on 2026/2/27.
//

import SwiftUI
import SwiftData

/// 禪意金色常數
private let zenGold = Color(red: 0.83, green: 0.66, blue: 0.29)

/// 迴向歷史列表視圖
/// 從 SwiftData 查詢所有有迴向的修行場次，按日期分組顯示，支援搜尋
struct DedicationHistoryView: View {
    /// 查詢所有有迴向的修行場次，按結束時間倒序排列
    @Query(filter: #Predicate<PracticeSession> { $0.hasDedication == true },
           sort: \PracticeSession.endTime, order: .reverse)
    private var dedicatedSessions: [PracticeSession]

    /// 從 SwiftData 查詢所有使用者設定
    @Query private var allSettings: [UserSettings]

    /// 搜尋文字
    @State private var searchText: String = ""

    /// 目前的背景主題
    private var currentBackgroundTheme: ZenBackgroundTheme {
        if let raw = allSettings.first?.backgroundTheme {
            return ZenBackgroundTheme(rawValue: raw) ?? .inkWash
        }
        return .inkWash
    }

    /// 根據搜尋文字篩選後的場次列表
    private var filteredSessions: [PracticeSession] {
        guard !searchText.isEmpty else { return dedicatedSessions }
        let query = searchText.lowercased()
        return dedicatedSessions.filter { session in
            (session.dedicationTarget?.lowercased().contains(query) ?? false) ||
            (session.dedicationText?.lowercased().contains(query) ?? false) ||
            session.mantraName.lowercased().contains(query)
        }
    }

    /// 按日期分組的場次
    private var groupedSessions: [(key: String, sessions: [PracticeSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSessions) { session -> String in
            guard let endTime = session.endTime else { return "未知日期" }
            if calendar.isDateInToday(endTime) {
                return "今日"
            } else if calendar.isDateInYesterday(endTime) {
                return "昨日"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "M 月 d 日 EEEE"
                formatter.locale = Locale(identifier: "zh_Hant")
                return formatter.string(from: endTime)
            }
        }
        // 保持倒序：依據每組第一筆的 endTime 排序
        return grouped.sorted { a, b in
            let aTime = a.value.first?.endTime ?? .distantPast
            let bTime = b.value.first?.endTime ?? .distantPast
            return aTime > bTime
        }.map { (key: $0.key, sessions: $0.value) }
    }

    var body: some View {
        ZStack {
            ZenBackgroundView(theme: currentBackgroundTheme, enableLotusDecoration: false)

            Group {
                if filteredSessions.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView(
                            "尚無迴向紀錄",
                            systemImage: "hands.and.sparkles",
                            description: Text("完成修行後進行迴向，紀錄將顯示於此")
                        )
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                } else {
                    List {
                        ForEach(groupedSessions, id: \.key) { group in
                            Section {
                                ForEach(group.sessions, id: \.self) { session in
                                    NavigationLink(destination: DedicationDetailView(session: session)) {
                                        DedicationRowView(session: session)
                                    }
                                    .listRowBackground(Color.white.opacity(0.08))
                                }
                            } header: {
                                Text(group.key)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(zenGold)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("迴向紀錄")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "搜尋迴向對象或迴向文")
    }
}

// MARK: - 迴向列表行視圖

/// 迴向列表中的單行視圖
private struct DedicationRowView: View {
    let session: PracticeSession

    /// 迴向文摘要（前 20 字）
    private var textPreview: String? {
        guard let text = session.dedicationText, !text.isEmpty else { return nil }
        if text.count > 20 {
            return String(text.prefix(20)) + "⋯"
        }
        return text
    }

    /// 格式化的時間
    private var formattedTime: String {
        guard let endTime = session.endTime else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: endTime)
    }

    var body: some View {
        HStack(spacing: 12) {
            // 左側 zenGold 色條
            RoundedRectangle(cornerRadius: 2)
                .fill(zenGold)
                .frame(width: 4, height: 50)

            // 主要資訊
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.mantraName)
                        .font(.body.weight(.medium))
                    Text("\(session.count) 遍 · \(session.rounds) 圈")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(session.dedicationTarget ?? "迴向法界眾生")
                    .font(.subheadline)
                    .foregroundStyle(zenGold.opacity(0.9))

                if let preview = textPreview {
                    Text(preview)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 右側時間
            Text(formattedTime)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
