//
//  WatchlistManager.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class WatchlistManager: ObservableObject {
    static let shared = WatchlistManager()
    
    @Published var watchlistMovies: [Movie] = []
    private let watchlistKey = "watchlistMovies"
    
    private init() {
        loadWatchlist()
    }
    
    func isInWatchlist(_ movieId: Int) -> Bool {
        watchlistMovies.contains { $0.id == movieId }
    }
    
    func toggleWatchlist(_ movie: Movie) {
        if let index = watchlistMovies.firstIndex(where: { $0.id == movie.id }) {
            watchlistMovies.remove(at: index)
        } else {
            watchlistMovies.insert(movie, at: 0)
        }
        saveWatchlist()
    }
    
    func addToWatchlist(_ movie: Movie) {
        guard !isInWatchlist(movie.id) else { return }
        watchlistMovies.insert(movie, at: 0)
        saveWatchlist()
        
        // Schedule alert if release date is in future
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let releaseDate = dateFormatter.date(from: movie.releaseDate), releaseDate > Date() {
            NotificationManager.shared.scheduleMovieReleaseAlert(for: movie, releaseDate: releaseDate)
        }
        
        // Sync to Firestore
        if let user = AuthenticationService.shared.user {
            Task {
                try? await FirestoreService.shared.addToWatchlist(userId: user.uid, movie: movie)
            }
        }
    }
    
    func removeFromWatchlist(_ movieId: Int) {
        watchlistMovies.removeAll { $0.id == movieId }
        saveWatchlist()
        
        // Cancel scheduled alerts
        NotificationManager.shared.cancelAlert(for: movieId)
        
        // Sync to Firestore
        if let user = AuthenticationService.shared.user {
            Task {
                try? await FirestoreService.shared.removeFromWatchlist(userId: user.uid, movieId: movieId)
            }
        }
    }
    
    func rateMovie(_ movie: Movie, rating: Int) {
        if let index = watchlistMovies.firstIndex(where: { $0.id == movie.id }) {
            var updatedMovie = watchlistMovies[index]
            updatedMovie.userRating = rating
            watchlistMovies[index] = updatedMovie
            saveWatchlist()
            
            // Sync to Firestore
            if let user = AuthenticationService.shared.user {
                Task {
                    try? await FirestoreService.shared.updateMovieRating(userId: user.uid, movieId: movie.id, rating: rating)
                }
            }
        }
    }
    
    private func saveWatchlist() {
        if let encoded = try? JSONEncoder().encode(watchlistMovies) {
            UserDefaults.standard.set(encoded, forKey: watchlistKey)
        }
    }
    
    private func loadWatchlist() {
        if let data = UserDefaults.standard.data(forKey: watchlistKey),
           let decoded = try? JSONDecoder().decode([Movie].self, from: data) {
            watchlistMovies = decoded
        }
    }
}
