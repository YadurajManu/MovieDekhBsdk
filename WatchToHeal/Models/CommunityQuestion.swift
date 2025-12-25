import Foundation
import FirebaseFirestore

struct CommunityQuestion: Codable, Identifiable {
    @DocumentID var id: String?
    let text: String
    let creatorId: String
    let creatorName: String
    let creatorUsername: String
    let creatorPhotoURL: String?
    let createdAt: Date
    var likeCount: Int = 0
    var likedUserIds: [String] = []
    var replyCount: Int = 0
    
    // Engagement Metrics (for smart feed sections)
    var engagementScore: Double? = 0.0
    var lastActivityAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case creatorId
        case creatorName
        case creatorUsername
        case creatorPhotoURL
        case createdAt
        case likeCount
        case likedUserIds
        case replyCount
        case engagementScore
        case lastActivityAt
    }
    
    // Memberwise initializer for creating new instances
    init(id: String? = nil, text: String, creatorId: String, creatorName: String, creatorUsername: String, creatorPhotoURL: String?, createdAt: Date, likeCount: Int = 0, likedUserIds: [String] = [], replyCount: Int = 0, engagementScore: Double? = 0.0, lastActivityAt: Date? = nil) {
        self.id = id
        self.text = text
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.creatorUsername = creatorUsername
        self.creatorPhotoURL = creatorPhotoURL
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.likedUserIds = likedUserIds
        self.replyCount = replyCount
        self.engagementScore = engagementScore
        self.lastActivityAt = lastActivityAt ?? createdAt
    }
}
