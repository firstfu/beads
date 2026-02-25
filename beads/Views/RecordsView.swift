// MARK: - 檔案說明
/// RecordsView.swift
/// 記錄畫面 - 顯示修行統計數據、週報長條圖、月曆熱力圖及修行時長
/// 模組：Views

//
//  RecordsView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI
import SwiftData
import Charts

/// 修行記錄視圖，展示今日統計、連續修行天數、本週長條圖、月曆熱力圖及修行時長
struct RecordsView: View {
    /// SwiftData 模型上下文，用於查詢修行紀錄資料
    @Environment(\.modelContext) private var modelContext
    /// 統計資料的 ViewModel，負責載入並計算各項統計數據
    @State private var viewModel = StatsViewModel()

    /// 主視圖內容，以捲動清單呈現各項修行統計卡片與圖表
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 今日統計卡片
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

                    // 本週修行長條圖
                    VStack(alignment: .leading, spacing: 8) {
                        Text("本週修行")
                            .font(.headline)

                        Chart(viewModel.weeklyData, id: \.date) { item in
                            BarMark(
                                x: .value("日期", item.date, unit: .day),
                                y: .value("計數", item.count)
                            )
                            .foregroundStyle(BeadsTheme.Colors.accent.gradient)
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
                    .background(BeadsTheme.Colors.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // 月曆熱力圖
                    PracticeCalendarView(records: viewModel.monthlyRecords)
                        .padding()
                        .background(BeadsTheme.Colors.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // 今日修行時長卡片
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

    /// 將秒數格式化為可讀的時間字串
    /// - Parameter seconds: 時間長度（秒）
    /// - Returns: 格式化後的字串，例如「30 分鐘」或「1 小時 15 分」
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
