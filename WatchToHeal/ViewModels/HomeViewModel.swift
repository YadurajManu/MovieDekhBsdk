//
//  HomeViewModel.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var tradingMovies: [Movie] = []
    @Published var actionMovies: [Movie] = []
    @Published var comedyMovies: [Movie] = []
    @Published var dramaMovies: [Movie] = []
    @Published var sciFiMovies: [Movie] = []
    @Published var horrorMovies: [Movie] = []
    @Published var romanceMovies: [Movie] = []
    @Published var thrillerMovies: [Movie] = []
    @Published var animationMovies: [Movie] = []
    @Published var documentaryMovies: [Movie] = []
    @Published var crimeMovies: [Movie] = []
    @Published var mysteryMovies: [Movie] = []
    @Published var adventureMovies: [Movie] = []
    @Published var warMovies: [Movie] = []
    @Published var nowPlaying: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var topRated: [Movie] = []
    @Published var personalizedRecommendations: [Movie] = []
    
    // UI State
    @Published var isLoadingRecommendations = false
    
    // World Cinema
    @Published var japaneseMasterpieces: [Movie] = []
    @Published var frenchMasterpieces: [Movie] = []
    @Published var koreanMasterpieces: [Movie] = []
    @Published var indianMasterpieces: [Movie] = []
    
    // Streaming Services
    @Published var netflixMovies: [Movie] = []
    @Published var disneyMovies: [Movie] = []
    @Published var amazonMovies: [Movie] = []
    @Published var appleTVMovies: [Movie] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Director data
    @Published var directorDetails: [Int: TMDBService.PersonDetail] = [:]
    @Published var directorMovies: [Int: [Movie]] = [:]
    
    // Famous directors (TMDB IDs)
    let famousDirectors: [(id: Int, name: String)] = [
        (525, "Christopher Nolan"),
        (138, "Quentin Tarantino"),
        (488, "Steven Spielberg"),
        (1032, "Martin Scorsese"),
        (7467, "David Fincher"),
        (108916, "Greta Gerwig")
    ]
    
    func loadAllMovies(region: String = "US") async {
        isLoading = true
        errorMessage = nil
        
        // Fetch all movie categories concurrently (including recommendations)
        async let recommendationsTask = loadPersonalizedRecommendations()
        async let trendingTask = TMDBService.shared.fetchTrending()
        async let nowPlayingTask = TMDBService.shared.fetchNowPlaying(region: region)
        async let upcomingTask = TMDBService.shared.fetchUpcoming(region: region)
        async let topRatedTask = TMDBService.shared.fetchTopRated()
        async let actionTask = TMDBService.shared.fetchMoviesByGenre(genreId: 28)
        async let comedyTask = TMDBService.shared.fetchMoviesByGenre(genreId: 35)
        async let dramaTask = TMDBService.shared.fetchMoviesByGenre(genreId: 18)
        async let sciFiTask = TMDBService.shared.fetchMoviesByGenre(genreId: 878)
        async let horrorTask = TMDBService.shared.fetchHorrorMovies()
        async let romanceTask = TMDBService.shared.fetchRomanceMovies()
        async let thrillerTask = TMDBService.shared.fetchThrillerMovies()
        async let animationTask = TMDBService.shared.fetchAnimationMovies()
        async let documentaryTask = TMDBService.shared.fetchDocumentaryMovies()
        async let crimeTask = TMDBService.shared.fetchCrimeMovies()
        async let mysteryTask = TMDBService.shared.fetchMysteryMovies()
        async let adventureTask = TMDBService.shared.fetchAdventureMovies()
        async let warTask = TMDBService.shared.fetchWarMovies()
        
        // World Cinema Tasks
        async let japanTask = TMDBService.shared.fetchMasterpiecesByLanguage(isoCode: "ja")
        async let franceTask = TMDBService.shared.fetchMasterpiecesByLanguage(isoCode: "fr")
        async let koreaTask = TMDBService.shared.fetchMasterpiecesByLanguage(isoCode: "ko")
        async let indiaTask = TMDBService.shared.fetchMasterpiecesByLanguage(isoCode: "hi")
        
        // Streaming Service Tasks
        async let netflixTask = TMDBService.shared.fetchMoviesByProvider(providerId: 8, region: region)
        async let disneyTask = TMDBService.shared.fetchMoviesByProvider(providerId: 337, region: region)
        async let amazonTask = TMDBService.shared.fetchMoviesByProvider(providerId: 119, region: region)
        async let appleTVTask = TMDBService.shared.fetchMoviesByProvider(providerId: 350, region: region)
        
        do {
            let (_, trending, playing, up, top, action, comedy, drama, sciFi, horror, romance, thriller, animation, documentary, crime, mystery, adventure, war, japan, france, korea, india, netflix, disney, amazon, appleTV) = try await (
                recommendationsTask, trendingTask, nowPlayingTask, upcomingTask, topRatedTask,
                actionTask, comedyTask, dramaTask, sciFiTask,
                horrorTask, romanceTask, thrillerTask, animationTask, documentaryTask,
                crimeTask, mysteryTask, adventureTask, warTask,
                japanTask, franceTask, koreaTask, indiaTask,
                netflixTask, disneyTask, amazonTask, appleTVTask
            )
            
            tradingMovies = trending
            nowPlaying = playing
            upcoming = up
            topRated = top
            actionMovies = action
            comedyMovies = comedy
            dramaMovies = drama
            sciFiMovies = sciFi
            horrorMovies = horror
            romanceMovies = romance
            thrillerMovies = thriller
            animationMovies = animation
            documentaryMovies = documentary
            crimeMovies = crime
            mysteryMovies = mystery
            adventureMovies = adventure
            warMovies = war
            
            // Assign World Cinema
            japaneseMasterpieces = japan
            frenchMasterpieces = france
            koreanMasterpieces = korea
            indianMasterpieces = india
            
            // Assign Streaming Services
            netflixMovies = netflix
            disneyMovies = disney
            amazonMovies = amazon
            appleTVMovies = appleTV
            
            // Load director data
            await loadDirectorData()
            
        } catch {
            errorMessage = "Failed to load movies: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadPersonalizedRecommendations() async {
        isLoadingRecommendations = true
        
        // Get seeds from Watchlist and History
        let watchlistSeeds = WatchlistManager.shared.watchlistMovies.map { $0.title }
        let historySeeds = HistoryManager.shared.watchedMovies.map { $0.title }
        var allSeeds = Array(Set(watchlistSeeds + historySeeds))
        
        // Fallback seeds if user has no data yet (ensure it's not empty)
        if allSeeds.isEmpty {
            allSeeds = ["Interstellar", "Inception", "The Dark Knight", "The Godfather", "Pulp Fiction"]
        }
        
        let finalSeeds = Array(allSeeds.prefix(5))
        
        do {
            let titles = try await TasteDiveService.shared.fetchRecommendations(for: finalSeeds)
            
            // Map titles back to TMDB movies concurrently
            var resolvedMovies: [Movie] = []
            
            await withTaskGroup(of: Movie?.self) { group in
                for title in titles.prefix(20) {
                    group.addTask {
                        do {
                            let results = try await TMDBService.shared.searchMovies(query: title)
                            return results.first
                        } catch {
                            return nil
                        }
                    }
                }
                
                for await movie in group {
                    if let movie = movie {
                        resolvedMovies.append(movie)
                    }
                }
            }
            
            // Filter out duplicates and movies already in history
            let watchedIds = Set(HistoryManager.shared.watchedMovies.map { $0.id })
            self.personalizedRecommendations = resolvedMovies.filter { !watchedIds.contains($0.id) }
            
        } catch {
            print("Failed to load personalized recommendations: \(error)")
        }
        
        isLoadingRecommendations = false
    }
    
    private func loadDirectorData() async {
        // Fetch first 3 directors for performance
        for director in famousDirectors.prefix(3) {
            do {
                async let detailTask = TMDBService.shared.fetchPersonDetails(id: director.id)
                async let moviesTask = TMDBService.shared.fetchPersonMovieCredits(id: director.id)
                
                let (detail, movies) = try await (detailTask, moviesTask)
                
                directorDetails[director.id] = detail
                directorMovies[director.id] = movies
            } catch {
                print("Failed to load director \(director.name): \(error)")
            }
        }
    }
}
