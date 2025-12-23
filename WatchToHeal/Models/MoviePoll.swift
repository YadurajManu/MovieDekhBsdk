import Foundation
import FirebaseFirestore


struct PollOptionData: Codable, Identifiable {
    var id = UUID()
    let text: String
    var movieId: Int?
    var posterPath: String?
    var secondaryInfo: String? // e.g., Director Name or Year
    
    enum CodingKeys: String, CodingKey {
        case text
        case movieId
        case posterPath
        case secondaryInfo
    }
}

enum PollType: String, Codable {
    case text
    case movie
}

struct MoviePoll: Codable, Identifiable {
    @DocumentID var id: String?
    let question: String
    let options: [PollOptionData]
    var votes: [Int] // Index-based vote counts
    var votedUserIds: [String]
    let createdAt: Date
    let expiresAt: Date?
    var isFinalized: Bool
    let type: PollType
    
    // Creator Info
    var creatorId: String? // nil for Official/Admin polls
    var creatorName: String?
    var creatorUsername: String?
    var creatorPhotoURL: String?
    
    // Social Features
    var likedUserIds: [String] = []
    var category: String? // e.g., "Battle", "Versus", "Recommendation"
    
    var totalVotes: Int {
        votes.reduce(0, +)
    }
    
    // Optional: Global linkage
    let globalMovieId: Int?
    let globalMovieTitle: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case question
        case options
        case votes
        case votedUserIds
        case createdAt
        case expiresAt
        case isFinalized
        case type
        case creatorId
        case creatorName
        case creatorUsername
        case creatorPhotoURL
        case likedUserIds
        case category
        case globalMovieId
        case globalMovieTitle
    }
}
