import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    // MARK: - User Data
    func saveUser(user: User) async throws {
        let userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "",
            "displayName": user.displayName ?? "",
            "photoURL": user.photoURL?.absoluteString ?? "",
            "lastLogin": Timestamp()
        ]
        
        try await db.collection("users").document(user.uid).setData(userData, merge: true)
    }
    
    // MARK: - Onboarding
    func saveOnboardingData(userId: String, data: [String: Any]) async throws {
        try await db.collection("users").document(userId).collection("onboarding").document("tasteFingerprint").setData(data)
        // Update main user doc flag
        try await db.collection("users").document(userId).updateData(["hasCompletedOnboarding": true])
    }
    
    func checkOnboardingStatus(userId: String) async throws -> Bool {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        guard let data = snapshot.data(), let status = data["hasCompletedOnboarding"] as? Bool else {
            return false
        }
        return status
    }
    
    // MARK: - Watchlist
    func addToWatchlist(userId: String, movie: Movie) async throws {
        // Only save minimal data needed for list
        var movieData: [String: Any] = [
            "id": movie.id,
            "title": movie.title,
            "posterPath": movie.posterPath ?? "",
            "voteAverage": movie.voteAverage,
            "addedAt": Timestamp()
        ]
        
        if let userRating = movie.userRating {
            movieData["userRating"] = userRating
        }
        
        try await db.collection("users").document(userId).collection("watchlist").document("\(movie.id)").setData(movieData, merge: true)
    }
    
    func removeFromWatchlist(userId: String, movieId: Int) async throws {
        try await db.collection("users").document(userId).collection("watchlist").document("\(movieId)").delete()
    }
    
    func updateMovieRating(userId: String, movieId: Int, rating: Int) async throws {
        try await db.collection("users").document(userId).collection("watchlist").document("\(movieId)").updateData([
            "userRating": rating
        ])
    }
    
    func fetchWatchlist(userId: String) async throws -> [Movie] {
        let snapshot = try await db.collection("users").document(userId).collection("watchlist").order(by: "addedAt", descending: true).getDocuments()
        
        return snapshot.documents.compactMap { doc -> Movie? in
            let data = doc.data()
            guard let id = data["id"] as? Int,
                  let title = data["title"] as? String else { return nil }
            
            let overview = data["overview"] as? String ?? ""
            let releaseDate = data["releaseDate"] as? String ?? ""
            let posterPath = data["posterPath"] as? String
             let voteAverage = data["voteAverage"] as? Double ?? 0.0
            
            var movie = Movie(id: id,
                         title: title,
                         posterPath: posterPath,
                         backdropPath: nil,
                         overview: overview,
                         releaseDate: releaseDate,
                         voteAverage: voteAverage,
                         voteCount: 0)
            
            if let rating = data["userRating"] as? Int {
                movie.userRating = rating
            }
            return movie
        }
    }
    
    // Simpler fetch assuming we store IDs and fetch validation from API or store full JSON
    func fetchWatchlistIDs(userId: String) async throws -> [Int] {
        let snapshot = try await db.collection("users").document(userId).collection("watchlist").getDocuments()
        return snapshot.documents.compactMap { $0.data()["id"] as? Int }
    }
    
    // MARK: - User Profile (Letterboxd Style)
    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        guard let data = snapshot.data() else { return nil }
        
        // Reconstruct basic details
        let username = data["username"] as? String
        let name = data["displayName"] as? String ?? "Movie Lover"
        let email = data["email"] as? String ?? ""
        let bio = data["bio"] as? String ?? ""
        let photoString = data["photoURL"] as? String ?? ""
        let photoURL = URL(string: photoString)
        
        let followerCount = data["followerCount"] as? Int ?? 0
        let followingCount = data["followingCount"] as? Int ?? 0
        
        // Fetch Top Favorites 
        let favSnapshot = try await db.collection("users").document(userId).collection("topFavorites").order(by: "rank").getDocuments()
        let topFavorites = favSnapshot.documents.compactMap { doc -> Movie? in
            let d = doc.data()
            guard let id = d["id"] as? Int,
                  let title = d["title"] as? String else { return nil }
            
            return Movie(id: id,
                         title: title,
                         posterPath: d["posterPath"] as? String,
                         backdropPath: nil,
                         overview: "",
                         releaseDate: d["releaseDate"] as? String ?? "",
                         voteAverage: 0.0,
                         voteCount: 0)
        }
        
        // Fetch Preferences
        let isNotificationEnabled = data["isNotificationEnabled"] as? Bool ?? true
        let showAdultContent = data["showAdultContent"] as? Bool ?? false
        let preferredRegion = data["preferredRegion"] as? String ?? "US"
        
        return UserProfile(id: userId,
                          username: username,
                          name: name, 
                          email: email, 
                          bio: bio, 
                          photoURL: photoURL, 
                          topFavorites: topFavorites,
                          followerCount: followerCount,
                          followingCount: followingCount,
                          isNotificationEnabled: isNotificationEnabled,
                          showAdultContent: showAdultContent,
                          preferredRegion: preferredRegion)
    }
    
    // MARK: - Social Identity
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let usernameLower = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let doc = try await db.collection("usernames").document(usernameLower).getDocument()
        return !doc.exists
    }
    
    func setUsername(userId: String, username: String) async throws {
        let usernameLower = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let batch = db.batch()
        
        // Reserve username
        let usernameRef = db.collection("usernames").document(usernameLower)
        batch.setData(["uid": userId], forDocument: usernameRef)
        
        // Update user profile
        let userRef = db.collection("users").document(userId)
        batch.updateData([
            "username": username,
            "usernameLowercase": usernameLower
        ], forDocument: userRef)
        
        try await batch.commit()
    }
    
    func searchUsers(query: String) async throws -> [UserProfile] {
        let queryLower = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !queryLower.isEmpty else { return [] }
        
        // Simple prefix search using Firestore query indices
        let snapshot = try await db.collection("users")
            .whereField("usernameLowercase", isGreaterThanOrEqualTo: queryLower)
            .whereField("usernameLowercase", isLessThanOrEqualTo: queryLower + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()
            
        var users: [UserProfile] = []
        for doc in snapshot.documents {
            if let profile = try? await fetchUserProfile(userId: doc.documentID) {
                users.append(profile)
            }
        }
        return users
    }
    
    func updateUserProfile(userId: String, data: [String: Any]) async throws {
        try await db.collection("users").document(userId).updateData(data)
    }
    
    func updateTopFavorites(userId: String, movies: [Movie]) async throws {
        let batch = db.batch()
        let ref = db.collection("users").document(userId).collection("topFavorites")
        
        // 1. Delete existing (naive approach for small list)
        let snapshot = try await ref.getDocuments()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        
        // 2. Add new ones
        for (index, movie) in movies.enumerated() {
            let docRef = ref.document("\(movie.id)")
            let data: [String: Any] = [
                "id": movie.id,
                "title": movie.title,
                "posterPath": movie.posterPath ?? "",
                "releaseDate": movie.releaseDate ?? "",
                "rank": index
            ]
            batch.setData(data, forDocument: docRef)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Watch History (Native)
    func addToHistory(userId: String, movie: MovieDetail) async throws {
        let data: [String: Any] = [
            "id": movie.id,
            "title": movie.title,
            "posterPath": movie.posterPath ?? "",
            "runtime": movie.runtime ?? 0,
            "genres": movie.genres.map { $0.name },
            "watchedAt": Timestamp()
        ]
        
        try await db.collection("users").document(userId).collection("history").document("\(movie.id)").setData(data, merge: true)
    }
    
    func removeFromHistory(userId: String, movieId: Int) async throws {
        try await db.collection("users").document(userId).collection("history").document("\(movieId)").delete()
    }
    
    func fetchHistory(userId: String) async throws -> [WatchedMovie] {
        let snapshot = try await db.collection("users").document(userId).collection("history").order(by: "watchedAt", descending: true).getDocuments()
        
        return snapshot.documents.compactMap { doc -> WatchedMovie? in
            let data = doc.data()
            guard let id = data["id"] as? Int,
                  let title = data["title"] as? String else { return nil }
            
            return WatchedMovie(
                id: id,
                title: title,
                posterPath: data["posterPath"] as? String,
                runtime: data["runtime"] as? Int ?? 0,
                genres: data["genres"] as? [String] ?? [],
                watchedAt: (data["watchedAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        }
    }
}

// Helper Model for History
struct WatchedMovie: Identifiable, Codable {
    let id: Int
    let title: String
    let posterPath: String?
    let runtime: Int
    let genres: [String]
    let watchedAt: Date
    
    var posterURL: URL? {
        guard let posterPath = posterPath, !posterPath.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
}
