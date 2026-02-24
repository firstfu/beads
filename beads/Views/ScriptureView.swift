//
//  ScriptureView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI
import SwiftData

struct ScriptureView: View {
    @Environment(\.modelContext) private var modelContext

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
