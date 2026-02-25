//
//  RecordsView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI
import SwiftData
import Charts

struct RecordsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Today stats
                    HStack(spacing: 12) {
                        StatsCardView(
                            title: "今日計數",
                            value: "\(viewModel.todayCount)",
                            subtitle: "\(viewModel.todaySessions) 次修行",
                            icon: "sun.min"
                        )
                        StatsCardView(
                            title: "連續修行",
                            value: "\(viewModel.streakDays) 天",
                            subtitle: "持續精進",
                            icon: "flame"
                        )
                    }

                    // Weekly chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("本週修行")
                            .font(.headline)

                        Chart(viewModel.weeklyData, id: \.date) { item in
                            BarMark(
                                x: .value("日期", item.date, unit: .day),
                                y: .value("計數", item.count)
                            )
                            .foregroundStyle(Color.orange.gradient)
                            .cornerRadius(4)
                        }
                        .frame(height: 180)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Calendar heatmap
                    PracticeCalendarView(records: viewModel.monthlyRecords)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Duration
                    StatsCardView(
                        title: "今日時長",
                        value: formatDuration(viewModel.todayDuration),
                        subtitle: "專注修行",
                        icon: "clock"
                    )
                }
                .padding()
            }
            .navigationTitle("記錄")
            .onAppear {
                viewModel.load(modelContext: modelContext)
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes < 60 {
            return "\(minutes) 分鐘"
        }
        let hours = minutes / 60
        let remaining = minutes % 60
        return "\(hours) 小時 \(remaining) 分"
    }
}

#Preview {
    RecordsView()
}
