import Foundation
import FirebaseFirestore

struct CommunityReply: Codable, Identifiable {
    @DocumentID var id: String?
    let text: String
    let userId: String
    let userName: String
    let userUsername: String
    let userPhotoURL: String?
    let createdAt: Date
    var likeCount: Int = 0
    var likedUserIds: [String] = []
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case userId
        case userName
        case userUsername
        case userPhotoURL
        case createdAt
        case likeCount
        case likedUserIds
    }
}
