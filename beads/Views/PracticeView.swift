//
//  PracticeView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI

struct PracticeView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("修行")
                .font(.largeTitle)
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    PracticeView()
}
