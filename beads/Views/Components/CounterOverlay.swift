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
            // 頂部列 — 咒語名稱
            HStack {
                Text(mantraName)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer()

            // 底部區域 — 計數、圈數與統計
            VStack(spacing: 12) {
                // 計數與圈數
                HStack(spacing: 0) {
                    // 總計數
                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.system(size: 48, weight: .thin, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("總計數")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(width: 80)

                    // 分隔線
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 1, height: 40)

                    // 圈數
                    VStack(spacing: 4) {
                        Text("\(rounds)")
                            .font(.system(size: 48, weight: .thin, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("圈")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(width: 80)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // 統計列 — 今日計數與連續天數
                HStack {
                    Label("今日：\(todayCount)", systemImage: "sun.min")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Label("\(streakDays) 天", systemImage: "flame")
                        .font(.footnote)
                        .foregroundStyle(.orange.opacity(0.9))
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)
        }
    }
}
