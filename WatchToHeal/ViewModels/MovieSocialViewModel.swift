import Foundation
import Combine

@MainActor
class MovieSocialViewModel: ObservableObject {
    @Published var stats = MovieSocialStats()
    @Published var reviews: [MovieReview] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    
    // Filtering & Sorting
    @Published var showSpoilers = false
    @Published var followingOnly = false
    @Published var sortOption: SortOption = .mostRecent
    
    enum SortOption {
        case mostRecent, mostLiked
    }
    
    var filteredReviews: [MovieReview] {
        var result = reviews
        
        // Filter out spoilers if not enabled
        if !showSpoilers {
            result = result.filter { !$0.isSpoiler }
        }
        
        // Sort
        switch sortOption {
        case .mostRecent:
            result.sort { $0.timestamp > $1.timestamp }
        case .mostLiked:
            result.sort { $0.likesCount > $1.likesCount }
        }
        
        return result
    }
    
    private let firestoreService = FirestoreService.shared
    private let movieId: Int
    
    init(movieId: Int) {
        self.movieId = movieId
    }
    
    func loadSocialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let fetchedStats = firestoreService.getMovieSocialStats(movieId: movieId)
            async let fetchedReviews = firestoreService.fetchMovieReviews(movieId: movieId)
            
            self.stats = try await fetchedStats
            self.reviews = try await fetchedReviews
        } catch {
            print("Error loading social data: \(error)")
        }
    }
    
    func submitVote(rating: String, genreTags: [String], review: String?, isSpoiler: Bool, user: UserProfile) async {
        isSubmitting = true
        defer { isSubmitting = false }
        
        do {
            try await firestoreService.submitMovieVote(
                movieId: movieId,
                rating: rating,
                genreTags: genreTags,
                userReview: review,
                isSpoiler: isSpoiler,
                user: user
            )
            // Refresh data
            await loadSocialData()
        } catch {
            print("Error submitting vote: \(error)")
        }
    }
    
    func toggleLike(reviewId: String, userId: String) async {
        do {
            try await firestoreService.toggleReviewLike(movieId: movieId, reviewId: reviewId, userId: userId)
            // Optimistic update or refresh
            await loadSocialData()
        } catch {
            print("Error toggling like: \(error)")
        }
    }
    
    func postReply(reviewId: String, content: String, user: UserProfile) async {
        do {
            try await firestoreService.submitMovieReply(movieId: movieId, reviewId: reviewId, content: content, user: user)
            // Refresh data to show new reply count and potentially fetch replies
            await loadSocialData()
        } catch {
            print("Error posting reply: \(error)")
        }
    }
    
    func fetchReplies(reviewId: String) async -> [MovieReply] {
        do {
            return try await firestoreService.fetchMovieReplies(movieId: movieId, reviewId: reviewId)
        } catch {
            print("Error fetching replies: \(error)")
            return []
        }
    }
}
