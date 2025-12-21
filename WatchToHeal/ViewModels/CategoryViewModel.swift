//
//  CategoryViewModel.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import Foundation
import Combine

@MainActor
class CategoryViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    
    private var currentPage = 1
    private var canLoadMore = true
    
    func loadMovies(category: MovieCategory) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        currentPage = 1
        canLoadMore = true
        
        do {
            let results = try await fetchMovies(category: category, page: currentPage)
            movies = results
        } catch {
            errorMessage = "Failed to load movies: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadMoreIfNeeded(category: MovieCategory) async {
        guard !isLoadingMore && canLoadMore else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let results = try await fetchMovies(category: category, page: currentPage)
            if results.isEmpty {
                canLoadMore = false
            } else {
                // Filter out duplicates before appending
                let existingIDs = Set(movies.map { $0.id })
                let newMovies = results.filter { !existingIDs.contains($0.id) }
                movies.append(contentsOf: newMovies)
                
                // If no new movies were added, stop loading more
                if newMovies.isEmpty {
                    canLoadMore = false
                }
            }
        } catch {
            print("Failed to load more: \(error)")
            currentPage -= 1
        }
        
        isLoadingMore = false
    }
    
    private func fetchMovies(category: MovieCategory, page: Int) async throws -> [Movie] {
        switch category {
        case .nowPlaying:
            return try await TMDBService.shared.fetchNowPlaying(page: page)
        case .upcoming:
            return try await TMDBService.shared.fetchUpcoming(page: page)
        case .topRated:
            return try await TMDBService.shared.fetchTopRated(page: page)
        case .trending:
            return try await TMDBService.shared.fetchTrending() // Trending doesn't always support pagination in simplicity
        case .action:
            return try await TMDBService.shared.fetchMoviesByGenre(genreId: 28, page: page)
        case .comedy:
            return try await TMDBService.shared.fetchMoviesByGenre(genreId: 35, page: page)
        case .drama:
            return try await TMDBService.shared.fetchMoviesByGenre(genreId: 18, page: page)
        case .horror:
            return try await TMDBService.shared.fetchHorrorMovies() // I should probably update these too if I had more methods
        case .sciFi:
            return try await TMDBService.shared.fetchMoviesByGenre(genreId: 878, page: page)
        case .thriller:
            return try await TMDBService.shared.fetchThrillerMovies()
        case .romance:
            return try await TMDBService.shared.fetchRomanceMovies()
        case .animation:
            return try await TMDBService.shared.fetchAnimationMovies()
        case .documentary:
            return try await TMDBService.shared.fetchDocumentaryMovies(page: page)
        case .crime:
            return try await TMDBService.shared.fetchCrimeMovies(page: page)
        case .adventure:
            return try await TMDBService.shared.fetchAdventureMovies(page: page)
        case .war:
            return try await TMDBService.shared.fetchWarMovies(page: page)
        case .indianClassics:
            return try await TMDBService.shared.fetchMasterpiecesByLanguage(isoCode: "hi", page: page)
        case .frenchCinema:
            return try await TMDBService.shared.fetchMasterpiecesByLanguage(isoCode: "fr", page: page)
        case .koreanMasterpieces:
            return try await TMDBService.shared.fetchMasterpiecesByLanguage(isoCode: "ko", page: page)
        case .japaneseMasterpieces:
            return try await TMDBService.shared.fetchMasterpiecesByLanguage(isoCode: "ja", page: page)
        case .netflix:
            return try await TMDBService.shared.fetchMoviesByProvider(providerId: 8, page: page)
        case .disney:
            return try await TMDBService.shared.fetchMoviesByProvider(providerId: 337, page: page)
        case .amazon:
            return try await TMDBService.shared.fetchMoviesByProvider(providerId: 119, page: page)
        case .appleTV:
            return try await TMDBService.shared.fetchMoviesByProvider(providerId: 350, page: page)
        }
    }
}
