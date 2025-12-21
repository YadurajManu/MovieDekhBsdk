import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App Logo
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .blur(radius: isAnimating ? 20 : 10)
                    
                    Image(systemName: "film.stack.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.appPrimary)
                        .shadow(color: .appPrimary.opacity(0.5), radius: 10)
                }
                
                VStack(spacing: 8) {
                    Text("WatchToHeal")
                        .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 48))
                        .foregroundColor(.appText)
                    
                    Text("Your Cinema, Your Peace")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                        .tracking(3)
                        .opacity(0.6)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}
