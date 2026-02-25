//
//  MantraListView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI
import SwiftData

struct MantraListView: View {
    @Query(sort: \Mantra.sortOrder) private var mantras: [Mantra]

    var body: some View {
        let grouped = Dictionary(grouping: mantras, by: \.category)
        let categories = grouped.keys.sorted()

        List {
            ForEach(categories, id: \.self) { category in
                Section(header: Text(category)) {
                    ForEach(grouped[category] ?? [], id: \.name) { mantra in
                        NavigationLink(destination: MantraDetailView(mantra: mantra)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mantra.name)
                                    .font(.body)
                                Text(mantra.pinyinText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
}
