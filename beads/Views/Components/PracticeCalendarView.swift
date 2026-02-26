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

/// 禪意金色常數
private let zenGold = Color(red: 0.83, green: 0.66, blue: 0.29)

/// 修行日曆視圖
/// 以 7 欄 x 5 列的格狀熱力圖顯示近 35 天的每日修行記錄，
/// 顏色深淺代表當日念誦數量的多寡
struct PracticeCalendarView: View {
    /// 每日修行記錄的陣列
    let records: [DailyRecord]

    /// 星期標籤
    private let weekdayLabels = ["日", "一", "二", "三", "四", "五", "六"]

    /// 視圖主體
    var body: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        VStack(alignment: .leading, spacing: 8) {
            // 星期標籤列
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }

            // 7 欄格狀熱力圖，顯示最近 35 天的修行記錄
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<35, id: \.self) { offset in
                    let date = calendar.date(byAdding: .day, value: -(34 - offset), to: today)!
                    let dateStart = calendar.startOfDay(for: date)
                    let count = records.first {
                        calendar.startOfDay(for: $0.date) == dateStart
                    }?.totalCount ?? 0
                    let isToday = dateStart == today

                    RoundedRectangle(cornerRadius: 4)
                        .fill(heatColor(for: count))
                        .frame(height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(
                                    isToday ? zenGold : .clear,
                                    lineWidth: 1.5
                                )
                        )
                }
            }

            // 圖例 — 水平漸層條
            HStack(spacing: 6) {
                Text("少")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                zenGold.opacity(0.3),
                                zenGold.opacity(0.5),
                                zenGold.opacity(0.7),
                                zenGold.opacity(0.95)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 100, height: 10)
                Text("多")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    /// 根據念誦數量計算熱力圖顏色
    /// 使用金色/琥珀色漸層，與禪意主題一致
    /// - Parameter count: 當日念誦數量
    /// - Returns: 對應的顏色
    private func heatColor(for count: Int) -> Color {
        switch count {
        case 0: return Color.white.opacity(0.08)
        case 1..<100: return zenGold.opacity(0.25)
        case 100..<300: return zenGold.opacity(0.45)
        case 300..<600: return zenGold.opacity(0.65)
        default: return zenGold.opacity(0.9)
        }
    }
}
