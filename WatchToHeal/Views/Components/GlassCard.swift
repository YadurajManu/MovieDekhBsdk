import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    var opacity: CGFloat = 0.5
    let content: Content
    
    init(cornerRadius: CGFloat = 20, opacity: CGFloat = 0.5, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Glass effect
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.05))
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.black.opacity(opacity))
                        .blur(radius: 1)
                )
                .background(
                    VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                )
            
            // Border
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05), .clear, .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            
            content
        }
    }
}

// Helper for UIKit Blur
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { uiView.effect = effect }
}
