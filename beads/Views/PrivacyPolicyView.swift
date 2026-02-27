// MARK: - 檔案說明
/// PrivacyPolicyView.swift
/// 隱私權政策頁面 - App Store 上架必要的隱私權政策說明
/// 模組：Views

//
//  PrivacyPolicyView.swift
//  beads
//
//  Created on 2026/2/27.
//

import SwiftUI
import SwiftData

/// 隱私權政策視圖
struct PrivacyPolicyView: View {
    @Query private var allSettings: [UserSettings]

    private var currentBackgroundTheme: ZenBackgroundTheme {
        if let raw = allSettings.first?.backgroundTheme {
            return ZenBackgroundTheme(rawValue: raw) ?? .inkWash
        }
        return .inkWash
    }

    var body: some View {
        ZStack {
            ZenBackgroundView(theme: currentBackgroundTheme, enableLotusDecoration: false)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("隱私權政策")
                            .font(.title2.bold())

                        Text("最後更新日期：2026 年 2 月 27 日")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        sectionView(title: "資料收集", content: """
                        「靜心念珠」不會收集、傳輸或儲存任何個人資料至外部伺服器。您的所有修行紀錄、設定偏好及迴向資料皆僅儲存於您的裝置本機。
                        """)

                        sectionView(title: "本機資料儲存", content: """
                        本 App 使用 Apple SwiftData 框架將資料儲存於您的裝置上。這些資料包括：
                        • 修行場次紀錄（念誦次數、時間、圈數）
                        • 每日修行統計
                        • 迴向紀錄
                        • 使用者偏好設定（佛珠樣式、音效、顯示模式等）

                        您可以隨時在「設定 → 資料管理」中清除所有修行紀錄。
                        """)

                        sectionView(title: "iCloud 同步", content: """
                        若您已啟用 iCloud，部分資料可能會透過 Apple iCloud 服務在您的裝置間同步。此同步完全由 Apple 管理，受 Apple 隱私權政策保護。本 App 開發者無法存取您的 iCloud 資料。
                        """)

                        sectionView(title: "第三方服務", content: """
                        本 App 不使用任何第三方分析工具、廣告服務或追蹤技術。不會與任何第三方分享您的資料。
                        """)

                        sectionView(title: "兒童隱私", content: """
                        本 App 不針對 13 歲以下兒童收集任何資訊。
                        """)

                        sectionView(title: "政策變更", content: """
                        若本隱私權政策有所更新，我們將在 App 內公告修改內容。繼續使用本 App 即表示您同意更新後的政策。
                        """)

                        sectionView(title: "聯絡我們", content: """
                        如有任何隱私權相關問題，請透過以下方式聯絡：
                        電子郵件：first.fu@gmail.com
                        """)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("隱私權政策")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionView(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
    .modelContainer(for: UserSettings.self, inMemory: true)
}
