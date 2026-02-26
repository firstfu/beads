// MARK: - 檔案說明
/// PracticeViewModelTests.swift
/// 修行視圖模型測試 - 驗證 PracticeViewModel 的初始狀態、場次管理、計數、回合和撤銷功能
/// 模組：beadsTests/ViewModels

//
//  PracticeViewModelTests.swift
//  beadsTests
//
//  Created by firstfu on 2026/2/24.
//

import Testing
import Foundation
@testable import beads

/// 修行視圖模型的單元測試
/// 測試 PracticeViewModel 的初始化、場次啟動、念珠撥動、回合完成、撤銷操作和統計初始值
struct PracticeViewModelTests {
    /// 測試視圖模型的初始狀態
    /// 驗證新建立的視圖模型各屬性皆為預設值
    @Test func initialState() async throws {
        let vm = PracticeViewModel()
        #expect(vm.count == 0)
        #expect(vm.rounds == 0)
        #expect(vm.currentBeadIndex == 0)
        #expect(vm.isActive == false)
        #expect(vm.beadsPerRound == 108)
    }

    /// 測試開始修行場次
    /// 驗證呼叫 startSession 後，場次變為啟動狀態且咒語名稱正確設定
    @Test func startSession() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "南無阿彌陀佛")
        #expect(vm.isActive == true)
        #expect(vm.mantraName == "南無阿彌陀佛")
    }

    /// 測試念珠撥動計數
    /// 驗證撥動一次後計數和念珠位置索引皆為 1
    @Test func incrementBead() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "南無阿彌陀佛")
        vm.incrementBead()
        #expect(vm.count == 1)
        #expect(vm.currentBeadIndex == 1)
    }

    /// 測試回合完成判定
    /// 以每回合 3 顆念珠為例，驗證撥動 3 次後完成一個回合
    @Test func roundCompletion() async throws {
        let vm = PracticeViewModel()
        vm.beadsPerRound = 3
        vm.startSession(mantraName: "test")
        vm.incrementBead()
        vm.incrementBead()
        vm.incrementBead()
        #expect(vm.rounds == 1)
        #expect(vm.didCompleteRound == true)
    }

    /// 測試撤銷上一次撥動
    /// 驗證撥動 3 次後撤銷 1 次，計數恢復為 2
    @Test func undoLastIncrement() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "test")
        vm.incrementBead()
        vm.incrementBead()
        vm.incrementBead()
        vm.undo()
        #expect(vm.count == 2)
    }

    /// 測試撤銷操作的邊界情況
    /// 驗證撥動 1 次後連續撤銷 2 次，計數不會低於 0
    @Test func undoLimit() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "test")
        vm.incrementBead()
        vm.undo()
        vm.undo()
        #expect(vm.count == 0)
    }

    /// 測試今日計數的初始值
    /// 驗證新建立的視圖模型今日計數為 0
    @Test func todayCount() async throws {
        let vm = PracticeViewModel()
        #expect(vm.todayCount == 0)
    }

    /// 測試連續修行天數的初始值
    /// 驗證新建立的視圖模型連續天數為 0
    @Test func streakDays() async throws {
        let vm = PracticeViewModel()
        #expect(vm.streakDays == 0)
    }

    @Test func endSessionWithDedicationParamsExist() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "南無阿彌陀佛")
        vm.incrementBead()
        vm.incrementBead()
        #expect(vm.count == 2)
        #expect(vm.isActive == true)
    }

    @Test func endSessionSkipsDedicationByDefault() async throws {
        let vm = PracticeViewModel()
        vm.startSession(mantraName: "test")
        vm.incrementBead()
        #expect(vm.isActive == true)
    }
}
