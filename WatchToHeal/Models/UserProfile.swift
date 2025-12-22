import Foundation

struct UserProfile: Codable, Identifiable, Hashable {
    let id: String
    var username: String?
    var name: String
    var email: String
    var bio: String
    var photoURL: URL?
    var topFavorites: [Movie]
    var isAdmin: Bool = false
    var isBanned: Bool = false
    
    // Social Stats
    var followerCount: Int = 0
    var followingCount: Int = 0
    
    // Preferences
    var isNotificationEnabled: Bool
    var showAdultContent: Bool
    var preferredRegion: String
    var streamingProviders: [Int] // IDs of preferred streaming services
    
    // Authority Stats
    var isVerified: Bool = false
    var watchedCount: Int = 0
    
    // Compatibility init for legacy calls or linker expectations
    init(id: String, 
         username: String? = nil,
         name: String, 
         email: String, 
         bio: String = "", 
         photoURL: URL? = nil, 
         topFavorites: [Movie] = [],
         isAdmin: Bool = false,
         isVerified: Bool = false,
         watchedCount: Int = 0,
         preferredRegion: String = "IN",
         streamingProviders: [Int] = []) {
        self.id = id
        self.username = username
        self.name = name
        self.email = email
        self.bio = bio
        self.photoURL = photoURL
        self.topFavorites = topFavorites
        self.isAdmin = isAdmin
        self.isVerified = isVerified
        self.watchedCount = watchedCount
        self.followerCount = 0
        self.followingCount = 0
        self.isNotificationEnabled = true
        self.showAdultContent = false
        self.preferredRegion = preferredRegion
        self.streamingProviders = streamingProviders
    }

    // Full init
    init(id: String, 
         username: String?,
         name: String, 
         email: String, 
         bio: String, 
         photoURL: URL?, 
         topFavorites: [Movie],
         isAdmin: Bool = false,
         isVerified: Bool = false,
         watchedCount: Int = 0,
         followerCount: Int = 0,
         followingCount: Int = 0,
         isNotificationEnabled: Bool,
         showAdultContent: Bool,
         preferredRegion: String,
         streamingProviders: [Int]) {
        self.id = id
        self.username = username
        self.name = name
        self.email = email
        self.bio = bio
        self.photoURL = photoURL
        self.topFavorites = topFavorites
        self.isAdmin = isAdmin
        self.isVerified = isVerified
        self.watchedCount = watchedCount
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.isNotificationEnabled = isNotificationEnabled
        self.showAdultContent = showAdultContent
        self.preferredRegion = preferredRegion
        self.streamingProviders = streamingProviders
    }
}
