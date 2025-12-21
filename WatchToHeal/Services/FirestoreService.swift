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
    
    // MARK: - Friend System
    
    enum FriendshipStatus {
        case friends
        case requestSent
        case requestReceived
        case none
    }
    
    func sendFriendRequest(from senderId: String, to recipientId: String) async throws {
        guard senderId != recipientId else { return } // Prevent self-requests
        
        let requestData: [String: Any] = [
            "senderId": senderId,
            "timestamp": Timestamp()
        ]
        
        try await db.collection("friendRequests")
            .document(recipientId)
            .collection("requests")
            .document(senderId)
            .setData(requestData)
    }
    
    func acceptFriendRequest(from senderId: String, to recipientId: String) async throws {
        let batch = db.batch()
        
        // Create friendship for both users
        let timestamp = Timestamp()
        let friendshipData: [String: Any] = ["timestamp": timestamp]
        
        let recipientFriendRef = db.collection("friendships")
            .document(recipientId)
            .collection("friends")
            .document(senderId)
        batch.setData(friendshipData, forDocument: recipientFriendRef)
        
        let senderFriendRef = db.collection("friendships")
            .document(senderId)
            .collection("friends")
            .document(recipientId)
        batch.setData(friendshipData, forDocument: senderFriendRef)
        
        // Delete the request
        let requestRef = db.collection("friendRequests")
            .document(recipientId)
            .collection("requests")
            .document(senderId)
        batch.deleteDocument(requestRef)
        
        // Update friend counts
        let recipientRef = db.collection("users").document(recipientId)
        batch.updateData(["followerCount": FieldValue.increment(Int64(1))], forDocument: recipientRef)
        
        let senderRef = db.collection("users").document(senderId)
        batch.updateData(["followingCount": FieldValue.increment(Int64(1))], forDocument: senderRef)
        
        try await batch.commit()
    }
    
    func declineFriendRequest(from senderId: String, to recipientId: String) async throws {
        try await db.collection("friendRequests")
            .document(recipientId)
            .collection("requests")
            .document(senderId)
            .delete()
    }
    
    func cancelFriendRequest(from senderId: String, to recipientId: String) async throws {
        try await db.collection("friendRequests")
            .document(recipientId)
            .collection("requests")
            .document(senderId)
            .delete()
    }
    
    func removeFriend(userId: String, friendId: String) async throws {
        let batch = db.batch()
        
        // Remove friendship from both users
        let userFriendRef = db.collection("friendships")
            .document(userId)
            .collection("friends")
            .document(friendId)
        batch.deleteDocument(userFriendRef)
        
        let friendUserRef = db.collection("friendships")
            .document(friendId)
            .collection("friends")
            .document(userId)
        batch.deleteDocument(friendUserRef)
        
        // Decrement friend counts
        let userRef = db.collection("users").document(userId)
        batch.updateData(["followerCount": FieldValue.increment(Int64(-1))], forDocument: userRef)
        
        let friendRef = db.collection("users").document(friendId)
        batch.updateData(["followingCount": FieldValue.increment(Int64(-1))], forDocument: friendRef)
        
        try await batch.commit()
    }
    
    func checkFriendshipStatus(userId: String, otherId: String) async throws -> FriendshipStatus {
        // Check if already friends
        let friendDoc = try await db.collection("friendships")
            .document(userId)
            .collection("friends")
            .document(otherId)
            .getDocument()
        
        if friendDoc.exists {
            return .friends
        }
        
        // Check if request sent
        let sentRequestDoc = try await db.collection("friendRequests")
            .document(otherId)
            .collection("requests")
            .document(userId)
            .getDocument()
        
        if sentRequestDoc.exists {
            return .requestSent
        }
        
        // Check if request received
        let receivedRequestDoc = try await db.collection("friendRequests")
            .document(userId)
            .collection("requests")
            .document(otherId)
            .getDocument()
        
        if receivedRequestDoc.exists {
            return .requestReceived
        }
        
        return .none
    }
    
    func fetchFriendRequests(userId: String) async throws -> [UserProfile] {
        let snapshot = try await db.collection("friendRequests")
            .document(userId)
            .collection("requests")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        var profiles: [UserProfile] = []
        for doc in snapshot.documents {
            if let senderId = doc.data()["senderId"] as? String,
               let profile = try? await fetchUserProfile(userId: senderId) {
                profiles.append(profile)
            }
        }
        return profiles
    }
    
    func fetchFriends(userId: String) async throws -> [UserProfile] {
        let snapshot = try await db.collection("friendships")
            .document(userId)
            .collection("friends")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        var profiles: [UserProfile] = []
        for doc in snapshot.documents {
            let friendId = doc.documentID
            if let profile = try? await fetchUserProfile(userId: friendId) {
                profiles.append(profile)
            }
        }
        return profiles
    }
    
    // MARK: - Community Lists
    
    func createCommunityList(list: CommunityList) async throws {
        try await db.collection("communityLists").document(list.id).setData(list.dictionary)
    }
    
    func likeCommunityList(listId: String, userId: String) async throws {
        let listRef = db.collection("communityLists").document(listId)
        let snapshot = try await listRef.getDocument()
        guard let data = snapshot.data() else { return }
        
        var likedBy = data["likedBy"] as? [String] ?? []
        let alreadyLiked = likedBy.contains(userId)
        
        if alreadyLiked {
            likedBy.removeAll { $0 == userId }
        } else {
            likedBy.append(userId)
        }
        
        try await listRef.updateData([
            "likedBy": likedBy,
            "likeCount": likedBy.count
        ])
    }
    
    func addComment(listId: String, comment: Comment) async throws {
        let listRef = db.collection("communityLists").document(listId)
        let commentRef = listRef.collection("comments").document(comment.id)
        
        try await db.runTransaction { (transaction, _) -> Any? in
            transaction.setData(comment.dictionary, forDocument: commentRef)
            transaction.updateData(["commentCount": FieldValue.increment(Int64(1))], forDocument: listRef)
            return nil
        }
    }
    
    func fetchComments(listId: String) async throws -> [Comment] {
        let snapshot = try await db.collection("communityLists").document(listId).collection("comments")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { Comment(dictionary: $0.data()) }
    }
    
    func deleteCommunityList(listId: String) async throws {
        try await db.collection("communityLists").document(listId).delete()
    }
    
    func updateCommunityList(list: CommunityList) async throws {
        try await db.collection("communityLists").document(list.id).updateData(list.dictionary)
    }
    
    func fetchUserCommunityLists(userId: String) async throws -> [CommunityList] {
        // We remove the .order(by:) to avoid needing a composite index in Firestore
        // which often causes empty results or errors if not manually created.
        // We will sort in-memory instead.
        let snapshot = try await db.collection("communityLists")
            .whereField("ownerId", isEqualTo: userId)
            .getDocuments()
        
        let lists = parseCommunityLists(from: snapshot)
        return lists.sorted { $0.createdAt > $1.createdAt }
    }
    
    func fetchAllCommunityLists() async throws -> [CommunityList] {
        let snapshot = try await db.collection("communityLists")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return parseCommunityLists(from: snapshot)
    }
    
    private func parseCommunityLists(from snapshot: QuerySnapshot) -> [CommunityList] {
        return snapshot.documents.compactMap { doc -> CommunityList? in
            return CommunityList(dictionary: doc.data())
        }
    }
    
    // MARK: - Movie Community
    
    func getMovieSocialStats(movieId: Int) async throws -> MovieSocialStats {
        let doc = try await db.collection("movieSocial").document("\(movieId)").getDocument()
        if let data = doc.data() {
            return try Firestore.Decoder().decode(MovieSocialStats.self, from: data)
        }
        return MovieSocialStats()
    }
    
    func submitMovieVote(movieId: Int, rating: String, genreTags: [String], userReview: String?, isSpoiler: Bool, user: UserProfile) async throws {
        let socialRef = db.collection("movieSocial").document("\(movieId)")
        let reviewRef = socialRef.collection("reviews").document(user.id)
        
        try await db.runTransaction { (transaction, _) -> Any? in
            // 1. Get current stats
            let socialDoc: DocumentSnapshot
            do {
                socialDoc = try transaction.getDocument(socialRef)
            } catch {
                return nil
            }
            
            var stats = MovieSocialStats()
            if socialDoc.exists, let data = socialDoc.data() {
                stats = (try? Firestore.Decoder().decode(MovieSocialStats.self, from: data)) ?? MovieSocialStats()
            }
            
            // 2. Check if user already reviewed to avoid double-counting increments
            // For now, we'll increment for every submission for simplicity, 
            // but in a production app we'd verify if user.id already exists in reviews.
            
            // 3. Update stats
            stats.totalVotes += 1
            stats.ratingCounts[rating, default: 0] += 1
            for tag in genreTags {
                stats.genreConsensus[tag, default: 0] += 1
            }
            stats.lastUpdated = Date()
            
            let statsData = try! Firestore.Encoder().encode(stats)
            transaction.setData(statsData, forDocument: socialRef, merge: true)
            
            // 4. Save individual review
            let review = MovieReview(
                userId: user.id,
                username: user.username ?? user.name,
                userPhoto: user.photoURL?.absoluteString,
                content: userReview ?? "",
                rating: rating,
                genreTags: genreTags,
                timestamp: Date(),
                isSpoiler: isSpoiler,
                likesCount: 0,
                repliesCount: 0,
                likedBy: []
            )
            let reviewData = try! Firestore.Encoder().encode(review)
            transaction.setData(reviewData, forDocument: reviewRef)
            
            return nil
        }
    }
    
    func fetchMovieReviews(movieId: Int) async throws -> [MovieReview] {
        let snapshot = try await db.collection("movieSocial")
            .document("\(movieId)")
            .collection("reviews")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> MovieReview? in
            return try? doc.data(as: MovieReview.self)
        }
    }
    
    func toggleReviewLike(movieId: Int, reviewId: String, userId: String) async throws {
        let reviewRef = db.collection("movieSocial")
            .document("\(movieId)")
            .collection("reviews")
            .document(reviewId)
            
        try await db.runTransaction { (transaction, _) -> Any? in
            let reviewDoc: DocumentSnapshot
            do {
                reviewDoc = try transaction.getDocument(reviewRef)
            } catch {
                return nil
            }
            
            guard var review = try? reviewDoc.data(as: MovieReview.self) else { return nil }
            
            if review.likedBy.contains(userId) {
                review.likedBy.removeAll { $0 == userId }
                review.likesCount = max(0, review.likesCount - 1)
            } else {
                review.likedBy.append(userId)
                review.likesCount += 1
            }
            
            let data = try! Firestore.Encoder().encode(review)
            transaction.setData(data, forDocument: reviewRef, merge: true)
            return nil
        }
    }
    
    func submitMovieReply(movieId: Int, reviewId: String, content: String, user: UserProfile) async throws {
        let reviewRef = db.collection("movieSocial")
            .document("\(movieId)")
            .collection("reviews")
            .document(reviewId)
        let replyRef = reviewRef.collection("replies").document()
        
        try await db.runTransaction { (transaction, _) -> Any? in
            // 1. Update review's reply count
            let reviewDoc: DocumentSnapshot
            do {
                reviewDoc = try transaction.getDocument(reviewRef)
            } catch {
                return nil
            }
            
            if var review = try? reviewDoc.data(as: MovieReview.self) {
                review.repliesCount += 1
                let reviewData = try! Firestore.Encoder().encode(review)
                transaction.setData(reviewData, forDocument: reviewRef, merge: true)
            }
            
            // 2. Add reply
            let reply = MovieReply(
                userId: user.id,
                username: user.username ?? user.name,
                userPhoto: user.photoURL?.absoluteString,
                content: content,
                timestamp: Date(),
                likesCount: 0,
                likedBy: []
            )
            let replyData = try! Firestore.Encoder().encode(reply)
            transaction.setData(replyData, forDocument: replyRef)
            
            return nil
        }
    }
    
    func fetchMovieReplies(movieId: Int, reviewId: String) async throws -> [MovieReply] {
        let snapshot = try await db.collection("movieSocial")
            .document("\(movieId)")
            .collection("reviews")
            .document(reviewId)
            .collection("replies")
            .order(by: "timestamp", descending: false)
            .getDocuments()
            
        return snapshot.documents.compactMap { doc -> MovieReply? in
            return try? doc.data(as: MovieReply.self)
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
