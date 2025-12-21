import SwiftUI

struct TrailerCard: View {
    let trailer: TMDBService.MovieTrailer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                // Backdrop Image
                CachedAsyncImage(url: trailer.backdropURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 280, height: 160)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 280, height: 160)
                }
                
                // Play Button Overlay
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )
                
                // Content Gradient
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(trailer.movieTitle.uppercased())
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.appText)
                    .lineLimit(1)
                
                Text("LATEST TRAILER")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.appPrimary)
                    .kerning(1)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 280)
    }
}
