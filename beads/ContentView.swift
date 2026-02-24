//
//  ContentView.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("修行", systemImage: "circle.circle") {
                PracticeView()
            }
            Tab("記錄", systemImage: "chart.bar") {
                RecordsView()
            }
            Tab("經藏", systemImage: "book") {
                ScriptureView()
            }
            Tab("設定", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            PracticeSession.self,
            DailyRecord.self,
            Mantra.self,
            UserSettings.self,
        ], inMemory: true)
}
