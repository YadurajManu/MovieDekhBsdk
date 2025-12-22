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
    private let movieTitle: String
    private let moviePoster: String?
    
    init(movieId: Int, movieTitle: String, moviePoster: String?) {
        self.movieId = movieId
        self.movieTitle = movieTitle
        self.moviePoster = moviePoster
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
                movieTitle: movieTitle,
                moviePoster: moviePoster,
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
        print("🔄 MovieSocialViewModel.toggleLike called - reviewId: \(reviewId), userId: \(userId)")
        do {
            try await firestoreService.toggleReviewLike(
                movieId: movieId,
                movieTitle: movieTitle,
                moviePoster: moviePoster,
                reviewId: reviewId,
                userId: userId
            )
            print("✅ Like toggled successfully")
            // Optimistic update or refresh
            await loadSocialData()
        } catch {
            print("❌ Error toggling like: \(error)")
        }
    }
    
    func postReply(reviewId: String, content: String, user: UserProfile) async {
        print("🔄 MovieSocialViewModel.postReply called - reviewId: \(reviewId), content: \(content)")
        do {
            try await firestoreService.submitMovieReply(
                movieId: movieId,
                movieTitle: movieTitle,
                moviePoster: moviePoster,
                reviewId: reviewId,
                content: content,
                user: user
            )
            print("✅ Reply posted successfully")
            // Refresh data to show new reply count and potentially fetch replies
            await loadSocialData()
        } catch {
            print("❌ Error posting reply: \(error)")
        }
    }
    
    func deleteReview(userId: String) async {
        print("🔄 MovieSocialViewModel.deleteReview called - userId: \(userId)")
        do {
            try await firestoreService.deleteMovieReview(movieId: movieId, userId: userId)
            print("✅ Review deleted successfully")
            await loadSocialData()
        } catch {
            print("❌ Error deleting review: \(error)")
        }
    }
    
    func deleteReply(reviewId: String, replyId: String) async {
        print("🔄 MovieSocialViewModel.deleteReply called - reviewId: \(reviewId), replyId: \(replyId)")
        do {
            try await firestoreService.deleteMovieReply(movieId: movieId, reviewId: reviewId, replyId: replyId)
            print("✅ Reply deleted successfully")
            await loadSocialData()
        } catch {
            print("❌ Error deleting reply: \(error)")
        }
    }
}
