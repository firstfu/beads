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

/// 禪意金色常數，與 ZenBackgroundView glow 色一致
private let zenGold = Color(red: 0.83, green: 0.66, blue: 0.29)

/// 修行記錄視圖，展示今日統計、連續修行天數、本週長條圖、月曆熱力圖及修行時長
struct RecordsView: View {
    /// SwiftData 模型上下文，用於查詢修行紀錄資料
    @Environment(\.modelContext) private var modelContext
    /// 從 SwiftData 查詢所有使用者設定
    @Query private var allSettings: [UserSettings]
    /// 查詢所有有迴向的修行場次
    @Query(filter: #Predicate<PracticeSession> { $0.hasDedication == true },
           sort: \PracticeSession.endTime, order: .reverse)
    private var dedicatedSessions: [PracticeSession]
    /// 統計資料的 ViewModel，負責載入並計算各項統計數據
    @State private var viewModel = StatsViewModel()
    /// 出場動畫狀態
    @State private var appeared = false

    /// 目前的背景主題，從使用者設定中取得
    private var currentBackgroundTheme: ZenBackgroundTheme {
        if let raw = allSettings.first?.backgroundTheme {
            return ZenBackgroundTheme(rawValue: raw) ?? .inkWash
        }
        return .inkWash
    }

    /// 本週總計
    private var weeklyTotal: Int {
        viewModel.weeklyData.reduce(0) { $0 + $1.count }
    }

    /// 主視圖內容，以捲動清單呈現各項修行統計卡片與圖表
    var body: some View {
        NavigationStack {
            ZStack {
                ZenBackgroundView(theme: currentBackgroundTheme, enableLotusDecoration: false)
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - 頂部摘要區
                        todaySummarySection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)

                        // MARK: - 三欄統計卡
                        threeColumnStats
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)

                        // MARK: - 本週修行長條圖
                        weeklyChartSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

                        // MARK: - 月曆熱力圖
                        calendarSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                            .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

                        // MARK: - 迴向紀錄
                        if !dedicatedSessions.isEmpty {
                            dedicationSection
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 15)
                                .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("記錄")
            .onAppear {
                viewModel.load(modelContext: modelContext)
                withAnimation(.easeOut(duration: 0.5)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - 頂部摘要區

    /// 大字體的總計數展示 + 圓形漸層背景
    private var todaySummarySection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [zenGold.opacity(0.3), zenGold.opacity(0.05)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                Text("\(viewModel.todayCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(zenGold)
            }
            Text("今日念誦")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
        .animation(.easeOut(duration: 0.5), value: appeared)
    }

    // MARK: - 三欄統計卡

    /// 將「今日計數」「連續修行」「今日時長」改為三欄橫排
    private var threeColumnStats: some View {
        HStack(spacing: 10) {
            StatsCardView(
                title: "今日計數",
                value: "\(viewModel.todayCount)",
                subtitle: "\(viewModel.todaySessions) 次修行",
                icon: "sun.min",
                accentColor: zenGold
            )
            StatsCardView(
                title: "連續修行",
                value: "\(viewModel.streakDays) 天",
                subtitle: "持續精進",
                icon: "flame",
                accentColor: Color.orange
            )
            StatsCardView(
                title: "今日時長",
                value: formatDuration(viewModel.todayDuration),
                subtitle: "專注修行",
                icon: "clock",
                accentColor: Color(red: 0.4, green: 0.6, blue: 0.85)
            )
        }
    }

    // MARK: - 本週修行長條圖

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 裝飾性段落標題
            sectionHeader("本週修行")

            Chart(viewModel.weeklyData, id: \.date) { item in
                let isToday = Calendar.current.isDateInToday(item.date)
                BarMark(
                    x: .value("日期", item.date, unit: .day),
                    y: .value("計數", item.count)
                )
                .foregroundStyle(
                    isToday
                        ? LinearGradient(colors: [zenGold, zenGold.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [zenGold.opacity(0.6), zenGold.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                }
            }

            // 本週總計
            HStack {
                Spacer()
                Text("本週共計 \(weeklyTotal) 次")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 月曆熱力圖

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("修行日曆")

            PracticeCalendarView(records: viewModel.monthlyRecords)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 迴向紀錄區塊

    /// 迴向紀錄摘要卡片，點擊導航至完整迴向歷史列表
    private var dedicationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("迴向紀錄")

            NavigationLink(destination: DedicationHistoryView()) {
                HStack(spacing: 14) {
                    // 左側圖示
                    Image(systemName: "hands.and.sparkles")
                        .font(.title2)
                        .foregroundStyle(zenGold)
                        .frame(width: 40, height: 40)
                        .background(zenGold.opacity(0.15))
                        .clipShape(Circle())

                    // 中間資訊
                    VStack(alignment: .leading, spacing: 4) {
                        Text("共 \(dedicatedSessions.count) 次迴向")
                            .font(.subheadline.weight(.medium))
                        if let latest = dedicatedSessions.first {
                            Text("最近：\(latest.dedicationTarget ?? "迴向法界眾生")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 裝飾性段落標題

    /// 左側小圓點 + 文字的段落標題
    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(zenGold)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.headline)
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
