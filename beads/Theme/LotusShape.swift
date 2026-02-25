import SwiftUI

struct LotusView: View {
    var color: Color = BeadsTheme.Colors.accent
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            // Center petal (top)
            Ellipse()
                .fill(color.opacity(0.3))
                .frame(width: size * 0.3, height: size * 0.5)
                .offset(y: -size * 0.15)

            // Left petal
            Ellipse()
                .fill(color.opacity(0.2))
                .frame(width: size * 0.3, height: size * 0.45)
                .rotationEffect(.degrees(30))
                .offset(x: -size * 0.2, y: -size * 0.05)

            // Right petal
            Ellipse()
                .fill(color.opacity(0.2))
                .frame(width: size * 0.3, height: size * 0.45)
                .rotationEffect(.degrees(-30))
                .offset(x: size * 0.2, y: -size * 0.05)

            // Outer left petal
            Ellipse()
                .fill(color.opacity(0.15))
                .frame(width: size * 0.25, height: size * 0.4)
                .rotationEffect(.degrees(55))
                .offset(x: -size * 0.32, y: size * 0.05)

            // Outer right petal
            Ellipse()
                .fill(color.opacity(0.15))
                .frame(width: size * 0.25, height: size * 0.4)
                .rotationEffect(.degrees(-55))
                .offset(x: size * 0.32, y: size * 0.05)
        }
        .frame(width: size, height: size)
    }
}
