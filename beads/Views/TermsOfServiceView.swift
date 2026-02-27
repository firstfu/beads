// MARK: - 檔案說明
/// TermsOfServiceView.swift
/// 使用條款頁面 - App Store 上架必要的使用條款說明
/// 模組：Views

//
//  TermsOfServiceView.swift
//  beads
//
//  Created on 2026/2/27.
//

import SwiftUI
import SwiftData

/// 使用條款視圖
struct TermsOfServiceView: View {
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
                        Text("使用條款")
                            .font(.title2.bold())

                        Text("最後更新日期：2026 年 2 月 27 日")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        sectionView(title: "服務說明", content: """
                        「靜心念珠」是一款免費的數位念珠修行輔助工具，旨在幫助使用者進行念佛、持咒、冥想等修行活動。本 App 提供虛擬念珠計數、修行紀錄統計、迴向功德等功能。
                        """)

                        sectionView(title: "使用授權", content: """
                        本 App 免費提供使用，您可以自由下載並用於個人修行用途。您不得對本 App 進行反向工程、反編譯或試圖提取原始碼。
                        """)

                        sectionView(title: "內容來源", content: """
                        本 App 中收錄的佛教經典、咒語及迴向文內容源自公共領域的佛教典籍，為佛教傳統的共同智慧遺產。背景音樂部分採用創用 CC 授權或原創音樂。
                        """)

                        sectionView(title: "免責聲明", content: """
                        本 App 僅為修行輔助工具，不構成任何宗教指導或建議。開發者不對使用本 App 所產生的任何直接或間接影響承擔責任。

                        本 App 以「現狀」提供，不作任何明示或暗示的保證。開發者不保證 App 將不間斷、無錯誤或完全安全地運行。
                        """)

                        sectionView(title: "智慧財產權", content: """
                        本 App 的介面設計、程式碼、圖示及原創音樂等內容受著作權法保護。佛教經典文本為公共領域內容，不受此限制。
                        """)

                        sectionView(title: "條款變更", content: """
                        我們保留隨時修改本使用條款的權利。條款變更後繼續使用本 App，即表示您接受修改後的條款。
                        """)

                        sectionView(title: "聯絡我們", content: """
                        如有任何使用條款相關問題，請透過以下方式聯絡：
                        電子郵件：first.fu@gmail.com
                        """)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("使用條款")
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
        TermsOfServiceView()
    }
    .modelContainer(for: UserSettings.self, inMemory: true)
}
