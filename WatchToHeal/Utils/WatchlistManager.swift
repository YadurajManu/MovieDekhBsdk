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
        Task {
            await syncWithFirestore()
        }
    }
    
    func syncWithFirestore() async {
        guard let userValue = Auth.auth().currentUser else { return }
        do {
            let cloudWatchlist = try await FirestoreService.shared.fetchWatchlist(userId: userValue.uid)
            
            await MainActor.run {
                // Merge cloud data with local data, prioritizing cloud for now
                // but ensuring uniqueness by ID
                var merged = cloudWatchlist
                for localMovie in self.watchlistMovies {
                    if !merged.contains(where: { $0.id == localMovie.id }) {
                        merged.append(localMovie)
                        // Proactively add local-only movies to cloud
                        Task {
                            try? await FirestoreService.shared.addToWatchlist(userId: userValue.uid, movie: localMovie)
                        }
                    }
                }
                
                self.watchlistMovies = merged.sorted(by: { $0.id > $1.id }) // Simple sort
                self.saveWatchlist()
            }
        } catch {
            print("Error syncing watchlist: \(error)")
        }
    }
    
    func isInWatchlist(_ movieId: Int) -> Bool {
        watchlistMovies.contains { $0.id == movieId }
    }
    
    func toggleWatchlist(_ movie: Movie) {
        if let index = watchlistMovies.firstIndex(where: { $0.id == movie.id }) {
            watchlistMovies.remove(at: index)
            removeFromFirestore(movie.id)
        } else {
            watchlistMovies.insert(movie, at: 0)
            addToFirestore(movie)
        }
        saveWatchlist()
    }
    
    private func addToFirestore(_ movie: Movie) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task {
            try? await FirestoreService.shared.addToWatchlist(userId: uid, movie: movie)
        }
    }
    
    private func removeFromFirestore(_ movieId: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task {
            try? await FirestoreService.shared.removeFromWatchlist(userId: uid, movieId: movieId)
        }
    }
    
    func addToWatchlist(_ movie: Movie) {
        guard !isInWatchlist(movie.id) else { return }
        watchlistMovies.insert(movie, at: 0)
        saveWatchlist()
        
        // Schedule alert if release date is in future
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let releaseDate = dateFormatter.date(from: movie.displayDate), releaseDate > Date() {
            NotificationManager.shared.scheduleMovieReleaseAlert(for: movie, releaseDate: releaseDate)
        }
        
        // Sync to Firestore
        addToFirestore(movie)
    }
    
    func removeFromWatchlist(_ movieId: Int) {
        watchlistMovies.removeAll { $0.id == movieId }
        saveWatchlist()
        
        // Cancel scheduled alerts
        NotificationManager.shared.cancelAlert(for: movieId)
        
        // Sync to Firestore
        removeFromFirestore(movieId)
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
