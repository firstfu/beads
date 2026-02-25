// MARK: - 檔案說明
/// DailyRecordTests.swift
/// 每日修行記錄模型測試 - 驗證 DailyRecord 的建立、新增場次和累計統計功能
/// 模組：beadsTests/Models

//
//  DailyRecordTests.swift
//  beadsTests
//
//  Created by firstfu on 2026/2/24.
//

import Testing
import Foundation
@testable import beads

/// 每日修行記錄的單元測試
/// 測試 DailyRecord 模型的初始化、單次場次新增和多次場次累計功能
struct DailyRecordTests {
    /// 測試建立每日記錄的初始狀態
    /// 驗證新建立的記錄其計數、時長和場次數皆為零
    @Test func createDailyRecord() async throws {
        let record = DailyRecord(date: Date())
        #expect(record.totalCount == 0)
        #expect(record.totalDuration == 0)
        #expect(record.sessionCount == 0)
    }

    /// 測試新增單次修行場次到每日記錄
    /// 驗證新增一次 108 顆、300 秒的場次後，各欄位數值正確
    @Test func addSessionToRecord() async throws {
        let record = DailyRecord(date: Date())
        record.addSession(count: 108, duration: 300)
        #expect(record.totalCount == 108)
        #expect(record.totalDuration == 300)
        #expect(record.sessionCount == 1)
    }

    /// 測試新增多次修行場次的累計計算
    /// 驗證連續新增兩次場次後，計數、時長和場次數正確累加
    @Test func multipleSessions() async throws {
        let record = DailyRecord(date: Date())
        record.addSession(count: 108, duration: 300)
        record.addSession(count: 216, duration: 600)
        #expect(record.totalCount == 324)
        #expect(record.totalDuration == 900)
        #expect(record.sessionCount == 2)
    }
}
