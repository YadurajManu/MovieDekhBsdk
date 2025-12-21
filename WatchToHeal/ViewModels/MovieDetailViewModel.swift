//
//  MovieDetailViewModel.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import Foundation
import Combine
import FirebaseAuth
@MainActor
class MovieDetailViewModel: ObservableObject {
    @Published var movieDetail: MovieDetail?
    @Published var cast: [Cast] = []
    @Published var watchProviders: TMDBService.WatchProvidersResponse.CountryProviders?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isWatched = false
    @Published var userRating: Int?
    
    private let traktService = TraktService.shared
    
    func loadMovieDetail(id: Int, region: String = "US") async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch movie details and watch providers concurrently
            async let detailTask = TMDBService.shared.fetchMovieDetail(id: id)
            async let providersTask = TMDBService.shared.fetchWatchProviders(movieId: id, region: region)
            
            let (detail, providers) = try await (detailTask, providersTask)
            
            self.movieDetail = detail
            self.cast = detail.credits?.cast ?? []
            self.watchProviders = providers
            
            // Load user rating if authenticated
            if let user = AuthenticationService.shared.user {
                let watchlist = try await FirestoreService.shared.fetchWatchlist(userId: user.uid)
                if let movieInWatchlist = watchlist.first(where: { $0.id == id }) {
                    self.userRating = movieInWatchlist.userRating
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func markAsWatched(movieId: Int) async {
        guard traktService.isAuthenticated else { return }
        
        do {
            try await traktService.scrobbleMovie(tmdbId: movieId, progress: 100.0)
            await MainActor.run {
                self.isWatched = true
            }
        } catch {
            print("Failed to scrobble: \(error)")
        }
    }
    
    func rateMovie(rating: Int) async {
        guard let movie = movieDetail else { return }
        self.userRating = rating
        
        // Sync to WatchlistManager (which handles Firestore)
        let movieObj = Movie(id: movie.id, title: movie.title, posterPath: movie.posterPath, backdropPath: movie.backdropPath, overview: movie.overview, releaseDate: movie.releaseDate, voteAverage: movie.voteAverage, voteCount: movie.voteCount)
        
        // Ensure movie is in watchlist to save rating (based on current implementation)
        if !WatchlistManager.shared.isInWatchlist(movie.id) {
            WatchlistManager.shared.addToWatchlist(movieObj)
        }
        WatchlistManager.shared.rateMovie(movieObj, rating: rating)
    }
}
