// MARK: - 檔案說明
/// DedicationDetailView.swift
/// 迴向詳情畫面 - 顯示單筆修行的迴向完整資訊，包含修行資訊、迴向對象與迴向文全文
/// 模組：Views

//
//  DedicationDetailView.swift
//  beads
//
//  Created on 2026/2/27.
//

import SwiftUI
import SwiftData

/// 禪意金色常數
private let zenGold = Color(red: 0.83, green: 0.66, blue: 0.29)

/// 迴向詳情視圖
/// 以卡片式區塊顯示修行資訊、迴向對象與迴向文全文
struct DedicationDetailView: View {
    /// 修行場次資料
    let session: PracticeSession

    /// 從 SwiftData 查詢所有使用者設定
    @Query private var allSettings: [UserSettings]

    /// 目前的背景主題
    private var currentBackgroundTheme: ZenBackgroundTheme {
        if let raw = allSettings.first?.backgroundTheme {
            return ZenBackgroundTheme(rawValue: raw) ?? .inkWash
        }
        return .inkWash
    }

    /// 格式化的修行時長
    private var formattedDuration: String {
        let seconds = Int(session.duration)
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes) 分鐘"
        }
        let hours = minutes / 60
        let remaining = minutes % 60
        return "\(hours) 小時 \(remaining) 分"
    }

    /// 格式化的修行時間
    private var formattedTime: String {
        guard let endTime = session.endTime else { return "未知" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_Hant")
        return formatter.string(from: endTime)
    }

    var body: some View {
        ZStack {
            ZenBackgroundView(theme: currentBackgroundTheme, enableLotusDecoration: false)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    practiceInfoCard
                    dedicationTargetCard
                    dedicationTextCard
                }
                .padding()
            }
        }
        .navigationTitle("迴向詳情")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 修行資訊卡

    private var practiceInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("修行資訊", systemImage: "figure.mind.and.body")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                infoRow(icon: "book.closed", label: "咒語", value: session.mantraName)
                infoRow(icon: "number", label: "念誦", value: "\(session.count) 遍 · \(session.rounds) 圈")
                infoRow(icon: "clock", label: "時間", value: formattedTime)
                infoRow(icon: "hourglass", label: "時長", value: formattedDuration)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(zenGold)
                .frame(width: 20)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }

    // MARK: - 迴向對象卡

    private var dedicationTargetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("迴向對象", systemImage: "person.2")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(session.dedicationTarget ?? "迴向法界眾生")
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 迴向文卡

    private var dedicationTextCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("迴向文", systemImage: "text.quote")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(session.dedicationText ?? "")
                .font(.body)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
