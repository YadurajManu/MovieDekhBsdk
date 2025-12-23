import Foundation
import SwiftUI
import Combine
import FirebaseAuth

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var watchedMovies: [WatchedMovie] = []
    @Published var totalMinutesWatched: Int = 0
    @Published var favoriteGenre: String = "None"
    @Published var moviesWatchedCount: Int = 0
    
    // Detailed Stats
    @Published var timeOfDayStats: [String: Int] = ["Morning": 0, "Afternoon": 0, "Evening": 0, "Night": 0]
    @Published var genreDistribution: [String: Int] = [:]
    
    private let userId: String?
    
    init() {
        self.userId = AuthenticationService.shared.user?.uid
        Task {
            await loadHistory()
        }
    }
    
    func loadHistory() async {
        guard let uid = AuthenticationService.shared.user?.uid else { return }
        do {
            let history = try await FirestoreService.shared.fetchHistory(userId: uid)
            await MainActor.run {
                self.watchedMovies = history
                self.calculateStats()
            }
        } catch {
            print("Error loading history: \(error)")
        }
    }
    
    func addToHistory(movie: MovieDetail) {
        guard let uid = AuthenticationService.shared.user?.uid else { return }
        // Optimistic update
        let newMovie = WatchedMovie(
            id: movie.id,
            title: movie.title,
            posterPath: movie.posterPath,
            runtime: movie.runtime ?? 0,
            genres: movie.genres.map { $0.name },
            watchedAt: Date()
        )
        
        DispatchQueue.main.async {
            if !self.watchedMovies.contains(where: { $0.id == movie.id }) {
                self.watchedMovies.insert(newMovie, at: 0)
                self.calculateStats()
            }
        }
        
        Task {
            try? await FirestoreService.shared.addToHistory(userId: uid, movie: movie)
        }
    }
    
    func removeFromHistory(movieId: Int) {
        guard let uid = AuthenticationService.shared.user?.uid else { return }
        
        DispatchQueue.main.async {
            if let index = self.watchedMovies.firstIndex(where: { $0.id == movieId }) {
                self.watchedMovies.remove(at: index)
                self.calculateStats()
            }
        }
        
        Task {
            try? await FirestoreService.shared.removeFromHistory(userId: uid, movieId: movieId)
        }
    }
    
    func isWatched(movieId: Int) -> Bool {
        watchedMovies.contains(where: { $0.id == movieId })
    }
    
    private func calculateStats() {
        // Count
        moviesWatchedCount = watchedMovies.count
        
        // Total Time
        totalMinutesWatched = watchedMovies.reduce(0) { $0 + $1.runtime }
        
        // Genre Distribution
        let allGenres = watchedMovies.flatMap { $0.genres }
        genreDistribution = allGenres.reduce(into: [:]) { counts, genre in
            counts[genre, default: 0] += 1
        }
        
        // Favorite Genre
        if let topGenre = genreDistribution.max(by: { $0.value < $1.value })?.key {
            favoriteGenre = topGenre
        } else {
            favoriteGenre = "None"
        }
        
        // Time of Day Stats
        var times: [String: Int] = ["Morning": 0, "Afternoon": 0, "Evening": 0, "Night": 0]
        let calendar = Calendar.current
        
        for movie in watchedMovies {
            let hour = calendar.component(.hour, from: movie.watchedAt)
            
            switch hour {
            case 5..<12: times["Morning", default: 0] += 1
            case 12..<17: times["Afternoon", default: 0] += 1
            case 17..<22: times["Evening", default: 0] += 1
            default: times["Night", default: 0] += 1 // 22-5
            }
        }
        timeOfDayStats = times
    }
    
    // Formatted Stats
    var formattedWatchTime: String {
        let minutes = totalMinutesWatched
        let years = minutes / (60 * 24 * 365)
        let months = (minutes % (60 * 24 * 365)) / (60 * 24 * 30)
        let days = (minutes % (60 * 24 * 30)) / (60 * 24)
        let hours = (minutes % (60 * 24)) / 60
        
        var components: [String] = []
        if years > 0 { components.append("\(years)y") }
        if months > 0 { components.append("\(months)mo") }
        if days > 0 { components.append("\(days)d") }
        // If we have years/months, hours might be too granular, but let's keep it simple
        if components.isEmpty {
            if hours > 0 { components.append("\(hours)h") }
            let mins = minutes % 60
            if mins > 0 || components.isEmpty { components.append("\(mins)m") }
        }
        
        return components.prefix(2).joined(separator: " ")
    }
    
    func clearHistory() {
        DispatchQueue.main.async {
            self.watchedMovies.removeAll()
            self.totalMinutesWatched = 0
            self.favoriteGenre = "None"
            self.moviesWatchedCount = 0
            self.timeOfDayStats = ["Morning": 0, "Afternoon": 0, "Evening": 0, "Night": 0]
            self.genreDistribution = [:]
        }
    }
}
