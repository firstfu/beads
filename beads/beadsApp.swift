//
//  beadsApp.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

import SwiftUI
import SwiftData

@main
struct beadsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PracticeSession.self,
            DailyRecord.self,
            Mantra.self,
            UserSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    MantraSeedData.seedIfNeeded(modelContext: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
