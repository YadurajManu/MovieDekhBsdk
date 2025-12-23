//
//  MovieDetail.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import Foundation

struct MovieDetail: Codable {
    let id: Int
    let title: String
    let posterPath: String?
    let backdropPath: String?
    let overview: String
    let releaseDate: String
    let voteAverage: Double
    let voteCount: Int
    let runtime: Int?
    let genres: [Genre]
    let tagline: String?
    let status: String
    let originalLanguage: String
    let budget: Int
    let revenue: Int
    
    // Appended responses
    let credits: CreditsResponse?
    let videos: VideosResponse?
    let images: ImagesResponse?
    let similar: MoviesResponse?
    let recommendations: MoviesResponse?
    let keywords: KeywordsResponse?
    let watchProviders: WatchProvidersResponse?
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, genres, tagline, status, budget, revenue
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case originalLanguage = "original_language"
        case credits, videos, images, similar, recommendations, keywords
        case watchProviders = "watch/providers"
    }
    
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    var backdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(backdropPath)")
    }
    
    var year: String {
        String(releaseDate.prefix(4))
    }
    
    var rating: String {
        String(format: "%.1f", voteAverage)
    }
    
    var runtimeFormatted: String {
        guard let runtime = runtime else { return "N/A" }
        let hours = runtime / 60
        let minutes = runtime % 60
        return "\(hours)h \(minutes)m"
    }
    
    var genreNames: String {
        genres.map { $0.name }.joined(separator: ", ")
    }
    
    // Helpers
    var director: Crew? {
        credits?.crew.first { $0.job == "Director" }
    }
    
    var writers: [Crew] {
        credits?.crew.filter { $0.department == "Writing" } ?? []
    }
    
    var youtubeTrailers: [Video] {
        videos?.results.filter { $0.site == "YouTube" && $0.type == "Trailer" } ?? []
    }
    
    var flatrateProviders: [Provider] {
        // Default to US or IN if available, fallback to first available
        if let providers = watchProviders?.results["IN"]?.flatrate { return providers }
        if let providers = watchProviders?.results["US"]?.flatrate { return providers }
        return []
    }
}

struct Genre: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
}

// MARK: - Credits
struct CreditsResponse: Codable {
    let cast: [Cast]
    let crew: [Crew]
}

struct Cast: Codable, Identifiable {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }
    
    var profileURL: URL? {
        guard let profilePath = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(profilePath)")
    }
}

struct Crew: Codable, Identifiable {
    let id: Int
    let name: String
    let job: String
    let department: String
    let profilePath: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, job, department
        case profilePath = "profile_path"
    }
}

// MARK: - Videos
struct VideosResponse: Codable {
    let results: [Video]
}

struct Video: Codable, Identifiable {
    let id: String
    let key: String
    let name: String
    let site: String
    let type: String
    let publishedAt: String?
    
    var thumbnailURL: URL? {
        URL(string: "https://img.youtube.com/vi/\(key)/hqdefault.jpg")
    }
    
    var youtubeURL: URL? {
        URL(string: "https://www.youtube.com/watch?v=\(key)")
    }
    
    var publishedDate: Date? {
        guard let dateString = publishedAt else { return nil }
        
        // Try with fractional seconds first (common in TMDB videos)
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: dateString) {
            return date
        }
        
        // Fallback to standard ISO8601
        let standardFormatter = ISO8601DateFormatter()
        standardFormatter.formatOptions = [.withInternetDateTime]
        return standardFormatter.date(from: dateString)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, key, name, site, type
        case publishedAt = "published_at"
    }
}

// MARK: - Images
struct ImagesResponse: Codable {
    let backdrops: [ImageInfo]
    let posters: [ImageInfo]
}

struct ImageInfo: Codable, Identifiable {
    let filePath: String
    let width: Int
    let height: Int
    
    var id: String { filePath }
    
    enum CodingKeys: String, CodingKey {
        case width, height
        case filePath = "file_path"
    }
    
    var url: URL? {
        URL(string: "https://image.tmdb.org/t/p/w500\(filePath)")
    }
}

// MARK: - Keywords
struct KeywordsResponse: Codable {
    let keywords: [Keyword]
}

struct Keyword: Codable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - Watch Providers
struct WatchProvidersResponse: Codable {
    let results: [String: CountryProvider]
}

struct CountryProvider: Codable {
    let link: String
    let flatrate: [Provider]?
    let rent: [Provider]?
    let buy: [Provider]?
}

struct Provider: Codable, Identifiable {
    let providerId: Int
    let providerName: String
    let logoPath: String?
    
    var id: Int { providerId }
    
    enum CodingKeys: String, CodingKey {
        case providerId = "provider_id"
        case providerName = "provider_name"
        case logoPath = "logo_path"
    }
    
    var logoURL: URL? {
        guard let logoPath = logoPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(logoPath)")
    }
}
