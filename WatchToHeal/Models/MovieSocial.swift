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
    
    // Consensus Meter Logic
    var consensusScore: Double {
        guard totalVotes > 0 else { return 0 }
        let absolute = Double(ratingCounts["absolute"] ?? 0)
        let awaara = Double(ratingCounts["awaara"] ?? 0)
        // bakwas is 0 weight
        return (absolute + (awaara * 0.5)) / Double(totalVotes)
    }
    
    var approvalRating: Int {
        Int(consensusScore * 100)
    }
    
    var consensusLabel: String {
        guard totalVotes > 0 else { return "NOT RATED" }
        let score = consensusScore
        if score >= 0.85 { return "MUST WATCH" }
        if score >= 0.70 { return "SOLID PICK" }
        if score >= 0.50 { return "MIXED BAGS" }
        if score >= 0.30 { return "SKIP IT" }
        return "AVOID IT"
    }
    
    var consensusColor: String {
        let score = consensusScore
        if score >= 0.70 { return "appPrimary" }
        if score >= 0.40 { return "orange" }
        return "red"
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
    var isSpoiler: Bool
    var likesCount: Int
    var repliesCount: Int
    var likedBy: [String]
    var movieTitle: String? // Added for activity log backfill
    var moviePoster: String? // Added for activity log backfill
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case username
        case userPhoto
        case content
        case rating
        case genreTags
        case timestamp
        case isSpoiler
        case likesCount
        case repliesCount
        case likedBy
        case movieTitle
        case moviePoster
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        username = try container.decode(String.self, forKey: .username)
        userPhoto = try container.decodeIfPresent(String.self, forKey: .userPhoto)
        content = try container.decode(String.self, forKey: .content)
        rating = try container.decode(String.self, forKey: .rating)
        genreTags = try container.decode([String].self, forKey: .genreTags)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isSpoiler = try container.decodeIfPresent(Bool.self, forKey: .isSpoiler) ?? false
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount) ?? 0
        repliesCount = try container.decodeIfPresent(Int.self, forKey: .repliesCount) ?? 0
        likedBy = try container.decodeIfPresent([String].self, forKey: .likedBy) ?? []
        movieTitle = try container.decodeIfPresent(String.self, forKey: .movieTitle)
        moviePoster = try container.decodeIfPresent(String.self, forKey: .moviePoster)
    }
    
    init(userId: String, username: String, userPhoto: String?, content: String, rating: String, genreTags: [String], timestamp: Date, isSpoiler: Bool, likesCount: Int, repliesCount: Int, likedBy: [String], movieTitle: String? = nil, moviePoster: String? = nil) {
        self.userId = userId
        self.username = username
        self.userPhoto = userPhoto
        self.content = content
        self.rating = rating
        self.genreTags = genreTags
        self.timestamp = timestamp
        self.isSpoiler = isSpoiler
        self.likesCount = likesCount
        self.repliesCount = repliesCount
        self.likedBy = likedBy
        self.movieTitle = movieTitle
        self.moviePoster = moviePoster
    }
}

struct MovieReply: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    let userPhoto: String?
    let content: String
    let timestamp: Date
    var likesCount: Int = 0
    var likedBy: [String] = []
}
