import Foundation

enum PulseFeedSection: String, CaseIterable, Identifiable {
    case trending = "🔥 Trending Polls"
    case hotDebates = "💬 Hot Debates"
    case latest = "✨ Latest"
    case topContributors = "👑 Top Contributors"
    case yourContent = "🎬 By You"
    
    var id: String { rawValue }
    
    var limit: Int {
        switch self {
        case .trending, .hotDebates: return 5
        case .latest: return 10
        case .topContributors: return 3
        case .yourContent: return 5
        }
    }
    
    var icon: String {
        switch self {
        case .trending: return "flame.fill"
        case .hotDebates: return "bubble.left.and.bubble.right.fill"
        case .latest: return "sparkles"
        case .topContributors: return "crown.fill"
        case .yourContent: return "person.crop.circle.fill"
        }
    }
}

struct ContributorProfile: Identifiable, Codable {
    let id: String // User ID
    let username: String
    let photoURL: String?
    var totalEngagement: Double = 0.0 // Sum of engagement from their posts
    var postCount: Int = 0
    var latestPost: PulseItem?
    
    enum CodingKeys: String, CodingKey {
        case id, username, photoURL, totalEngagement, postCount
    }
}
