//
//  MantraDetailView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI

struct MantraDetailView: View {
    let mantra: Mantra

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(mantra.name)
                    .font(.largeTitle.bold())

                VStack(alignment: .leading, spacing: 8) {
                    Text("原文")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(mantra.originalText)
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("拼音")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(mantra.pinyinText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("說明")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(mantra.descriptionText)
                        .font(.body)
                }

                HStack {
                    Image(systemName: "target")
                    Text("建議每次持誦 \(mantra.suggestedCount) 遍")
                        .font(.subheadline)
                }
                .foregroundStyle(.orange)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
        .navigationTitle(mantra.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
