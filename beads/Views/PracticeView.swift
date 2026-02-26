// MARK: - 檔案說明
/// PracticeView.swift
/// 修行畫面 - 顯示 3D 佛珠場景、計數器覆蓋層及功德彈出動畫
/// 模組：Views

//
//  PracticeView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI
import SwiftData

/// 修行主視圖，整合 3D 佛珠場景、撥珠計數、觸感回饋與音效播放
struct PracticeView: View {
    /// SwiftData 模型上下文，用於讀寫修行紀錄
    @Environment(\.modelContext) private var modelContext
    /// 從 SwiftData 查詢所有使用者設定
    @Query private var allSettings: [UserSettings]
    /// 目前的佛珠顯示模式（環形或直列），從使用者設定中取得
    private var displayMode: BeadDisplayMode {
        if let raw = allSettings.first?.displayMode {
            return BeadDisplayMode(rawValue: raw) ?? .vertical
        }
        return .vertical
    }
    /// 是否啟用快速撥珠模式，從使用者設定中取得
    private var fastScrollMode: Bool {
        allSettings.first?.fastScrollMode ?? false
    }
    /// 目前的佛珠材質類型，從使用者設定中取得
    private var currentMaterialType: BeadMaterialType {
        if let raw = allSettings.first?.currentBeadStyle {
            return BeadMaterialType(rawValue: raw) ?? .zitan
        }
        return .zitan
    }
    /// 目前的背景主題，從使用者設定中取得
    private var currentBackgroundTheme: ZenBackgroundTheme {
        if let raw = allSettings.first?.backgroundTheme {
            return ZenBackgroundTheme(rawValue: raw) ?? .inkWash
        }
        return .inkWash
    }
    /// 目前每圈珠數，從使用者設定中取得
    private var currentBeadsPerRound: Int {
        allSettings.first?.beadsPerRound ?? 108
    }

    /// 修行邏輯的 ViewModel，管理計數、回合數等狀態
    @State private var viewModel = PracticeViewModel()
    /// 環形佛珠 3D 場景管理器
    @State private var sceneManager = BeadSceneManager()
    /// 直列佛珠 3D 場景管理器
    @State private var verticalSceneManager = VerticalBeadSceneManager()
    /// 手串佛珠 3D 場景管理器
    @State private var braceletSceneManager = BraceletBeadSceneManager()
    /// 觸感回饋服務，負責撥珠和完成回合時的震動回饋
    @State private var hapticService = HapticService()
    /// 音訊服務實例，從環境中注入，用於播放撥珠音效和背景音樂
    @Environment(AudioService.self) private var audioService
    /// 是否顯示重置確認對話框
    @State private var showResetConfirm = false
    /// 是否顯示「功德+1」彈出動畫
    @State private var showMeritPopup = false
    /// 功德彈出文字的垂直偏移量（用於上浮動畫）
    @State private var meritPopupOffset: CGFloat = 0
    /// 功德彈出文字的透明度（用於淡出動畫）
    @State private var meritPopupOpacity: Double = 1.0

