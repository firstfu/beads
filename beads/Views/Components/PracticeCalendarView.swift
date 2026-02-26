// MARK: - 檔案說明
/// PracticeCalendarView.swift
/// 修行日曆視圖 - 以熱力圖形式顯示近 35 天的修行記錄
/// 模組：Views/Components

//
//  PracticeCalendarView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI

/// 修行日曆視圖
/// 以 7 欄 x 5 列的格狀熱力圖顯示近 35 天的每日修行記錄，
/// 顏色深淺代表當日念誦數量的多寡
struct PracticeCalendarView: View {
    /// 每日修行記錄的陣列
    let records: [DailyRecord]

    /// 視圖主體
    var body: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        VStack(alignment: .leading, spacing: 4) {
            Text("修行日曆")
                .font(.headline)
                .padding(.bottom, 4)

            // 7 欄格狀熱力圖，顯示最近 35 天的修行記錄
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 3) {
                ForEach(0..<35, id: \.self) { offset in
                    let date = calendar.date(byAdding: .day, value: -(34 - offset), to: today)!
                    let count = records.first {
                        calendar.startOfDay(for: $0.date) == calendar.startOfDay(for: date)
                    }?.totalCount ?? 0

                    RoundedRectangle(cornerRadius: 3)
                        .fill(heatColor(for: count))
                        .frame(height: 20)
                }
            }

            // 圖例 — 顯示顏色深淺對應的數量等級
            HStack(spacing: 4) {
                Text("少")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach([0, 50, 200, 500, 1000], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatColor(for: level))
                        .frame(width: 12, height: 12)
                }
                Text("多")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    /// 根據念誦數量計算熱力圖顏色
    /// 數量越多顏色越深（橘色），無記錄則顯示灰色
    /// - Parameter count: 當日念誦數量
    /// - Returns: 對應的顏色
    private func heatColor(for count: Int) -> Color {
        switch count {
        case 0: return Color.white.opacity(0.1)
        case 1..<100: return Color.orange.opacity(0.3)
        case 100..<300: return Color.orange.opacity(0.5)
        case 300..<600: return Color.orange.opacity(0.7)
        default: return Color.orange.opacity(0.95)
        }
    }
}
