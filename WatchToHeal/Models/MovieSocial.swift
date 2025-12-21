import Foundation
import FirebaseFirestore

struct MovieSocialStats: Codable {
    var ratingCounts: [String: Int] = ["absolute": 0, "awaara": 0, "bakwas": 0]
    var genreConsensus: [String: Int] = [:]
    var totalVotes: Int = 0
    var lastUpdated: Date = Date()
    
    var absolutePercentage: Double {
        totalVotes == 0 ? 0 : (Double(ratingCounts["absolute"] ?? 0) / Double(totalVotes)) * 100
    }
    
    var awaaraPercentage: Double {
        totalVotes == 0 ? 0 : (Double(ratingCounts["awaara"] ?? 0) / Double(totalVotes)) * 100
    }
    
    var bakwasPercentage: Double {
        totalVotes == 0 ? 0 : (Double(ratingCounts["bakwas"] ?? 0) / Double(totalVotes)) * 100
    }
}

struct MovieReview: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    let userPhoto: String?
    let content: String
    let rating: String // absolute, awaara, bakwas
    let genreTags: [String]
    let timestamp: Date
}
