//
//  HomeViewModel.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import Foundation
import Combine

enum HomeSegment: String, CaseIterable {
    case movies = "Movies"
    case series = "Web Series"
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var selectedSegment: HomeSegment = .movies
    
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
    
    // Series Data
    @Published var tradingSeries: [Movie] = []
    @Published var actionSeries: [Movie] = []
    @Published var comedySeries: [Movie] = []
    @Published var dramaSeries: [Movie] = []
    @Published var sciFiSeries: [Movie] = []
    @Published var mysterySeries: [Movie] = []
    @Published var topRatedSeries: [Movie] = []
    @Published var netflixSeries: [Movie] = []
    @Published var disneySeries: [Movie] = []
    @Published var amazonSeries: [Movie] = []
    @Published var appleTVSeries: [Movie] = []
    
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
            // Trigger all tasks and wait for them
            _ = try await (
                recommendationsTask, trendingTask, nowPlayingTask, upcomingTask, topRatedTask,
                actionTask, comedyTask, dramaTask, sciFiTask,
                horrorTask, romanceTask, thrillerTask, animationTask, documentaryTask,
                crimeTask, mysteryTask, adventureTask, warTask,
                japanTask, franceTask, koreaTask, indiaTask,
                netflixTask, disneyTask, amazonTask, appleTVTask
            )
            
            // Assign results directly to published properties to ensure type safety and avoid tuple explosion issues
            tradingMovies = try await trendingTask
            nowPlaying = try await nowPlayingTask
            upcoming = try await upcomingTask
            topRated = try await topRatedTask
            actionMovies = try await actionTask
            comedyMovies = try await comedyTask
            dramaMovies = try await dramaTask
            sciFiMovies = try await sciFiTask
            horrorMovies = try await horrorTask
            romanceMovies = try await romanceTask
            thrillerMovies = try await thrillerTask
            animationMovies = try await animationTask
            documentaryMovies = try await documentaryTask
            crimeMovies = try await crimeTask
            mysteryMovies = try await mysteryTask
            adventureMovies = try await adventureTask
            warMovies = try await warTask
            
            japaneseMasterpieces = try await japanTask
            frenchMasterpieces = try await franceTask
            koreanMasterpieces = try await koreaTask
            indianMasterpieces = try await indiaTask
            
            netflixMovies = try await netflixTask
            disneyMovies = try await disneyTask
            amazonMovies = try await amazonTask
            appleTVMovies = try await appleTVTask
            
            // Load director data
            await loadDirectorData()
            
            // Load TV Series data
            await loadAllSeries(region: region)
            
        } catch {
            errorMessage = "Failed to load movies: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadPersonalizedRecommendations() async {
        isLoadingRecommendations = true
        
        // Get seeds from Watchlist and History
        let watchlistSeeds = WatchlistManager.shared.watchlistMovies.compactMap { $0.title }
        let historySeeds = HistoryManager.shared.watchedMovies.compactMap { $0.title }
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
    
    func loadAllSeries(region: String = "US") async {
        async let trendingTask = TMDBService.shared.fetchTrendingTV()
        async let actionTask = TMDBService.shared.fetchTVByGenre(genreId: 10759) // Action & Adventure
        async let comedyTask = TMDBService.shared.fetchTVByGenre(genreId: 35)
        async let dramaTask = TMDBService.shared.fetchTVByGenre(genreId: 18)
        async let sciFiTask = TMDBService.shared.fetchTVByGenre(genreId: 10765) // Sci-Fi & Fantasy
        async let mysteryTask = TMDBService.shared.fetchTVByGenre(genreId: 9648)
        async let topRatedTask = TMDBService.shared.fetchTopRatedTV()
        
        // Streaming Service Tasks for TV
        async let netflixTask = TMDBService.shared.fetchTVByProvider(providerId: 8, region: region)
        async let disneyTask = TMDBService.shared.fetchTVByProvider(providerId: 337, region: region)
        async let amazonTask = TMDBService.shared.fetchTVByProvider(providerId: 119, region: region)
        async let appleTVTask = TMDBService.shared.fetchTVByProvider(providerId: 350, region: region)
        
        do {
            let (trending, action, comedy, drama, sciFi, mystery, top, netflix, disney, amazon, appleTV) = try await (
                trendingTask, actionTask, comedyTask, dramaTask, sciFiTask, mysteryTask, topRatedTask,
                netflixTask, disneyTask, amazonTask, appleTVTask
            )
            
            tradingSeries = trending
            actionSeries = action
            comedySeries = comedy
            dramaSeries = drama
            sciFiSeries = sciFi
            mysterySeries = mystery
            topRatedSeries = top
            netflixSeries = netflix
            disneySeries = disney
            amazonSeries = amazon
            appleTVSeries = appleTV
            
        } catch {
            print("Failed to load TV series: \(error)")
        }
    }
}
