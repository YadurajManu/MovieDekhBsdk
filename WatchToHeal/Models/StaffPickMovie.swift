import Foundation
import FirebaseFirestore

struct StaffPickMovie: Identifiable, Codable {
    @DocumentID var firestoreId: String?
    let id: Int // TMDB Movie ID
    let title: String
    let posterPath: String?
    let backdropPath: String?
    let overview: String
    let releaseDate: String
    let voteAverage: Double
    let voteCount: Int
    let addedAt: Date
    
    var movie: Movie {
        Movie(
            id: id,
            title: title,
            posterPath: posterPath,
            backdropPath: backdropPath,
            overview: overview,
            releaseDate: releaseDate,
            voteAverage: voteAverage,
            voteCount: voteCount
        )
    }
    
    init(movie: Movie, addedAt: Date = Date()) {
        self.id = movie.id
        self.title = movie.title
        self.posterPath = movie.posterPath
        self.backdropPath = movie.backdropPath
        self.overview = movie.overview
        self.releaseDate = movie.releaseDate
        self.voteAverage = movie.voteAverage
        self.voteCount = movie.voteCount
        self.addedAt = addedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        overview = try container.decode(String.self, forKey: .overview)
        releaseDate = try container.decode(String.self, forKey: .releaseDate)
        voteAverage = try container.decode(Double.self, forKey: .voteAverage)
        voteCount = try container.decode(Int.self, forKey: .voteCount)
        
        // Handle Firestore Timestamp or Date
        if let timestamp = try? container.decode(Timestamp.self, forKey: .addedAt) {
            addedAt = timestamp.dateValue()
        } else {
            addedAt = try container.decode(Date.self, forKey: .addedAt)
        }
    }
}
