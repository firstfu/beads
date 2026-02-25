// MARK: - 檔案說明
/// PracticeSessionTests.swift
/// 修行場次模型測試 - 驗證 PracticeSession 的建立、計數、回合和時間計算功能
/// 模組：beadsTests/Models

//
//  PracticeSessionTests.swift
//  beadsTests
//
//  Created by firstfu on 2026/2/24.
//

import Testing
import Foundation
@testable import beads

/// 修行場次模型的單元測試
/// 測試 PracticeSession 模型的初始化、計數遞增、回合完成、念珠位置和時長計算
struct PracticeSessionTests {
    /// 測試建立修行場次的初始狀態
    /// 驗證新建場次的咒語名稱、每回合數量、計數、回合數和啟動狀態皆正確
    @Test func createSession() async throws {
        let session = PracticeSession(mantraName: "南無阿彌陀佛", beadsPerRound: 108)
        #expect(session.mantraName == "南無阿彌陀佛")
        #expect(session.beadsPerRound == 108)
        #expect(session.count == 0)
        #expect(session.rounds == 0)
        #expect(session.isActive == false)
    }

    /// 測試計數遞增功能
    /// 驗證執行一次遞增後，計數為 1 且尚未完成回合
    @Test func incrementCount() async throws {
        let session = PracticeSession(mantraName: "南無阿彌陀佛", beadsPerRound: 108)
        session.increment()
        #expect(session.count == 1)
        #expect(session.rounds == 0)
    }

    /// 測試回合完成判定
    /// 以每回合 3 顆念珠為例，驗證計數達到 3 時正確標記為完成一個回合
    @Test func completesRound() async throws {
        let session = PracticeSession(mantraName: "南無阿彌陀佛", beadsPerRound: 3)
        session.increment()
        session.increment()
        session.increment()
        #expect(session.count == 3)
        #expect(session.rounds == 1)
    }

    /// 測試念珠在本回合中的位置索引
    /// 驗證初始位置為 0，遞增一次後位置為 1
    @Test func currentBeadPosition() async throws {
        let session = PracticeSession(mantraName: "南無阿彌陀佛", beadsPerRound: 108)
        #expect(session.currentBeadIndex == 0)
        session.increment()
        #expect(session.currentBeadIndex == 1)
    }

    /// 測試修行場次的時長計算
    /// 設定開始和結束時間間隔 60 秒，驗證計算出的時長在合理範圍內
    @Test func sessionDuration() async throws {
        let session = PracticeSession(mantraName: "南無阿彌陀佛", beadsPerRound: 108)
        session.startTime = Date().addingTimeInterval(-60)
        session.endTime = Date()
        #expect(session.duration >= 59 && session.duration <= 61)
    }
}
