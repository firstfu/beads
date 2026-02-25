// MARK: - 檔案說明
/// beadsUITestsLaunchTests.swift
/// 啟動畫面測試 - 驗證應用程式啟動流程並擷取啟動畫面截圖
/// 模組：beadsUITests

//
//  beadsUITestsLaunchTests.swift
//  beadsUITests
//
//  Created by firstfu on 2026/2/24.
//

import XCTest

/// 應用程式啟動畫面的測試類別
/// 針對每個目標應用程式 UI 設定執行啟動測試，並擷取啟動畫面截圖作為附件
final class beadsUITestsLaunchTests: XCTestCase {

    /// 是否針對每個目標應用程式 UI 設定執行測試
    /// 回傳 true 表示此測試會在所有 UI 設定組合下執行
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    /// 每個測試方法執行前的設定
    /// 設定失敗時立即停止測試
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 啟動畫面測試
    /// 啟動應用程式後擷取螢幕截圖，並儲存為永久保留的測試附件
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