    /// 主視圖內容，根據顯示模式切換環形或直列佛珠場景，並疊加計數器與功德動畫
    var body: some View {
        ZStack {
            // 背景層：禪意背景
            ZenBackgroundView(theme: currentBackgroundTheme, isCircularLayout: displayMode == .circular || displayMode == .bracelet)

            // 3D 佛珠場景 - 根據顯示模式切換
            beadSceneContent

            // 計數器覆蓋層（兩種模式共用）
            CounterOverlay(
                count: viewModel.count,
                rounds: viewModel.rounds,
                todayCount: viewModel.todayCount + viewModel.count,
                streakDays: viewModel.streakDays,
                mantraName: viewModel.mantraName
            )
            .allowsHitTesting(false)

            // 「功德+1」彈出動畫
            if showMeritPopup {
                Text("功德+1")
                    .font(.title3.bold())
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 8)
                    .offset(y: meritPopupOffset)
                    .opacity(meritPopupOpacity)
            }
        }
        .onAppear {
            // 同步珠數設定（必須在場景管理器初始化之前）
            let beadCount = currentBeadsPerRound
            viewModel.beadsPerRound = beadCount
            sceneManager = BeadSceneManager(beadCount: beadCount)
            verticalSceneManager = VerticalBeadSceneManager(beadCount: beadCount)
            braceletSceneManager = BraceletBeadSceneManager(beadCount: beadCount)

            sceneManager.materialType = currentMaterialType
            verticalSceneManager.materialType = currentMaterialType
            braceletSceneManager.materialType = currentMaterialType
            viewModel.startSession(mantraName: "南無阿彌陀佛")
            viewModel.loadTodayStats(modelContext: modelContext)
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
        }
        .onDisappear {
            viewModel.endSession(modelContext: modelContext)
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
        .onChange(of: allSettings.first?.currentBeadStyle) {
            sceneManager.materialType = currentMaterialType
            verticalSceneManager.materialType = currentMaterialType
            braceletSceneManager.materialType = currentMaterialType
        }
        .onChange(of: allSettings.first?.beadsPerRound) {
            let beadCount = currentBeadsPerRound
            viewModel.updateBeadsPerRound(beadCount)

            // 場景管理器的 beadCount 是 let，需要重建實例
            let material = currentMaterialType
            sceneManager = BeadSceneManager(beadCount: beadCount)
            sceneManager.materialType = material
            verticalSceneManager = VerticalBeadSceneManager(beadCount: beadCount)
            verticalSceneManager.materialType = material
            braceletSceneManager = BraceletBeadSceneManager(beadCount: beadCount)
            braceletSceneManager.materialType = material
        }
        .alert("確定要重置計數嗎？", isPresented: $showResetConfirm) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                viewModel.resetCount()
                sceneManager.currentBeadIndex = 0
                verticalSceneManager.currentBeadIndex = 0
                braceletSceneManager.currentBeadIndex = 0
            }
        } message: {
            Text("此操作將清除本次修行的所有計數。")
        }
    }

    // MARK: - 場景內容

    /// 根據顯示模式回傳對應的佛珠場景視圖
    @ViewBuilder
    private var beadSceneContent: some View {
        switch displayMode {
        case .vertical:
            VerticalBeadSceneView(sceneManager: verticalSceneManager, onBeadAdvance: {
                onBeadAdvance()
            }, fastScrollMode: fastScrollMode)
            .ignoresSafeArea()
        case .circular:
            BeadSceneView(sceneManager: sceneManager, onBeadAdvance: {
                onBeadAdvance()
            }, fastScrollMode: fastScrollMode)
            .ignoresSafeArea()
        case .bracelet:
            BraceletBeadSceneView(sceneManager: braceletSceneManager, onBeadAdvance: {
                onBeadAdvance()
            }, fastScrollMode: fastScrollMode)
            .ignoresSafeArea()
        }
    }

    /// 處理撥珠前進事件
    /// - 增加計數並同步佛珠索引至兩個場景管理器
    /// - 觸發觸感回饋和撥珠音效
    /// - 若完成一圈，額外觸發完成回合的回饋與音效
    /// - 顯示「功德+1」上浮淡出動畫
    private func onBeadAdvance() {
        viewModel.incrementBead()
        sceneManager.currentBeadIndex = viewModel.currentBeadIndex
        verticalSceneManager.currentBeadIndex = viewModel.currentBeadIndex
        braceletSceneManager.currentBeadIndex = viewModel.currentBeadIndex
        hapticService.playBeadTap()
        audioService.playBeadClick()

        if viewModel.didCompleteRound {
            verticalSceneManager.resetColumnPosition()
            hapticService.playRoundComplete()
            audioService.playRoundComplete()
        }

        // 顯示功德彈出動畫
        withAnimation(.easeOut(duration: 0.8)) {
            showMeritPopup = true
            meritPopupOffset = -50
            meritPopupOpacity = 0
        }
        // 動畫結束後重置狀態
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            showMeritPopup = false
            meritPopupOffset = 0
            meritPopupOpacity = 1.0
        }
    }
}

#Preview {
    PracticeView()
        .environment(AudioService())
}
