//
//  PracticeCalendarView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI

struct PracticeCalendarView: View {
    let records: [DailyRecord]

    var body: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        VStack(alignment: .leading, spacing: 4) {
            Text("修行日曆")
                .font(.headline)
                .padding(.bottom, 4)

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

    private func heatColor(for count: Int) -> Color {
        switch count {
        case 0: return Color(.systemGray5)
        case 1..<100: return Color.orange.opacity(0.3)
        case 100..<300: return Color.orange.opacity(0.5)
        case 300..<600: return Color.orange.opacity(0.7)
        default: return Color.orange.opacity(0.95)
        }
    }
}
