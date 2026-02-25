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

/// 統計卡片視圖
/// 以圓角矩形卡片呈現單項統計資訊，包含圖示、標題、主要數值及副標題，
/// 使用超薄毛玻璃材質背景
struct StatsCardView: View {
    /// 卡片標題（如「今日計數」）
    let title: String
    /// 主要數值文字（如「1,080」）
    let value: String
    /// 副標題說明文字（如「較昨日 +200」）
    let subtitle: String
    /// SF Symbols 圖示名稱（如「flame」）
    let icon: String

    /// 視圖主體
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 頂部列 — 圖示與標題
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            // 主要數值
            Text(value)
                .font(.title2.bold())
            // 副標題
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
