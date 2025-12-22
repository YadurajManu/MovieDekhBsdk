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
        // Save comprehensive data needed for list visibility
        var movieData: [String: Any] = [
            "id": movie.id,
            "title": movie.displayName,
            "posterPath": movie.posterPath ?? "",
            "overview": movie.overview,
            "releaseDate": movie.displayDate,
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
        let streamingProviders = data["streamingProviders"] as? [Int] ?? []
        
        // Authority Stats
        let isVerified = data["isVerified"] as? Bool ?? false
        let watchedCount = data["watchedCount"] as? Int ?? 0
        let isAdmin = data["isAdmin"] as? Bool ?? false
        
        return UserProfile(id: userId,
                          username: username,
                          name: name, 
                          email: email, 
                          bio: bio, 
                          photoURL: photoURL, 
                          topFavorites: topFavorites,
                          isAdmin: isAdmin,
                          isVerified: isVerified,
                          watchedCount: watchedCount,
                          followerCount: followerCount,
                          followingCount: followingCount,
                          isNotificationEnabled: isNotificationEnabled,
                          showAdultContent: showAdultContent,
                          preferredRegion: preferredRegion,
                          streamingProviders: streamingProviders)
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
    
    func updateStreamingProviders(userId: String, providerIds: [Int]) async throws {
        try await db.collection("users").document(userId).updateData([
            "streamingProviders": providerIds
        ])
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
                "title": movie.displayName,
                "posterPath": movie.posterPath ?? "",
                "releaseDate": movie.displayDate,
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
        
        // Pre-check: ensure we're not already friends or have pending requests
        let currentStatus = try await checkFriendshipStatus(userId: senderId, otherId: recipientId)
        guard currentStatus == .none else {
            print("Cannot send friend request - current status: \(currentStatus)")
            return
        }
        
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
        // First read current counts to prevent negative values
        let userDoc = try await db.collection("users").document(userId).getDocument(source: .server)
        let friendDoc = try await db.collection("users").document(friendId).getDocument(source: .server)
        
        let currentUserFollowers = max(0, (userDoc.data()?["followerCount"] as? Int ?? 0) - 1)
        let currentFriendFollowing = max(0, (friendDoc.data()?["followingCount"] as? Int ?? 0) - 1)
        
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
        
        // Safe decrement - clamped to 0
        let userRef = db.collection("users").document(userId)
        batch.updateData(["followerCount": currentUserFollowers], forDocument: userRef)
        
        let friendRef = db.collection("users").document(friendId)
        batch.updateData(["followingCount": currentFriendFollowing], forDocument: friendRef)
        
        try await batch.commit()
    }
    
    func checkFriendshipStatus(userId: String, otherId: String) async throws -> FriendshipStatus {
        // Force server read to bypass Firestore cache for accurate status
        let friendDoc = try await db.collection("friendships")
            .document(userId)
            .collection("friends")
            .document(otherId)
            .getDocument(source: .server)
        
        if friendDoc.exists {
            return .friends
        }
        
        // Check if request sent - force server read
        let sentRequestDoc = try await db.collection("friendRequests")
            .document(otherId)
            .collection("requests")
            .document(userId)
            .getDocument(source: .server)
        
        if sentRequestDoc.exists {
            return .requestSent
        }
        
        // Check if request received - force server read
        let receivedRequestDoc = try await db.collection("friendRequests")
            .document(userId)
            .collection("requests")
            .document(otherId)
            .getDocument(source: .server)
        
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
        
        _ = try await db.runTransaction { (transaction, _) -> Any? in
            transaction.setData(comment.dictionary, forDocument: commentRef)
            transaction.updateData(["commentCount": FieldValue.increment(Int64(1))], forDocument: listRef)
            return nil
        }
    }
    
    func deleteComment(listId: String, commentId: String) async throws {
        let listRef = db.collection("communityLists").document(listId)
        let commentRef = listRef.collection("comments").document(commentId)
        
        try await db.runTransaction { (transaction, _) -> Any? in
            transaction.updateData(["commentCount": FieldValue.increment(Int64(-1))], forDocument: listRef)
            transaction.deleteDocument(commentRef)
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
    
    func submitMovieVote(movieId: Int, movieTitle: String, moviePoster: String?, rating: String, genreTags: [String], userReview: String?, isSpoiler: Bool, user: UserProfile) async throws {
        let socialRef = db.collection("movieSocial").document("\(movieId)")
        let reviewRef = socialRef.collection("reviews").document(user.id)
        
        _ = try await db.runTransaction { (transaction, _) -> Any? in
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
            
            // 2. Check if user already reviewed
            let reviewRef = socialRef.collection("reviews").document(user.id)
            let existingDoc = try? transaction.getDocument(reviewRef)
            
            if existingDoc != nil && existingDoc!.exists {
                // Decrement old stats if updating
                if let oldReview = try? existingDoc?.data(as: MovieReview.self) {
                    stats.ratingCounts[oldReview.rating, default: 1] -= 1
                    for tag in oldReview.genreTags {
                        stats.genreConsensus[tag, default: 1] -= 1
                    }
                    // totalVotes stays the same since we're just updating
                }
            } else {
                // New vote
                stats.totalVotes += 1
            }
            
            // 3. Update stats with new values
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
                likedBy: [],
                movieTitle: movieTitle,
                moviePoster: moviePoster
            )
            let reviewData = try! Firestore.Encoder().encode(review)
            transaction.setData(reviewData, forDocument: reviewRef)
            
            return nil
        }
        
        // Log Activity (OUTSIDE transaction)
        Task {
            let activity = UserActivity(
                userId: user.id,
                type: .rating,
                movieId: movieId,
                movieTitle: movieTitle,
                moviePoster: moviePoster,
                content: userReview,
                rating: rating
            )
            try? await self.logActivity(userId: user.id, activity: activity)
        }
    }
    
    func deleteMovieReview(movieId: Int, userId: String) async throws {
        let socialRef = db.collection("movieSocial").document("\(movieId)")
        let reviewRef = socialRef.collection("reviews").document(userId)
        
        _ = try await db.runTransaction { (transaction, _) -> Any? in
            let reviewDoc: DocumentSnapshot
            do {
                reviewDoc = try transaction.getDocument(reviewRef)
            } catch {
                return nil
            }
            
            guard let review = try? reviewDoc.data(as: MovieReview.self) else { return nil }
            
            // 1. Prepare updates for stats
            var updates: [String: Any] = [
                "totalVotes": FieldValue.increment(Int64(-1)),
                "ratingCounts.\(review.rating)": FieldValue.increment(Int64(-1)),
                "lastUpdated": Date()
            ]
            
            // 2. Decrement genre tag counts
            for tag in review.genreTags {
                updates["genreConsensus.\(tag)"] = FieldValue.increment(Int64(-1))
            }
            
            transaction.updateData(updates, forDocument: socialRef)
            
            // 3. Delete review
            transaction.deleteDocument(reviewRef)
            
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
    
    func toggleReviewLike(movieId: Int, movieTitle: String, moviePoster: String?, reviewId: String, userId: String) async throws {
        let reviewRef = db.collection("movieSocial")
            .document("\(movieId)")
            .collection("reviews")
            .document(reviewId)
            
        var isLiking = false
        
        _ = try await db.runTransaction { (transaction, _) -> Any? in
            let reviewDoc: DocumentSnapshot
            do {
                reviewDoc = try transaction.getDocument(reviewRef)
            } catch {
                return nil
            }
            
            guard var review = try? reviewDoc.data(as: MovieReview.self) else { return nil }
            
            isLiking = !review.likedBy.contains(userId)
            
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
        
        // Log Activity (OUTSIDE transaction)
        if isLiking {
            Task {
                let activity = UserActivity(
                    userId: userId,
                    type: .like,
                    movieId: movieId,
                    movieTitle: movieTitle,
                    moviePoster: moviePoster
                )
                try? await self.logActivity(userId: userId, activity: activity)
            }
        }
    }
    
    func submitMovieReply(movieId: Int, movieTitle: String, moviePoster: String?, reviewId: String, content: String, user: UserProfile) async throws {
        let reviewRef = db.collection("movieSocial")
            .document("\(movieId)")
            .collection("reviews")
            .document(reviewId)
        let replyRef = reviewRef.collection("replies").document()
        
        _ = try await db.runTransaction { (transaction, _) -> Any? in
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
        
        // Log Activity (OUTSIDE transaction)
        Task {
            let activity = UserActivity(
                userId: user.id,
                type: .reply,
                movieId: movieId,
                movieTitle: movieTitle,
                moviePoster: moviePoster,
                content: content
            )
            try? await self.logActivity(userId: user.id, activity: activity)
        }
    }
    
    func deleteMovieReply(movieId: Int, reviewId: String, replyId: String) async throws {
        let reviewRef = db.collection("movieSocial")
            .document("\(movieId)")
            .collection("reviews")
            .document(reviewId)
        let replyRef = reviewRef.collection("replies").document(replyId)
        
        _ = try await db.runTransaction { (transaction, _) -> Any? in
            transaction.updateData(["repliesCount": FieldValue.increment(Int64(-1))], forDocument: reviewRef)
            transaction.deleteDocument(replyRef)
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
    
    // MARK: - User Activity & Stats
    func logActivity(userId: String, activity: UserActivity) async throws {
        let activityRef = db.collection("users").document(userId).collection("activities").document()
        try activityRef.setData(from: activity)
        
        // Update stats
        try await updateUserStats(userId: userId, activityType: activity.type, rating: activity.rating)
    }
    
    func fetchUserActivities(userId: String, limit: Int = 50) async throws -> [UserActivity] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("activities")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
            
        return snapshot.documents.compactMap { try? $0.data(as: UserActivity.self) }
    }
    
    func getUserStats(userId: String) async throws -> UserStats {
        let docRef = db.collection("users").document(userId).collection("stats").document("main")
        let doc = try await docRef.getDocument()
        
        if doc.exists {
            return (try? doc.data(as: UserStats.self)) ?? UserStats()
        }
        return UserStats()
    }
    
    /// Synchronizes past community reviews into the activity log
    func syncPastActivities(userId: String) async throws {
        // 1. Fetch existing activities to avoid duplicates
        let existingActivities = try await fetchUserActivities(userId: userId, limit: 1000)
        let existingRatingKeys = Set(existingActivities.filter { $0.type == .rating }.map { String($0.movieId) })
        
        // 2. Fetch watch history to use as a title/poster cache
        let history = try? await fetchHistory(userId: userId)
        let historyCache = Dictionary(uniqueKeysWithValues: (history ?? []).map { ("\($0.id)", ($0.title, $0.posterPath)) })
        
        // 3. Query all reviews by this user across all movies
        let snapshot = try await db.collectionGroup("reviews")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
            
        for doc in snapshot.documents {
            // The movie ID is the parent document ID
            guard let movieIdString = doc.reference.parent.parent?.documentID,
                  !existingRatingKeys.contains(movieIdString) else { continue }
            
            guard let review = try? doc.data(as: MovieReview.self),
                  let movieId = Int(movieIdString) else { continue }
            
            // Try to get movie info from review itself (new format) or history cache (old format)
            var title = review.movieTitle ?? "Movie \(movieId)"
            var poster = review.moviePoster
            
            if let cached = historyCache[movieIdString] {
                title = cached.0
                poster = cached.1
            }
            
            // Create activity
            let activity = UserActivity(
                userId: userId,
                type: .rating,
                movieId: movieId,
                movieTitle: title,
                moviePoster: poster,
                content: review.content,
                rating: review.rating,
                timestamp: review.timestamp
            )
            
            // Save activity
            let activityRef = db.collection("users").document(userId).collection("activities").document()
            try activityRef.setData(from: activity)
            
            // Update stats for each newly found review
            try? await self.updateUserStats(userId: userId, activityType: .rating, rating: review.rating)
        }
        
        // 4. Query all REPLIES by this user
        let repliesSnapshot = try await db.collectionGroup("replies")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
            
        for doc in repliesSnapshot.documents {
            // Check if activity already exists
            let existing = try await db.collection("users").document(userId).collection("activities")
                .whereField("type", isEqualTo: ActivityType.reply.rawValue)
                .whereField("timestamp", isEqualTo: doc.get("timestamp") ?? Date())
                .getDocuments()
            
            if existing.isEmpty {
                if let reply = try? doc.data(as: MovieReply.self) {
                    // Try to get movie info from history or parent chain
                    // For simplicity in replies, we'll try to find the movie ID from the path
                    let path = doc.reference.path // "movieSocial/123/reviews/abc/replies/xyz"
                    let parts = path.components(separatedBy: "/")
                    if parts.count >= 2, let movieId = Int(parts[1]) {
                        var title = "Movie \(movieId)"
                        var poster: String? = nil
                        if let cached = historyCache["\(movieId)"] {
                            title = cached.0
                            poster = cached.1
                        }
                        
                        let activity = UserActivity(
                            userId: userId,
                            type: .reply,
                            movieId: movieId,
                            movieTitle: title,
                            moviePoster: poster,
                            content: reply.content,
                            timestamp: reply.timestamp
                        )
                        try db.collection("users").document(userId).collection("activities").addDocument(from: activity)
                        try? await self.updateUserStats(userId: userId, activityType: .reply)
                    }
                }
            }
        }
        
        // 5. Query all LIKES (Reviews the user liked)
        let likesSnapshot = try await db.collectionGroup("reviews")
            .whereField("likedBy", arrayContains: userId)
            .getDocuments()
            
        for doc in likesSnapshot.documents {
            let movieIdString = doc.reference.parent.parent?.documentID ?? ""
            guard let movieId = Int(movieIdString) else { continue }
            
            // Check if "like" activity already exists for this movie
            // Note: This is simpler than checking specific review IDs for now
            let existing = try await db.collection("users").document(userId).collection("activities")
                .whereField("type", isEqualTo: ActivityType.like.rawValue)
                .whereField("movieId", isEqualTo: movieId)
                .getDocuments()
            
            if existing.isEmpty {
                var title = "Movie \(movieId)"
                var poster: String? = nil
                if let cached = historyCache[movieIdString] {
                    title = cached.0
                    poster = cached.1
                }
                
                let activity = UserActivity(
                    userId: userId,
                    type: .like,
                    movieId: movieId,
                    movieTitle: title,
                    moviePoster: poster
                )
                try db.collection("users").document(userId).collection("activities").addDocument(from: activity)
                try? await self.updateUserStats(userId: userId, activityType: .like)
            }
        }
    }
    
    private func updateUserStats(userId: String, activityType: ActivityType, rating: String? = nil) async throws {
        let statsRef = db.collection("users").document(userId).collection("stats").document("main")
        
        _ = try await db.runTransaction { (transaction, _) -> Any? in
            let statsDoc: DocumentSnapshot
            do {
                statsDoc = try transaction.getDocument(statsRef)
            } catch {
                return nil
            }
            
            var stats = (try? statsDoc.data(as: UserStats.self)) ?? UserStats()
            
            // Update counters
            switch activityType {
            case .rating:
                stats.totalRatings += 1
                if let r = rating {
                    stats.ratingBreakdown[r, default: 0] += 1
                }
            case .comment:
                stats.totalComments += 1
            case .reply:
                stats.totalReplies += 1
            case .like:
                stats.totalLikes += 1
            }
            
            // Update streak
            let now = Date()
            if let lastDate = stats.lastActivityDate {
                let calendar = Calendar.current
                if calendar.isDateInYesterday(lastDate) {
                    stats.currentStreak += 1
                } else if !calendar.isDateInToday(lastDate) {
                    stats.currentStreak = 1
                }
                // If already active today, do nothing to streak
            } else {
                stats.currentStreak = 1
            }
            
            if stats.currentStreak > stats.longestStreak {
                stats.longestStreak = stats.currentStreak
            }
            
            stats.lastActivityDate = now
            
            let statsData = try! Firestore.Encoder().encode(stats)
            transaction.setData(statsData, forDocument: statsRef, merge: true)
            return nil
        }
    }
    // MARK: - Movie Nudges (Direct Recommendations)
    
    func sendRecommendation(sender: UserProfile, recipientId: String, movieId: Int, movieTitle: String, moviePoster: String?, note: String) async throws {
        let recommendation = MovieRecommendation(
            senderId: sender.id,
            senderName: sender.username ?? sender.name,
            senderPhoto: sender.photoURL?.absoluteString,
            recipientId: recipientId,
            movieId: movieId,
            movieTitle: movieTitle,
            moviePoster: moviePoster,
            note: note,
            timestamp: Date(),
            reaction: nil,
            isRead: false
        )
        
        try db.collection("recommendations").addDocument(from: recommendation)
    }
    
    func fetchRecommendations(userId: String) async throws -> [MovieRecommendation] {
        let snapshot = try await db.collection("recommendations")
            .whereField("recipientId", isEqualTo: userId)
            .getDocuments()
        
        let recs = snapshot.documents.compactMap { try? $0.data(as: MovieRecommendation.self) }
        return recs.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    func updateRecommendationReaction(recommendationId: String, reaction: String) async throws {
        try await db.collection("recommendations").document(recommendationId).updateData([
            "reaction": reaction
        ])
    }
    
    func markRecommendationAsRead(recommendationId: String) async throws {
        try await db.collection("recommendations").document(recommendationId).updateData([
            "isRead": true
        ])
    }
    
    // MARK: - Global Polls
    func createPoll(poll: MoviePoll) async throws {
        _ = try db.collection("polls").addDocument(from: poll)
    }
    
    func fetchAllPollsAdmin() async throws -> [MoviePoll] {
        let snapshot = try await db.collection("polls")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: MoviePoll.self) }
    }
    
    func fetchActivePolls() async throws -> [MoviePoll] {
        let snapshot = try await db.collection("polls")
            .order(by: "createdAt", descending: true)
            .limit(to: 5)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: MoviePoll.self) }
    }
    
    func submitPollVote(pollId: String, optionIndex: Int, userId: String) async throws {
        let pollRef = db.collection("polls").document(pollId)
        
        _ = try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            let pollDocument: DocumentSnapshot
            do {
                pollDocument = try transaction.getDocument(pollRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let poll = try? pollDocument.data(as: MoviePoll.self) else {
                let error = NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Poll not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            if poll.isFinalized { return nil }
            if let expires = poll.expiresAt, expires < Date() { return nil }
            if poll.votedUserIds.contains(userId) { return nil }
            
            var newVotes = poll.votes
            if optionIndex < newVotes.count {
                newVotes[optionIndex] += 1
            }
            
            var newVotedIds = poll.votedUserIds
            newVotedIds.append(userId)
            
            transaction.updateData([
                "votes": newVotes,
                "votedUserIds": newVotedIds
            ], forDocument: pollRef)
            
            return nil
        })
    }
    
    func fetchAllUsers() async throws -> [UserProfile] {
        let snapshot = try await db.collection("users").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: UserProfile.self) }
    }
    
    func updateUserRole(userId: String, isAdmin: Bool) async throws {
        try await db.collection("users").document(userId).updateData(["isAdmin": isAdmin])
    }
    
    // MARK: - Staff Picks
    func toggleFeaturedList(listId: String, isFeatured: Bool) async throws {
        try await db.collection("communityLists").document(listId).updateData([
            "isFeatured": isFeatured,
            "updatedAt": Timestamp()
        ])
    }
    
    func fetchFeaturedLists() async throws -> [CommunityList] {
        let snapshot = try await db.collection("communityLists")
            .whereField("isFeatured", isEqualTo: true)
            .limit(to: 20)
            .getDocuments()
        
        let lists = parseCommunityLists(from: snapshot)
        return lists.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // MARK: - Staff Pick Movies
    func addStaffPickMovie(movie: Movie) async throws {
        let staffPick = StaffPickMovie(movie: movie)
        try db.collection("staffPickMovies").document("\(movie.id)").setData(from: staffPick)
    }
    
    func removeStaffPickMovie(movieId: Int) async throws {
        try await db.collection("staffPickMovies").document("\(movieId)").delete()
    }
    
    func fetchStaffPickMovies() async throws -> [Movie] {
        let snapshot = try await db.collection("staffPickMovies")
            .order(by: "addedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> Movie? in
            guard let pick = try? doc.data(as: StaffPickMovie.self) else { return nil }
            return pick.movie
        }
    }
    
    func banUser(userId: String, isBanned: Bool) async throws {
        try await db.collection("users").document(userId).updateData(["isBanned": isBanned])
    }
    
    // MARK: - Platform Analytics
    func fetchPlatformAnalytics() async throws -> [String: Any] {
        // In a production app, these would be cached or use Firestore Aggregations
        // For now, we'll do simple counting for the dashboard
        let usersCount = try await db.collection("users").count.getAggregation(source: .server).count
        let listsCount = try await db.collection("communityLists").count.getAggregation(source: .server).count
        let pollsCount = try await db.collection("polls").count.getAggregation(source: .server).count
        
        // New users this week
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let newUsersSnapshot = try await db.collection("users")
            .whereField("lastLogin", isGreaterThanOrEqualTo: Timestamp(date: weekAgo))
            .getDocuments()
            
        return [
            "totalUsers": Int(truncating: usersCount as NSNumber),
            "totalLists": Int(truncating: listsCount as NSNumber),
            "totalPolls": Int(truncating: pollsCount as NSNumber),
            "newUsersWeek": newUsersSnapshot.documents.count
        ]
    }
}

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
