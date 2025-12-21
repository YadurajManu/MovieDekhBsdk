import Foundation
import FirebaseFirestore


struct MovieRecommendation: Codable, Identifiable {
    @DocumentID var id: String?
    let senderId: String
    let senderName: String
    let senderPhoto: String?
    let recipientId: String
    let movieId: Int
    let movieTitle: String
    let moviePoster: String?
    let note: String
    let timestamp: Date
    var reaction: String? // Optional emoji reaction
    var isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case senderName
        case senderPhoto
        case recipientId
        case movieId
        case movieTitle
        case moviePoster
        case note
        case timestamp
        case reaction
        case isRead
    }
}
