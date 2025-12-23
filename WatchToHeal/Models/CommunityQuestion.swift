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
    }
}
