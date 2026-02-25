//
//  PracticeView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI
import SwiftData

struct PracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PracticeViewModel()
    @State private var sceneManager = BeadSceneManager()
    @State private var hapticService = HapticService()
    @State private var audioService = AudioService()
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            // 3D Bead Scene
            BeadSceneView(sceneManager: sceneManager, onBeadAdvance: {
                onBeadAdvance()
            })
            .ignoresSafeArea()

            // Counter overlay
            CounterOverlay(
                count: viewModel.count,
                rounds: viewModel.rounds,
                todayCount: viewModel.todayCount + viewModel.count,
                streakDays: viewModel.streakDays,
                mantraName: viewModel.mantraName
            )
        }
        .onAppear {
            viewModel.startSession(mantraName: "南無阿彌陀佛")
            viewModel.loadTodayStats(modelContext: modelContext)
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
        }
        .onDisappear {
            viewModel.endSession(modelContext: modelContext)
            audioService.fadeOutAmbient()
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
        .alert("確定要重置計數嗎？", isPresented: $showResetConfirm) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                viewModel.resetCount()
                sceneManager.currentBeadIndex = 0
            }
        } message: {
            Text("此操作將清除本次修行的所有計數。")
        }
    }

    private func onBeadAdvance() {
        viewModel.incrementBead()
        sceneManager.currentBeadIndex = viewModel.currentBeadIndex
        hapticService.playBeadTap()
        audioService.playBeadClick()

        if viewModel.didCompleteRound {
            hapticService.playRoundComplete()
            audioService.playRoundComplete()
        }
    }
}

#Preview {
    PracticeView()
}
