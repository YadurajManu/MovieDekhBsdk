import SwiftUI

struct SearchMovieRow: View {
    let movie: Movie
    @State private var directorName: String?
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Poster
            CachedAsyncImage(url: movie.posterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.appCardBackground)
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title, Year and Original Title
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(movie.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appText)
                        
                        Text(movie.year)
                            .font(.system(size: 14))
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    if let original = movie.originalTitle, original != movie.title {
                        Text("'\(original)'")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.appTextSecondary.opacity(0.8))
                            .italic()
                    }
                }
                
                // Director
                if let director = directorName {
                    Text("directed by ")
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)
                    + Text(director)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                } else {
                    // Placeholder while loading
                    Text("directed by ...")
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary.opacity(0.5))
                        .italic()
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .task {
            await loadDirector()
        }
    }
    
    private func loadDirector() async {
        // Simple caching or checking if already known would be good
        // For now, fetch from TMDB
        do {
            let credits = try await TMDBService.shared.fetchMovieCredits(id: movie.id)
            if let director = credits.crew.first(where: { $0.job == "Director" }) {
                directorName = director.name
            }
        } catch {
            print("Failed to load director for \(movie.title): \(error)")
        }
    }
}

// Add fetchMovieCredits to TMDBService if not present
// Actually I noticed fetchMovieCast only returns cast. I'll need a credits fetcher.
