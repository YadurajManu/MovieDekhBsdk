import Foundation
import Combine

@MainActor
class MovieSocialViewModel: ObservableObject {
    @Published var stats = MovieSocialStats()
    @Published var reviews: [MovieReview] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    
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
    
    func submitVote(rating: String, genreTags: [String], review: String?, user: UserProfile) async {
        isSubmitting = true
        defer { isSubmitting = false }
        
        do {
            try await firestoreService.submitMovieVote(
                movieId: movieId,
                rating: rating,
                genreTags: genreTags,
                userReview: review,
                user: user
            )
            // Refresh data
            await loadSocialData()
        } catch {
            print("Error submitting vote: \(error)")
        }
    }
}
