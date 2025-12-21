import Foundation

enum MediaType: String, Codable {
    case movie
    case tv
    case person
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = MediaType(rawValue: value) ?? .unknown
    }
}

// Wrapper for Multi-Search Results
struct SearchResult: Identifiable, Codable {
    let id: Int
    let mediaType: MediaType
    
    // Common properties
    let title: String? // Movie title
    let name: String? // TV/Person name
    let posterPath: String? // Movie/TV poster
    let profilePath: String? // Person profile
    let overview: String?
    let releaseDate: String? // Movie release
    let firstAirDate: String? // TV release
    let voteAverage: Double?
    let voteCount: Int?
    let originalTitle: String?
    
    // Helpers
    var displayTitle: String { title ?? name ?? "Unknown" }
    var imageURL: URL? {
        if let path = posterPath ?? profilePath {
            return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
        }
        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case originalTitle = "original_title"
        case mediaType = "media_type"
        case posterPath = "poster_path"
        case profilePath = "profile_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}



struct GenresResponse: Codable {
    let genres: [Genre]
}

enum SortOption: String, CaseIterable, Identifiable {
    case popularityDesc = "popularity.desc"
    case popularityAsc = "popularity.asc"
    case ratingDesc = "vote_average.desc"
    case ratingAsc = "vote_average.asc"
    case dateDesc = "primary_release_date.desc"
    case dateAsc = "primary_release_date.asc"
    case titleAsc = "original_title.asc"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .popularityDesc: return "Popularity (High to Low)"
        case .popularityAsc: return "Popularity (Low to High)"
        case .ratingDesc: return "Rating (High to Low)"
        case .ratingAsc: return "Rating (Low to High)"
        case .dateDesc: return "Release Date (Newest)"
        case .dateAsc: return "Release Date (Oldest)"
        case .titleAsc: return "Title (A-Z)"
        }
    }
}

enum MonetizationType: String, CaseIterable, Identifiable {
    case flatrate = "Stream"
    case rent = "Rent"
    case buy = "Buy"
    case free = "Free"
    
    var id: String { rawValue }
}

struct FilterState {
    var sortOption: SortOption = .popularityDesc
    var selectedGenres: Set<Genre> = []
    var yearRange: ClosedRange<Double> = 1970...2025
    var minVoteAverage: Double = 0
    var minVoteCount: Int = 0
    var runtimeRange: ClosedRange<Double> = 0...240
    var monetizationTypes: Set<MonetizationType> = [.flatrate]
    var showAdult: Bool = false
    var region: String? = "US"

    
    mutating func reset() {
        self = FilterState()
    }
}
