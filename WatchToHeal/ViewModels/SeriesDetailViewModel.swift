//
//  SeriesDetailViewModel.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 22/12/25.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class SeriesDetailViewModel: ObservableObject {
    @Published var seriesDetail: TVDetail?
    @Published var cast: [Cast] = []
    @Published var watchProviders: TMDBService.WatchProvidersResponse.CountryProviders?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isWatched = false
    @Published var userRating: Int?
    
    func loadSeriesDetail(id: Int, region: String = "US") async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch TV details and watch providers concurrently
            async let detailTask = TMDBService.shared.fetchTVDetail(id: id)
            async let providersTask = TMDBService.shared.fetchTVWatchProviders(tvId: id, region: region)
            
            let (detail, providers) = try await (detailTask, providersTask)
            
            self.seriesDetail = detail
            self.cast = detail.credits?.cast ?? []
            self.watchProviders = providers
            
            // Load user rating if authenticated
            if let user = AuthenticationService.shared.user {
                let watchlist = try await FirestoreService.shared.fetchWatchlist(userId: user.uid)
                if let seriesInWatchlist = watchlist.first(where: { $0.id == id }) {
                    self.userRating = seriesInWatchlist.userRating
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func rateSeries(rating: Int) async {
        guard let series = seriesDetail else { return }
        self.userRating = rating
        
        // Create Movie object for watchlist compatibility
        let seriesAsMovie = Movie(
            id: series.id,
            title: nil,
            name: series.name,
            posterPath: series.posterPath,
            backdropPath: series.backdropPath,
            overview: series.overview,
            releaseDate: nil,
            firstAirDate: series.firstAirDate,
            voteAverage: series.voteAverage,
            voteCount: series.voteCount
        )
        
        // Ensure series is in watchlist to save rating
        if !WatchlistManager.shared.isInWatchlist(series.id) {
            WatchlistManager.shared.addToWatchlist(seriesAsMovie)
        }
        WatchlistManager.shared.rateMovie(seriesAsMovie, rating: rating)
    }
}
