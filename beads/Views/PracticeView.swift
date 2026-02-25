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
    @Query private var allSettings: [UserSettings]
    private var displayMode: BeadDisplayMode {
        if let raw = allSettings.first?.displayMode {
            return BeadDisplayMode(rawValue: raw) ?? .circular
        }
        return .circular
    }

    @State private var viewModel = PracticeViewModel()
    @State private var sceneManager = BeadSceneManager()
    @State private var verticalSceneManager = VerticalBeadSceneManager()
    @State private var hapticService = HapticService()
    @State private var audioService = AudioService()
    @State private var showResetConfirm = false
    @State private var showMeritPopup = false
    @State private var meritPopupOffset: CGFloat = 0
    @State private var meritPopupOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // 3D Bead Scene - switch based on display mode
            if displayMode == .vertical {
                VerticalBeadSceneView(sceneManager: verticalSceneManager, onBeadAdvance: {
                    onBeadAdvance()
                })
                .ignoresSafeArea()
            } else {
                BeadSceneView(sceneManager: sceneManager, onBeadAdvance: {
                    onBeadAdvance()
                })
                .ignoresSafeArea()
            }

            // Counter overlay (same for both modes)
            CounterOverlay(
                count: viewModel.count,
                rounds: viewModel.rounds,
                todayCount: viewModel.todayCount + viewModel.count,
                streakDays: viewModel.streakDays,
                mantraName: viewModel.mantraName
            )

            // Merit popup "功德+1"
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
            viewModel.startSession(mantraName: "南無阿彌陀佛")
            viewModel.loadTodayStats(modelContext: modelContext)
            if let settings = allSettings.first, settings.ambientSoundEnabled {
                audioService.isAmbientEnabled = true
                audioService.ambientVolume = settings.ambientVolume
                audioService.startAmbient(named: settings.selectedAmbientTrack)
            } else {
                audioService.isAmbientEnabled = false
            }
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
                verticalSceneManager.currentBeadIndex = 0
            }
        } message: {
            Text("此操作將清除本次修行的所有計數。")
        }
    }

    private func onBeadAdvance() {
        viewModel.incrementBead()
        sceneManager.currentBeadIndex = viewModel.currentBeadIndex
        verticalSceneManager.currentBeadIndex = viewModel.currentBeadIndex
        hapticService.playBeadTap()
        audioService.playBeadClick()

        if viewModel.didCompleteRound {
            hapticService.playRoundComplete()
            audioService.playRoundComplete()
        }

        // Show merit popup animation
        withAnimation(.easeOut(duration: 0.8)) {
            showMeritPopup = true
            meritPopupOffset = -50
            meritPopupOpacity = 0
        }
        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            showMeritPopup = false
            meritPopupOffset = 0
            meritPopupOpacity = 1.0
        }
    }
}

#Preview {
    PracticeView()
}
