//
//  TVDetail.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 22/12/25.
//

import Foundation

struct TVDetail: Codable {
    let id: Int
    let name: String
    let originalName: String?
    let posterPath: String?
    let backdropPath: String?
    let overview: String
    let firstAirDate: String?
    let lastAirDate: String?
    let voteAverage: Double
    let voteCount: Int
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let episodeRunTime: [Int]?
    let genres: [Genre]
    let tagline: String?
    let status: String?
    let originalLanguage: String?
    let networks: [Network]?
    let createdBy: [Creator]?
    let inProduction: Bool?
    
    // Appended responses
    let credits: CreditsResponse?
    let videos: VideosResponse?
    let images: ImagesResponse?
    let similar: TVResponse?
    let recommendations: TVResponse?
    let watchProviders: WatchProvidersResponse?
    
    enum CodingKeys: String, CodingKey {
        case id, name, overview, genres, tagline, status, networks, credits, videos, images, similar, recommendations
        case originalName = "original_name"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case lastAirDate = "last_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case numberOfSeasons = "number_of_seasons"
        case numberOfEpisodes = "number_of_episodes"
        case episodeRunTime = "episode_run_time"
        case originalLanguage = "original_language"
        case createdBy = "created_by"
        case inProduction = "in_production"
        case watchProviders = "watch/providers"
    }
    
    // MARK: - Computed Properties
    
    var displayName: String { name }
    
    var displayDate: String { firstAirDate ?? "" }
    
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    var backdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(backdropPath)")
    }
    
    var year: String {
        String((firstAirDate ?? "").prefix(4))
    }
    
    var rating: String {
        String(format: "%.1f", voteAverage)
    }
    
    var runtimeFormatted: String {
        guard let runtimes = episodeRunTime, let avg = runtimes.first else { return "N/A" }
        return "\(avg) min/ep"
    }
    
    var genreNames: String {
        genres.map { $0.name }.joined(separator: ", ")
    }
    
    var seasonsFormatted: String {
        guard let seasons = numberOfSeasons else { return "" }
        return seasons == 1 ? "1 Season" : "\(seasons) Seasons"
    }
    
    var episodesFormatted: String {
        guard let episodes = numberOfEpisodes else { return "" }
        return "\(episodes) Episodes"
    }
    
    var youtubeTrailers: [Video] {
        videos?.results.filter { $0.site == "YouTube" && $0.type == "Trailer" } ?? []
    }
    
    var flatrateProviders: [Provider] {
        if let providers = watchProviders?.results["IN"]?.flatrate { return providers }
        if let providers = watchProviders?.results["US"]?.flatrate { return providers }
        return []
    }
}

// MARK: - Supporting Types

struct Network: Codable, Identifiable {
    let id: Int
    let name: String
    let logoPath: String?
    let originCountry: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case logoPath = "logo_path"
        case originCountry = "origin_country"
    }
    
    var logoURL: URL? {
        guard let logoPath = logoPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w200\(logoPath)")
    }
}

struct Creator: Codable, Identifiable {
    let id: Int
    let name: String
    let profilePath: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case profilePath = "profile_path"
    }
    
    var profileURL: URL? {
        guard let profilePath = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(profilePath)")
    }
}

struct TVResponse: Codable {
    let results: [Movie]
}
