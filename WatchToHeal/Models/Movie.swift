//
//  Movie.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import Foundation

struct Movie: Identifiable, Codable, Hashable {
    let id: Int
    let title: String? // Optional for TV shows
    let name: String? // For TV shows
    let posterPath: String?
    let backdropPath: String?
    let overview: String
    let releaseDate: String? // Optional for TV shows
    let firstAirDate: String? // For TV shows
    let voteAverage: Double
    let voteCount: Int
    
    // Local State
    var userRating: Int?
    let originalTitle: String?
    let originalName: String? // For TV shows
    
    init(id: Int, title: String? = nil, name: String? = nil, posterPath: String?, backdropPath: String?, overview: String, releaseDate: String? = nil, firstAirDate: String? = nil, voteAverage: Double, voteCount: Int, originalTitle: String? = nil, originalName: String? = nil, userRating: Int? = nil) {
        self.id = id
        self.title = title
        self.name = name
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.overview = overview
        self.releaseDate = releaseDate
        self.firstAirDate = firstAirDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.originalTitle = originalTitle
        self.originalName = originalName
        self.userRating = userRating
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case originalTitle = "original_title"
        case originalName = "original_name"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
    
    var displayName: String {
        title ?? name ?? "Unknown"
    }
    
    var displayDate: String {
        releaseDate ?? firstAirDate ?? ""
    }
    
    var displayYear: String {
        String(displayDate.prefix(4))
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
        displayYear
    }
    
    var rating: String {
        String(format: "%.1f", voteAverage)
    }
}

struct MoviesResponse: Codable {
    let results: [Movie]
    let page: Int
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case results, page
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
