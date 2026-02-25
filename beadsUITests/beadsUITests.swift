// MARK: - 檔案說明
/// beadsUITests.swift
/// UI 測試檔案 - 包含應用程式的使用者介面測試和啟動效能測試
/// 模組：beadsUITests

//
//  beadsUITests.swift
//  beadsUITests
//
//  Created by firstfu on 2026/2/24.
//

import XCTest

/// 應用程式的 UI 測試類別
/// 使用 XCTest 框架進行使用者介面的自動化測試
final class beadsUITests: XCTestCase {

    /// 每個測試方法執行前的設定
    /// 配置測試環境，設定失敗時立即停止以及初始介面狀態
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    /// 每個測試方法執行後的清理
    /// 釋放測試資源並還原環境狀態
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// 範例 UI 測試
    /// 啟動應用程式並驗證基本的使用者介面行為
    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    /// 應用程式啟動效能測試
    /// 測量應用程式從啟動到可用狀態所需的時間
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
