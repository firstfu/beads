// MARK: - 檔案說明
/// ScriptureView.swift
/// 經藏畫面 - 顯示咒語/經文列表，並於首次載入時植入預設資料
/// 模組：Views

//
//  ScriptureView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI
import SwiftData

/// 經藏視圖，顯示咒語與經文的瀏覽列表
struct ScriptureView: View {
    /// SwiftData 模型上下文，用於查詢咒語資料與植入預設種子資料
    @Environment(\.modelContext) private var modelContext

    /// 主視圖內容，以導覽堆疊包裹咒語列表，並在畫面出現時確保種子資料已植入
    var body: some View {
        NavigationStack {
            MantraListView()
                .navigationTitle("經藏")
                .onAppear {
                    MantraSeedData.seedIfNeeded(modelContext: modelContext)
                }
        }
    }
}

#Preview {
    ScriptureView()
}
