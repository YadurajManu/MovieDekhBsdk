//
//  TMDBService.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import Foundation

class TMDBService {
    static let shared = TMDBService()
    
    private let apiKey = "b80939fd2834d65514c181d3046684d1"
    private let baseURL = "https://api.themoviedb.org/3"
    
    // Configure URLSession with caching
    // Configure URLSession with standard configuration
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    func fetchTrending(timeWindow: String = "day") async throws -> [Movie] {
        let urlString = "\(baseURL)/trending/movie/\(timeWindow)?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results
    }
    
    func fetchMoviesByGenre(genreId: Int, page: Int = 1) async throws -> [Movie] {
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&language=en-US&sort_by=popularity.desc&with_genres=\(genreId)&page=\(page)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results
    }
    
    func fetchTopMovies(page: Int = 1) async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/popular?api_key=\(apiKey)&language=en-US&page=\(page)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results
    }
    
    func fetchNowPlaying(region: String = "US", page: Int = 1) async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/now_playing?api_key=\(apiKey)&language=en-US&region=\(region)&page=\(page)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results
    }
    
    func fetchUpcoming(region: String = "US", page: Int = 1) async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/upcoming?api_key=\(apiKey)&language=en-US&region=\(region)&page=\(page)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results
    }
    
    func fetchTopRated(page: Int = 1) async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/top_rated?api_key=\(apiKey)&language=en-US&page=\(page)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results
    }
    
    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        let appendToResponse = "credits,videos,images,similar,recommendations,keywords,watch/providers"
        let url = URL(string: "\(baseURL)/movie/\(id)?api_key=\(apiKey)&append_to_response=\(appendToResponse)")!
        let (data, _) = try await urlSession.data(from: url)
        return try JSONDecoder().decode(MovieDetail.self, from: data)
    }
    
    // fetchMovieCast is no longer needed as independent call, but keeping for compatibility if utilized elsewhere
    func fetchMovieCredits(id: Int) async throws -> CreditsResponse {
        let url = URL(string: "\(baseURL)/movie/\(id)/credits?api_key=\(apiKey)")!
        let (data, _) = try await urlSession.data(from: url)
        return try JSONDecoder().decode(CreditsResponse.self, from: data)
    }
    
    func searchMovies(query: String) async throws -> [Movie] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/search/movie?api_key=\(apiKey)&language=en-US&query=\(encodedQuery)&page=1"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results
    }
    
    func searchPeople(query: String) async throws -> [Person] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/search/person?api_key=\(apiKey)&language=en-US&query=\(encodedQuery)&page=1"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(PersonResponse.self, from: data)
        return response.results
    }
    
    // MARK: - Advanced Search & Discovery
    
    struct MultiSearchResponse: Codable {
        let results: [SearchResult]
    }
    
    func searchMulti(query: String) async throws -> [SearchResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/search/multi?api_key=\(apiKey)&language=en-US&query=\(encodedQuery)&page=1&include_adult=false"
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MultiSearchResponse.self, from: data)
        
        // Filter out unknown media types if necessary, or keep them
        return response.results.filter { $0.mediaType != .unknown }
    }
    
    func fetchGenres() async throws -> [Genre] {
        let urlString = "\(baseURL)/genre/movie/list?api_key=\(apiKey)&language=en-US"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(GenresResponse.self, from: data)
        return response.genres
    }
    
    func discoverMovies(filter: FilterState) async throws -> [Movie] {
        var components = URLComponents(string: "\(baseURL)/discover/movie")!
        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "sort_by", value: filter.sortOption.rawValue),
            URLQueryItem(name: "include_adult", value: String(filter.showAdult)),
            URLQueryItem(name: "include_video", value: "false"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "watch_region", value: filter.region ?? "US")
        ]
        
        // Year Range (primary_release_date.gte / .lte)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startYear = Int(filter.yearRange.lowerBound)
        let endYear = Int(filter.yearRange.upperBound)
        
        queryItems.append(URLQueryItem(name: "primary_release_date.gte", value: "\(startYear)-01-01"))
        queryItems.append(URLQueryItem(name: "primary_release_date.lte", value: "\(endYear)-12-31"))
        
        // Genres (with_genres)
        if !filter.selectedGenres.isEmpty {
            let genreIds = filter.selectedGenres.map { String($0.id) }.joined(separator: ",")
            queryItems.append(URLQueryItem(name: "with_genres", value: genreIds))
        }
        
        // Vote Average (vote_average.gte)
        if filter.minVoteAverage > 0 {
            queryItems.append(URLQueryItem(name: "vote_average.gte", value: String(filter.minVoteAverage)))
        }
        
        // Vote Count (vote_count.gte)
        if filter.minVoteCount > 0 {
            queryItems.append(URLQueryItem(name: "vote_count.gte", value: String(filter.minVoteCount)))
        }
        
        // Runtime (with_runtime.gte / .lte)
        // Note: TMDB API uses separate params for runtime filtering
        if filter.runtimeRange.lowerBound > 0 {
            queryItems.append(URLQueryItem(name: "with_runtime.gte", value: String(Int(filter.runtimeRange.lowerBound))))
        }
        if filter.runtimeRange.upperBound < 240 { // Assuming 240 is max slider value
            queryItems.append(URLQueryItem(name: "with_runtime.lte", value: String(Int(filter.runtimeRange.upperBound))))
        }
        
        // Monetization (with_watch_monetization_types)
        if !filter.monetizationTypes.isEmpty {
            let types = filter.monetizationTypes.map { $0.rawValue.lowercased() }.joined(separator: "|") // OR logic
            queryItems.append(URLQueryItem(name: "with_watch_monetization_types", value: types))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else { throw URLError(.badURL) }
        
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results
    }
    
    // MARK: - Advanced Onboarding Support (Taste Fingerprinting)
    
    func fetchPopularPeople() async throws -> [Person] {
        let urlString = "\(baseURL)/person/popular?api_key=\(apiKey)&language=en-US&page=1"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(PersonResponse.self, from: data)
        return response.results
    }
    
    func fetchMoviesByKeyword(keywordId: String) async throws -> [Movie] {
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&language=en-US&sort_by=popularity.desc&with_keywords=\(keywordId)&page=1"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results
    }
    
    func fetchMoviesByEra(startYear: Int, endYear: Int) async throws -> [Movie] {
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&language=en-US&sort_by=vote_count.desc&primary_release_date.gte=\(startYear)-01-01&primary_release_date.lte=\(endYear)-12-31&page=1"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results
    }
    
    func fetchHighlyRatedMovies() async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/top_rated?api_key=\(apiKey)&language=en-US&page=\(Int.random(in: 1...5))"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results.shuffled()
    }
    
    // MARK: - Additional Genre Methods
    
    func fetchHorrorMovies(page: Int = 1) async throws -> [Movie] {
        try await fetchMoviesByGenre(genreId: 27, page: page)
    }
    
    func fetchRomanceMovies(page: Int = 1) async throws -> [Movie] {
        try await fetchMoviesByGenre(genreId: 10749, page: page)
    }
    
    func fetchThrillerMovies(page: Int = 1) async throws -> [Movie] {
        try await fetchMoviesByGenre(genreId: 53, page: page)
    }
    
    func fetchAnimationMovies(page: Int = 1) async throws -> [Movie] {
        try await fetchMoviesByGenre(genreId: 16, page: page)
    }
    
    func fetchDocumentaryMovies(page: Int = 1) async throws -> [Movie] {
        try await fetchMoviesByGenre(genreId: 99, page: page)
    }
    
    func fetchCrimeMovies(page: Int = 1) async throws -> [Movie] {
        try await fetchMoviesByGenre(genreId: 80, page: page)
    }
    
    func fetchMysteryMovies(page: Int = 1) async throws -> [Movie] {
        try await fetchMoviesByGenre(genreId: 9648, page: page)
    }
    
    func fetchAdventureMovies(page: Int = 1) async throws -> [Movie] {
        try await fetchMoviesByGenre(genreId: 12, page: page)
    }
    
    func fetchWesternMovies(page: Int = 1) async throws -> [Movie] {
        try await fetchMoviesByGenre(genreId: 37, page: page)
    }
    
    func fetchMusicMovies(page: Int = 1) async throws -> [Movie] {
        try await fetchMoviesByGenre(genreId: 10402, page: page)
    }
    
    func fetchWarMovies(page: Int = 1) async throws -> [Movie] {
        try await fetchMoviesByGenre(genreId: 10752, page: page)
    }
    
    // MARK: - Director/Person Methods
    
    struct PersonDetail: Codable {
        let id: Int
        let name: String
        let biography: String?
        let profilePath: String?
        let knownForDepartment: String?
        let birthday: String?
        let deathday: String?
        let placeOfBirth: String?
        let images: PersonImages?
        
        enum CodingKeys: String, CodingKey {
            case id, name, biography, birthday, deathday, images
            case profilePath = "profile_path"
            case knownForDepartment = "known_for_department"
            case placeOfBirth = "place_of_birth"
        }
        
        struct PersonImages: Codable {
            let profiles: [Image]
        }
        
        struct Image: Codable, Identifiable {
            let filePath: String
            let height: Int
            let width: Int
            let voteAverage: Double
            
            var id: String { filePath }
            
            var url: URL? {
                URL(string: "https://image.tmdb.org/t/p/original\(filePath)")
            }
            
            enum CodingKeys: String, CodingKey {
                case filePath = "file_path"
                case height, width
                case voteAverage = "vote_average"
            }
        }
    }
    
    struct PersonMovieCreditsResponse: Codable {
        let cast: [Movie]
        let crew: [CrewMember]
    }
    
    struct CrewMember: Codable {
        let id: Int
        let title: String
        let posterPath: String?
        let voteAverage: Double
        let releaseDate: String?
        let job: String
        let department: String
        
        enum CodingKeys: String, CodingKey {
            case id, title, job, department
            case posterPath = "poster_path"
            case voteAverage = "vote_average"
            case releaseDate = "release_date"
        }
    }
    
    func fetchPersonDetails(id: Int) async throws -> PersonDetail {
        let urlString = "\(baseURL)/person/\(id)?api_key=\(apiKey)&language=en-US&append_to_response=images"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        return try JSONDecoder().decode(PersonDetail.self, from: data)
    }
    
    func fetchPersonMovieCredits(id: Int) async throws -> [Movie] {
        let urlString = "\(baseURL)/person/\(id)/movie_credits?api_key=\(apiKey)&language=en-US"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(PersonMovieCreditsResponse.self, from: data)
        
        // Get movies where person was director
        let directedMovies = response.crew
            .filter { $0.job == "Director" }
            .sorted { $0.voteAverage > $1.voteAverage }
            .prefix(10)
            .compactMap { crew -> Movie? in
                Movie(
                    id: crew.id,
                    title: crew.title,
                    posterPath: crew.posterPath,
                    backdropPath: nil,
                    overview: "",
                    releaseDate: crew.releaseDate ?? "",
                    voteAverage: crew.voteAverage,
                    voteCount: 0
                )
            }
        
        return directedMovies
    }
    
    // MARK: - Watch Providers
    
    struct WatchProvidersResponse: Codable {
        let id: Int
        let results: [String: CountryProviders]
        
        struct CountryProviders: Codable {
            let link: String?
            let flatrate: [Provider]?
            let rent: [Provider]?
            let buy: [Provider]?
        }
        
        struct Provider: Codable, Identifiable {
            let logoPath: String
            let providerId: Int
            let providerName: String
            let displayPriority: Int
            
            var id: Int { providerId }
            
            var logoURL: URL? {
                URL(string: "https://image.tmdb.org/t/p/original\(logoPath)")
            }
            
            enum CodingKeys: String, CodingKey {
                case logoPath = "logo_path"
                case providerId = "provider_id"
                case providerName = "provider_name"
                case displayPriority = "display_priority"
            }
        }
    }
    
    func fetchWatchProviders(movieId: Int, region: String = "US") async throws -> WatchProvidersResponse.CountryProviders? {
        let urlString = "\(baseURL)/movie/\(movieId)/watch/providers?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(WatchProvidersResponse.self, from: data)
        return response.results[region]
    }
    
    // MARK: - Dedicated Discovery Methods
    
    /// Fetches movies releasing between today and X days from now
    func fetchUpcomingWithinDays(days: Int, region: String = "US") async throws -> [Movie] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today)!
        
        let start = dateFormatter.string(from: today)
        let end = dateFormatter.string(from: futureDate)
        
        // Using primary_release_date for more accuracy in "Calendar" context
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&language=en-US&sort_by=primary_release_date.asc&primary_release_date.gte=\(start)&primary_release_date.lte=\(end)&with_release_type=2|3&region=\(region)"
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results
    }
    
    /// Fetches top-rated "Masterpieces" for a specific language
    func fetchMasterpiecesByLanguage(isoCode: String, page: Int = 1) async throws -> [Movie] {
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&language=en-US&sort_by=vote_count.desc&with_original_language=\(isoCode)&vote_average.gte=8.0&vote_count.gte=500&page=\(page)"
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results
    }
    
    /// Fetches movies available on a specific watch provider (e.g., Netflix, Disney+)
    func fetchMoviesByProvider(providerId: Int, region: String = "US", page: Int = 1) async throws -> [Movie] {
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&language=en-US&sort_by=popularity.desc&watch_region=\(region)&with_watch_providers=\(providerId)&page=\(page)"
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        return response.results
    }
    
    // MARK: - Trailers
    
    struct MovieTrailer: Identifiable, Codable {
        let id: Int
        let movieTitle: String
        let backdropPath: String?
        let youtubeKey: String
        
        var backdropURL: URL? {
            guard let path = backdropPath else { return nil }
            return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
        }
        
        var youtubeURL: URL? {
            URL(string: "https://www.youtube.com/watch?v=\(youtubeKey)")
        }
    }
    
    func fetchLatestTrailers() async throws -> [MovieTrailer] {
        // 1. Fetch upcoming movies
        let upcoming = try await fetchUpcoming()
        let moviesToFetch = Array(upcoming.prefix(6)) // Limit to 6 for performance
        
        var trailers: [MovieTrailer] = []
        
        // 2. Fetch videos for each movie
        for movie in moviesToFetch {
            do {
                let detail = try await fetchMovieDetail(id: movie.id)
                if let trailer = detail.youtubeTrailers.first {
                    trailers.append(MovieTrailer(
                        id: movie.id,
                        movieTitle: movie.title,
                        backdropPath: movie.backdropPath ?? movie.posterPath,
                        youtubeKey: trailer.key
                    ))
                }
            } catch {
                print("Error fetching trailer for \(movie.title): \(error)")
            }
        }
        
        return trailers
    }
}
