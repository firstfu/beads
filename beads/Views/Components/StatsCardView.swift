// MARK: - 檔案說明
/// StatsCardView.swift
/// 統計卡片視圖 - 以卡片形式顯示單項統計數據（標題、數值、副標題、圖示）
/// 模組：Views/Components

//
//  StatsCardView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI

/// 禪意金色常數，與 ZenBackgroundView glow 色一致
private let zenGold = Color(red: 0.83, green: 0.66, blue: 0.29)

/// 統計卡片視圖
/// 以圓角矩形卡片呈現單項統計資訊，包含圖示、標題、主要數值及副標題，
/// 帶有主題色漸層裝飾
struct StatsCardView: View {
    /// 卡片標題（如「今日計數」）
    let title: String
    /// 主要數值文字（如「1,080」）
    let value: String
    /// 副標題說明文字（如「較昨日 +200」）
    let subtitle: String
    /// SF Symbols 圖示名稱（如「flame」）
    let icon: String
    /// 卡片主題色，預設為禪意金色
    var accentColor: Color = zenGold

    /// 視圖主體
    var body: some View {
        HStack(spacing: 0) {
            // 左側漸層色條裝飾
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 8) {
                // 頂部列 — 圓形漸層圖示與標題
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [accentColor, accentColor.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                // 主要數值 — 加大且使用 rounded 設計字型
                Text(value)
                    .font(.title2.bold().width(.condensed))
                    .fontDesign(.rounded)
                // 副標題 — 柔和顏色
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .padding(.leading, 10)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.trailing, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
