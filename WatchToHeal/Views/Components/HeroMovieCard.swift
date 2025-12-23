import SwiftUI

struct HeroMovieCard: View {
    let movie: Movie
    var onDetailsTap: () -> Void
    @ObservedObject private var watchlistManager = WatchlistManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Background Image
                CachedAsyncImage(url: movie.backdropURL ?? movie.posterURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                
                // Gradient Overlay
                LinearGradient(
                    colors: [.clear, .appBackground.opacity(0.8), .appBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(movie.displayName)
                        .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 40))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                    
                    HStack(spacing: 8) {
                        Text(movie.year)
                        Text("•")
                        PremiumRatingBadge(rating: movie.voteAverage, size: .small)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    
                    Text(movie.overview)
                        .lineLimit(2)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.trailing, 40)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            onDetailsTap()
                        }) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                Text("Details")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.appPrimary)
                            .cornerRadius(30)
                        }
                        
                        Button(action: {
                            withAnimation {
                                watchlistManager.toggleWatchlist(movie)
                            }
                        }) {
                            HStack {
                                Image(systemName: watchlistManager.isInWatchlist(movie.id) ? "checkmark" : "plus")
                                Text("My List")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(watchlistManager.isInWatchlist(movie.id) ? Color.appPrimary : Color.white.opacity(0.2))
                            .cornerRadius(30)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
        .frame(height: 480)
    }
}
