import SwiftUI
import Combine

class StreamingSyncViewModel: ObservableObject {
    @Published var availableInWatchlist: [MovieAvailability] = []
    @Published var isChecking = false
    
    private let tmdbService = TMDBService.shared
    private let watchlistManager = WatchlistManager.shared
    
    struct MovieAvailability: Identifiable {
        let id: Int
        let movie: Movie
        let providers: [TMDBService.WatchProvidersResponse.Provider]
    }
    
    @MainActor
    func checkWatchlistAvailability(userProfile: UserProfile) async {
        guard !userProfile.streamingProviders.isEmpty else { return }
        
        isChecking = true
        defer { isChecking = false }
        
        var results: [MovieAvailability] = []
        let region = userProfile.preferredRegion
        let preferredIds = Set(userProfile.streamingProviders)
        
        // We check the first 20 movies in watchlist to avoid massive API hammering in one go
        let moviesToCheck = Array(watchlistManager.watchlistMovies.prefix(20))
        
        for movie in moviesToCheck {
            do {
                if let providers = try await tmdbService.fetchWatchProviders(movieId: movie.id, region: region) {
                    let matching = (providers.flatrate ?? []).filter { preferredIds.contains($0.id) }
                    
                    if !matching.isEmpty {
                        results.append(MovieAvailability(id: movie.id, movie: movie, providers: matching))
                    }
                }
            } catch {
                print("❌ Error checking availability for \(movie.displayName): \(error)")
            }
        }
        
        self.availableInWatchlist = results
    }
}
