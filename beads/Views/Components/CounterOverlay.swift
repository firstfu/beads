//
//  CounterOverlay.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI

struct CounterOverlay: View {
    let count: Int
    let rounds: Int
    let todayCount: Int
    let streakDays: Int
    let mantraName: String

    var body: some View {
        VStack {
            // Top bar
            HStack {
                Text(mantraName)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Round counter
            if rounds > 0 {
                Text("第 \(rounds) 圈")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 4)
            }

            Spacer()

            // Center count
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("總計數")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            // Mantra text
            Text(mantraName)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.bottom, 8)

            // Bottom stats bar
            HStack {
                Label("今日：\(todayCount)", systemImage: "sun.min")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Label("\(streakDays) 天", systemImage: "flame")
                    .font(.footnote)
                    .foregroundStyle(.orange.opacity(0.9))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
}
