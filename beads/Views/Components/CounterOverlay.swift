// MARK: - 檔案說明
/// CounterOverlay.swift
/// 計數器疊加層視圖 - 在佛珠場景上方顯示念誦計數、圈數、今日統計等資訊
/// 模組：Views/Components

//
//  CounterOverlay.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI

/// 計數器疊加層視圖
/// 覆蓋在 3D 佛珠場景上方，顯示咒語名稱、圈數、總計數、今日計數及連續修行天數
struct CounterOverlay: View {
    /// 目前總計數
    let count: Int
    /// 目前圈數
    let rounds: Int
    /// 今日念誦計數
    let todayCount: Int
    /// 連續修行天數
    let streakDays: Int
    /// 咒語名稱
    let mantraName: String

    /// 視圖主體
    var body: some View {
        VStack {
            // 頂部列 — 顯示咒語名稱
            HStack {
                Text(mantraName)
                    .font(.headline)
                    .foregroundStyle(BeadsTheme.Colors.accent)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // 圈數顯示 — 僅在已有圈數時顯示
            if rounds > 0 {
                Text("第 \(rounds) 圈")
                    .font(.title3)
                    .foregroundStyle(BeadsTheme.Colors.textSecondary)
                    .padding(.top, 4)
            }

            Spacer()

            // 中央計數顯示 — 大字體總計數與標籤
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .foregroundStyle(BeadsTheme.Colors.textPrimary)
                    .contentTransition(.numericText())
                Text("總計數")
                    .font(.caption)
                    .foregroundStyle(BeadsTheme.Colors.textTertiary)
            }

            Spacer()

            // 咒語文字顯示
            Text(mantraName)
                .font(.title2)
                .foregroundStyle(BeadsTheme.Colors.textPrimary)
                .padding(.bottom, 8)

            // 底部統計列 — 今日計數與連續天數
            HStack {
                Label("今日：\(todayCount)", systemImage: "sun.min")
                    .font(.footnote)
                    .foregroundStyle(BeadsTheme.Colors.textSecondary)
                Spacer()
                Label("\(streakDays) 天", systemImage: "flame")
                    .font(.footnote)
                    .foregroundStyle(BeadsTheme.Colors.accent)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
}
