import SwiftUI

struct PremiumRatingBadge: View {
    let rating: Double
    var size: BadgeSize = .medium
    
    enum BadgeSize {
        case small, medium, large
        
        var starSize: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 18
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 14
            case .large: return 24
            }
        }
        
        var hPadding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 8
            case .large: return 14
            }
        }
        
        var vPadding: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 8
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 12
            }
        }
    }
    
    var body: some View {
        HStack(spacing: size == .large ? 10 : 6) {
            // Star icon with glow
            ZStack {
                Image(systemName: "star.fill")
                    .font(.system(size: size.starSize))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blur(radius: size == .large ? 4 : 2)
                
                Image(systemName: "star.fill")
                    .font(.system(size: size.starSize))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            // Rating text
            Text(String(format: "%.1f", rating))
                .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .fixedSize()
        .padding(.horizontal, size.hPadding)
        .padding(.vertical, size.vPadding)
        .background(
            ZStack {
                // Premium background
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.15),
                                Color(white: 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Metallic golden border
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.8, green: 0.6, blue: 0.2),
                                Color(red: 0.6, green: 0.4, blue: 0.1),
                                Color(red: 0.3, green: 0.5, blue: 0.6).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: size == .large ? 1.5 : 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        PremiumRatingBadge(rating: 8.5, size: .large)
        PremiumRatingBadge(rating: 7.2, size: .medium)
        PremiumRatingBadge(rating: 6.5, size: .small)
    }
    .padding()
    .background(Color.black)
}
