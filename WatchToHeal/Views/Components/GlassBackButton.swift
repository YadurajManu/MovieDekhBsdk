import SwiftUI

struct GlassBackButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // System Material Background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 42, height: 42)
                    // Subtle vibrancy-like border using separator color
                    .overlay(
                        Circle()
                            .stroke(Color(colorScheme == .dark ? .systemGray4 : .systemGray6).opacity(0.5), lineWidth: 0.5)
                    )
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.white)
                    // Slight shadow on the icon itself for better contrast on light backgrounds
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.15), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents(onPress: { isPressed = true }, onRelease: { isPressed = false })
    }
}

// Helper to handle press states without breaking standard button behavior
struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in onPress() })
                    .onEnded({ _ in onRelease() })
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressActions(onPress: onPress, onRelease: onRelease))
    }
}
