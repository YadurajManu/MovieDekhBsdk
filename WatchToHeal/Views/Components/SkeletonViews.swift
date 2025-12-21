import SwiftUI

// MARK: - Skeleton Views

struct SkeletonMovieCard: View {
    let width: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(width: width, height: width * 1.5)
                .shimmer()
            
            // Title skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: width * 0.8, height: 12)
                .shimmer()
            
            // Rating skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: width * 0.5, height: 10)
                .shimmer()
        }
    }
}

struct SkeletonHeroCard: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 500)
                    .shimmer()
                
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 200, height: 24)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 150, height: 16)
                }
                .padding(24)
            }
        }
        .frame(height: 500)
    }
}

struct SkeletonMovieSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header skeleton
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 20)
                    .shimmer()
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 16)
                    .shimmer()
            }
            .padding(.horizontal, 20)
            
            // Movie cards skeleton
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonMovieCard(width: 120)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(30))
                        .offset(x: isAnimating ? geometry.size.width * 2 : -geometry.size.width * 2)
                }
            )
            .clipped()
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Empty States

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.appPrimary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.appText)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.appPrimary)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Predefined Empty States

extension EmptyStateView {
    static func emptyWatchlist(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "bookmark.slash",
            title: "No Movies Yet",
            message: "Start building your watchlist by adding movies you want to watch",
            actionTitle: "Browse Movies",
            action: action
        )
    }
    
    static func noSearchResults() -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try adjusting your search or filters to find what you're looking for"
        )
    }
    
    static func noInternet(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "No Internet Connection",
            message: "Please check your connection and try again",
            actionTitle: "Retry",
            action: action
        )
    }
    
    static func error(message: String, action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "Something Went Wrong",
            message: message,
            actionTitle: "Try Again",
            action: action
        )
    }
}
