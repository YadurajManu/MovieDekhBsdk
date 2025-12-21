//
//  Movie.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import Foundation

struct Movie: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let posterPath: String?
    let backdropPath: String?
    let overview: String
    let releaseDate: String
    let voteAverage: Double
    let voteCount: Int
    
    // Local State
    var userRating: Int?
    let originalTitle: String?
    
    init(id: Int, title: String, posterPath: String?, backdropPath: String?, overview: String, releaseDate: String, voteAverage: Double, voteCount: Int, originalTitle: String? = nil, userRating: Int? = nil) {
        self.id = id
        self.title = title
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.overview = overview
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.originalTitle = originalTitle
        self.userRating = userRating
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case originalTitle = "original_title"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
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
