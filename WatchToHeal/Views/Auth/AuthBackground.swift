import SwiftUI

struct AuthBackground: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Subtle Mesh Gradient
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                .black, .black, .black,
                Color(hex: "1A1A1A"), .black, Color(hex: "0D0D0D"),
                Color.appPrimary.opacity(0.1), .black, .black
            ])
            .ignoresSafeArea()
            .blur(radius: 50)
            
            // Animated Glow
            Circle()
                .fill(Color.appPrimary.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -150, y: -200)
            
            Circle()
                .fill(Color.appPrimary.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 150, y: 300)
        }
    }
}
