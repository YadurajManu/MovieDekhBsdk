import Foundation

// MARK: - Trakt Models

struct TraktMovie: Codable, Identifiable {
    let ids: TraktIDs
    let title: String
    let year: Int?
    let overview: String?
    
    var id: Int { ids.tmdb ?? ids.trakt }
    
    struct TraktIDs: Codable {
        let trakt: Int
        let tmdb: Int?
        let imdb: String?
    }
}

struct TraktWatchHistory: Codable, Identifiable {
    let id: Int
    let watchedAt: String
    let action: String
    let type: String
    let movie: TraktMovie?
    
    enum CodingKeys: String, CodingKey {
        case id, action, type, movie
        case watchedAt = "watched_at"
    }
    
    var watchedDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: watchedAt)
    }
}

struct TraktStats: Codable {
    let movies: MovieStats
    
    struct MovieStats: Codable {
        let watched: Int
        let collected: Int
        let ratings: Int
        let comments: Int
        let plays: Int
        let minutes: Int
    }
    
    var totalWatchTime: String {
        let hours = movies.minutes / 60
        let days = hours / 24
        if days > 0 {
            return "\(days)d \(hours % 24)h"
        }
        return "\(hours)h"
    }
}

struct TraktList: Codable, Identifiable {
    let ids: ListIDs
    let name: String
    let description: String?
    let privacy: String
    let displayNumbers: Bool
    let allowComments: Bool
    let sortBy: String
    let sortHow: String
    let createdAt: String
    let updatedAt: String
    let itemCount: Int
    let commentCount: Int
    let likes: Int
    
    var id: Int { ids.trakt }
    
    struct ListIDs: Codable {
        let trakt: Int
        let slug: String
    }
    
    enum CodingKeys: String, CodingKey {
        case ids, name, description, privacy, likes
        case displayNumbers = "display_numbers"
        case allowComments = "allow_comments"
        case sortBy = "sort_by"
        case sortHow = "sort_how"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case itemCount = "item_count"
        case commentCount = "comment_count"
    }
}

struct TraktListItem: Codable, Identifiable {
    let id: Int
    let rank: Int
    let listedAt: String
    let type: String
    let movie: TraktMovie?
    
    enum CodingKeys: String, CodingKey {
        case id, rank, type, movie
        case listedAt = "listed_at"
    }
}

struct TraktUser: Codable {
    let username: String
    let name: String?
    let vip: Bool
    let vipEp: Bool
    let ids: UserIDs
    let joinedAt: String?
    let location: String?
    let about: String?
    let gender: String?
    let age: Int?
    let images: UserImages?
    
    struct UserIDs: Codable {
        let slug: String
    }
    
    struct UserImages: Codable {
        let avatar: Avatar?
        
        struct Avatar: Codable {
            let full: String?
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case username, name, vip, ids, location, about, gender, age, images
        case vipEp = "vip_ep"
        case joinedAt = "joined_at"
    }
}

// MARK: - OAuth Models

struct TraktAuthTokens: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let scope: String
    let createdAt: Int
    
    enum CodingKeys: String, CodingKey {
        case scope
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case createdAt = "created_at"
    }
    
    var isExpired: Bool {
        let expirationDate = Date(timeIntervalSince1970: TimeInterval(createdAt + expiresIn))
        return Date() > expirationDate
    }
}

// MARK: - Request/Response Models

struct ScrobbleRequest: Codable {
    let movie: MovieIdentifier
    let progress: Double
    let appVersion: String
    let appDate: String
    
    struct MovieIdentifier: Codable {
        let ids: IDs
        
        struct IDs: Codable {
            let tmdb: Int
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case movie, progress
        case appVersion = "app_version"
        case appDate = "app_date"
    }
}

struct AddToListRequest: Codable {
    let movies: [MovieIdentifier]
    
    struct MovieIdentifier: Codable {
        let ids: IDs
        
        struct IDs: Codable {
            let tmdb: Int
        }
    }
}
