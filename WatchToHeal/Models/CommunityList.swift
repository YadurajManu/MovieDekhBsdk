import Foundation
import FirebaseFirestore

struct CommunityList: Identifiable, Codable, Hashable {
    let id: String
    let ownerId: String
    let ownerName: String
    var title: String
    var description: String
    var movies: [Movie]
    var isRanked: Bool
    var isFeatured: Bool
    var tags: [String]
    var likeCount: Int
    var commentCount: Int
    var likedBy: [String]
    let createdAt: Date
    var updatedAt: Date
    
    init(id: String, ownerId: String, ownerName: String, title: String, description: String, movies: [Movie], isRanked: Bool, isFeatured: Bool, tags: [String], likeCount: Int, commentCount: Int, likedBy: [String], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.title = title
        self.description = description
        self.movies = movies
        self.isRanked = isRanked
        self.isFeatured = isFeatured
        self.tags = tags
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.likedBy = likedBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let ownerId = dictionary["ownerId"] as? String,
              let ownerName = dictionary["ownerName"] as? String,
              let title = dictionary["title"] as? String,
              let description = dictionary["description"] as? String,
              let movieData = dictionary["movies"] as? [[String: Any]],
              let createdAt = (dictionary["createdAt"] as? Timestamp)?.dateValue(),
              let updatedAt = (dictionary["updatedAt"] as? Timestamp)?.dateValue() else { return nil }
        
        self.id = id
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.title = title
        self.description = description
        self.movies = movieData.compactMap { Movie(dictionary: $0) }
        self.isRanked = dictionary["isRanked"] as? Bool ?? false
        self.isFeatured = dictionary["isFeatured"] as? Bool ?? false
        self.tags = dictionary["tags"] as? [String] ?? []
        self.likeCount = dictionary["likeCount"] as? Int ?? 0
        self.commentCount = dictionary["commentCount"] as? Int ?? 0
        self.likedBy = dictionary["likedBy"] as? [String] ?? []
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "ownerId": ownerId,
            "ownerName": ownerName,
            "title": title,
            "description": description,
            "movies": movies.map { $0.dictionary },
            "isRanked": isRanked,
            "isFeatured": isFeatured,
            "tags": tags,
            "likeCount": likeCount,
            "commentCount": commentCount,
            "likedBy": likedBy,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
}

extension Movie {
    // Helper to convert movie to dictionary for nested storage in lists
    var dictionary: [String: Any] {
        return [
            "id": id,
            "title": displayName,
            "posterPath": posterPath ?? "",
            "voteAverage": voteAverage,
            "releaseDate": displayDate
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? Int,
              let title = dictionary["title"] as? String else { return nil }
        
        self.init(id: id,
                  title: title,
                  posterPath: dictionary["posterPath"] as? String,
                  backdropPath: nil,
                  overview: "",
                  releaseDate: dictionary["releaseDate"] as? String ?? "",
                  voteAverage: dictionary["voteAverage"] as? Double ?? 0.0,
                  voteCount: 0)
    }
}
