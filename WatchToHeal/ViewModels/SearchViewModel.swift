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
    @Published var recentSearches: [String] = []
    @Published var trendingMovies: [Movie] = []
    @Published var latestTrailers: [TMDBService.MovieTrailer] = []
    @Published var featuredLists: [CommunityList] = []
    @Published var staffPicks: [Movie] = []
    @Published var isSearching = false
    @Published var isLoadingTrending = false
    @Published var errorMessage: String?
    @Published var multiSearchResults: [SearchResult] = []

    private var searchTask: Task<Void, Never>?
    private let recentSearchesKey = "recentSearches"
    private let maxRecentSearches = 8

    init() {
        loadRecentSearches()
        Task {
            await loadTrendingMovies()
        }
    }

    func search() async {
        searchTask?.cancel()

        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            multiSearchResults = []
            return
        }

        searchTask = Task {
            isSearching = true
            defer { isSearching = false }
            errorMessage = nil

            try? await Task.sleep(nanoseconds: 300_000_000)

            guard !Task.isCancelled else {
                return
            }

            do {
                let results = try await TMDBService.shared.searchMulti(query: searchQuery)
                multiSearchResults = results
                saveRecentSearch(searchQuery)
            } catch is CancellationError {
                return
            } catch {
                errorMessage = "Search failed: \(error.localizedDescription)"
                multiSearchResults = []
            }
        }
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
        multiSearchResults = []
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

        recentSearches.removeAll { $0.lowercased() == trimmed.lowercased() }
        recentSearches.insert(trimmed, at: 0)

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
