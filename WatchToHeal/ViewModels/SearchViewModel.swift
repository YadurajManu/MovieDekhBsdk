//
//  SearchViewModel.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [Movie] = []
    @Published var recentSearches: [String] = []
    @Published var trendingMovies: [Movie] = []
    @Published var latestTrailers: [TMDBService.MovieTrailer] = []
    @Published var featuredLists: [CommunityList] = []
    @Published var staffPicks: [Movie] = []
    @Published var isSearching = false
    @Published var isLoadingTrending = false
    @Published var errorMessage: String?
    
    @Published var filterState = FilterState()
    @Published var availableGenres: [Genre] = []
    @Published var showFilters = false
    @Published var isDiscoveryMode = false
    @Published var multiSearchResults: [SearchResult] = []
    @Published var activeFilterPanel: FilterPanel?
    
    enum FilterPanel: String, Identifiable, CaseIterable {
        case sort = "Sort"
        case genre = "Genre"
        case year = "Year"
        case rating = "Rating"
        
        var id: String { rawValue }
    }
    
    @Published var selectedScope: SearchScope = .all
    
    enum SearchScope: String, CaseIterable, Identifiable {
        case all = "All"
        case movie = "Movies"
        case tv = "TV Shows"
        case person = "People"
        
        var id: String { rawValue }
    }
    
    private var searchTask: Task<Void, Never>?
    private let recentSearchesKey = "recentSearches"
    private let maxRecentSearches = 8
    
    init() {
        loadRecentSearches()
        Task {
            await loadTrendingMovies()
            await loadGenres()
        }
    }
    
    func search() async {
        searchTask?.cancel()
        
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            multiSearchResults = []
            searchResults = []
            return
        }
        
        searchTask = Task {
            isSearching = true
            errorMessage = nil
            isDiscoveryMode = false // Reset discovery mode on text search
            
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            guard !Task.isCancelled else {
                isSearching = false
                return
            }
            
            do {
                switch selectedScope {
                case .all:
                    // Use Multi-Search
                    let results = try await TMDBService.shared.searchMulti(query: searchQuery)
                    multiSearchResults = results
                    searchResults = []
                    
                case .movie:
                    // Use Movie-only Search
                    let movies = try await TMDBService.shared.searchMovies(query: searchQuery)
                    // Convert to SearchResult for consistent display logic
                    multiSearchResults = movies.map { movie in
                        SearchResult(
                            id: movie.id,
                            mediaType: .movie,
                            title: movie.title,
                            name: nil,
                            posterPath: movie.posterPath,
                            profilePath: nil,
                            overview: movie.overview,
                            releaseDate: movie.releaseDate,
                            firstAirDate: nil,
                            voteAverage: movie.voteAverage,
                            voteCount: movie.voteCount,
                            originalTitle: movie.originalTitle
                        )
                    }
                    searchResults = []
                    
                case .tv:
                    // Use TV-only Search
                    let movies = try await TMDBService.shared.searchTV(query: searchQuery)
                    // Convert to SearchResult for consistent display logic
                    multiSearchResults = movies.map { movie in
                        SearchResult(
                            id: movie.id,
                            mediaType: .tv,
                            title: nil,
                            name: movie.displayName, // Use displayName to get name
                            posterPath: movie.posterPath,
                            profilePath: nil,
                            overview: movie.overview,
                            releaseDate: nil,
                            firstAirDate: movie.firstAirDate,
                            voteAverage: movie.voteAverage,
                            voteCount: movie.voteCount,
                            originalTitle: movie.originalName
                        )
                    }
                    searchResults = []
                    
                case .person:
                    // Use Person-only Search
                    let people = try await TMDBService.shared.searchPeople(query: searchQuery)
                    // Convert to SearchResult
                    multiSearchResults = people.map { person in
                        SearchResult(
                            id: person.id,
                            mediaType: .person,
                            title: nil,
                            name: person.name,
                            posterPath: nil,
                            profilePath: person.profilePath,
                            overview: nil,
                            releaseDate: nil,
                            firstAirDate: nil,
                            voteAverage: nil,
                            voteCount: nil,
                            originalTitle: nil
                        )
                    }
                    searchResults = []
                }
                
                saveRecentSearch(searchQuery)
            } catch {
                errorMessage = "Search failed: \(error.localizedDescription)"
                multiSearchResults = []
            }
            
            isSearching = false
        }
    }
    
    func applyFilters(region: String = "US") {
        searchTask?.cancel()
        searchTask = Task {
            isSearching = true
            errorMessage = nil
            isDiscoveryMode = true // Enable discovery mode
            
            filterState.region = region
            
            do {
                let results = try await TMDBService.shared.discoverMovies(filter: filterState)
                searchResults = results // Reuse searchResults for movies returned by discover
                multiSearchResults = [] // Clear multi-search results to avoid confusion
            } catch {
                errorMessage = "Discovery failed: \(error.localizedDescription)"
                searchResults = []
            }
            
            isSearching = false
            showFilters = false // Close filter sheet
        }
    }
    
    func loadGenres() async {
        do {
            availableGenres = try await TMDBService.shared.fetchGenres()
        } catch {
            print("Failed to load genres: \(error)")
        }
    }
    
    func toggleGenre(_ genre: Genre) {
        if filterState.selectedGenres.contains(genre) {
            filterState.selectedGenres.remove(genre)
        } else {
            filterState.selectedGenres.insert(genre)
        }
    }
    
    func toggleMonetization(_ type: MonetizationType) {
        if filterState.monetizationTypes.contains(type) {
            filterState.monetizationTypes.remove(type)
        } else {
            filterState.monetizationTypes.insert(type)
        }
    }
    
    func resetFilters() {
        filterState.reset()
    }
    
    @Published var trendingTimeWindow: String = "day"
    
    func loadTrendingMovies(region: String = "US") async {
        print("🔄 loadTrendingMovies called - timeWindow: \(trendingTimeWindow)")
        isLoadingTrending = true
        
        // Fetch trending movies (TMDB)
        Task {
            do {
                let fetchedTrending = try await TMDBService.shared.fetchTrending(timeWindow: trendingTimeWindow)
                self.trendingMovies = fetchedTrending
                print("✅ Trending movies: \(fetchedTrending.count)")
            } catch {
                print("❌ Failed to load trending: \(error)")
            }
        }
        
        // Fetch latest trailers (TMDB)
        Task {
            do {
                let fetchedTrailers = try await TMDBService.shared.fetchLatestTrailers(region: region)
                self.latestTrailers = fetchedTrailers
                print("✅ Trailers: \(fetchedTrailers.count)")
            } catch {
                print("❌ Failed to load trailers: \(error)")
            }
        }
        
        // Fetch featured lists (Firestore)
        Task {
            do {
                let fetchedFeatured = try await FirestoreService.shared.fetchFeaturedLists()
                self.featuredLists = fetchedFeatured
                print("✅ Featured lists: \(fetchedFeatured.count)")
            } catch {
                print("❌ Failed to load featured lists: \(error)")
            }
        }
        
        // Fetch staff pick movies (Firestore)
        Task {
            do {
                let fetchedPicks = try await FirestoreService.shared.fetchStaffPickMovies()
                self.staffPicks = fetchedPicks
                print("✅ Staff pick movies: \(fetchedPicks.count)")
            } catch {
                print("❌ Failed to load staff pick movies: \(error)")
            }
        }
        
        // We set isLoadingTrending to false immediately as the sections will pop in individually
        // Or we could use a group to wait, but decoupling is better for responsiveness
        isLoadingTrending = false
    }
    
    func toggleTrendingTimeWindow(region: String = "US") {
        trendingTimeWindow = (trendingTimeWindow == "day") ? "week" : "day"
        Task {
            await loadTrendingMovies(region: region)
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        multiSearchResults = []
        isDiscoveryMode = false
        errorMessage = nil
        searchTask?.cancel()
    }
    
    func selectRecentSearch(_ query: String) {
        searchQuery = query
        Task {
            await search()
        }
    }
    
    func removeRecentSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        saveRecentSearchesToStorage()
    }
    
    func clearAllRecentSearches() {
        recentSearches = []
        saveRecentSearchesToStorage()
    }
    
    private func saveRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        // Remove if already exists
        recentSearches.removeAll { $0.lowercased() == trimmed.lowercased() }
        
        // Add to front
        recentSearches.insert(trimmed, at: 0)
        
        // Keep only max recent searches
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        saveRecentSearchesToStorage()
    }
    
    private func loadRecentSearches() {
        if let saved = UserDefaults.standard.stringArray(forKey: recentSearchesKey) {
            recentSearches = saved
        }
    }
    
    private func saveRecentSearchesToStorage() {
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }
}
