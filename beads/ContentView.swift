//
//  ContentView.swift
//  beads
//
//  Created by firstfu on 2026/2/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack {
                Text("念珠")
                    .font(.largeTitle)
                Text("Buddhist Bead Counter")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("念珠")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PracticeSession.self, inMemory: true)
}
