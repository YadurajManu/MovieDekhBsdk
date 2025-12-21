import Foundation
import FirebaseFirestore

enum ActivityType: String, Codable {
    case rating
    case comment
    case reply
    case like
}

struct UserActivity: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let type: ActivityType
    let movieId: Int
    let movieTitle: String
    let moviePoster: String?
    let content: String? // For comments/replies
    let rating: String? // For ratings (absolute, awaara, bakwas)
    let timestamp: Date
    
    init(userId: String, type: ActivityType, movieId: Int, movieTitle: String, moviePoster: String?, content: String? = nil, rating: String? = nil, timestamp: Date = Date()) {
        self.userId = userId
        self.type = type
        self.movieId = movieId
        self.movieTitle = movieTitle
        self.moviePoster = moviePoster
        self.content = content
        self.rating = rating
        self.timestamp = timestamp
    }
}

struct UserStats: Codable {
    var totalRatings: Int = 0
    var totalComments: Int = 0
    var totalReplies: Int = 0
    var totalLikes: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActivityDate: Date?
    var ratingBreakdown: [String: Int] = [:] // "absolute": 5, "awaara": 3, "bakwas": 2
    
    enum CodingKeys: String, CodingKey {
        case totalRatings
        case totalComments
        case totalReplies
        case totalLikes
        case currentStreak
        case longestStreak
        case lastActivityDate
        case ratingBreakdown
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalRatings = try container.decodeIfPresent(Int.self, forKey: .totalRatings) ?? 0
        totalComments = try container.decodeIfPresent(Int.self, forKey: .totalComments) ?? 0
        totalReplies = try container.decodeIfPresent(Int.self, forKey: .totalReplies) ?? 0
        totalLikes = try container.decodeIfPresent(Int.self, forKey: .totalLikes) ?? 0
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        longestStreak = try container.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        lastActivityDate = try container.decodeIfPresent(Date.self, forKey: .lastActivityDate)
        ratingBreakdown = try container.decodeIfPresent([String: Int].self, forKey: .ratingBreakdown) ?? [:]
    }
    
    init() {}
}
