import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

enum OnboardingStep: Int, CaseIterable {
    case personalDetails = 0
    case recognition
    case polarity
    case context
    case actors
    case directors
    case vibe
    case era
    case language
    case competition
    case result
}

enum OnboardingSentiment: String, Codable {
    case loved = "loved"
    case okay = "okay"
    case disliked = "disliked"
    case unseen = "unseen"
}

class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .personalDetails
    @Published var progress: Double = 0.0
    
    // Data Sources for steps
    @Published var recognitionMovies: [Movie] = []
    @Published var polarityMovies: [Movie] = []
    @Published var contextOptions: [String] = [
        "Late Night", "Date Night", "Sunday Afternoon", "Solo Watch",
        "With Parents", "Party w/ Friends", "Rainy Day", "Workout",
        "Background Noise", "Critical Watch"
    ]
    @Published var popularActors: [Person] = []
    @Published var directors: [Person] = [] // Placeholder if we implement directors
    @Published var vibes: [String] = [
        "Dark", "Hopeful", "Weird", "Comfort", 
        "Mind-bending", "Adrenaline", "Romantic", "Nostalgic",
        "Intellectual", "Funny"
    ]
    @Published var eraMovies: [Movie] = []
    @Published var competitionPair: [Movie] = []
    @Published var recommendedMovie: Movie?
    
    // User Selections
    @Published var selectedRecognitionIds: Set<Int> = []
    @Published var likedMovies: Set<Int> = []
    @Published var dislikedMovies: Set<Int> = []
    @Published var selectedContexts: Set<String> = []
    @Published var selectedActors: Set<Int> = []
    @Published var selectedVibes: Set<String> = []
    @Published var selectedEra: String?
    @Published var subtitlePreference: String?
    @Published var winnerId: Int?
    
    @Published var isLoading = false

    @Published var name: String = ""
    @Published var age: String = ""
    
    // Step 3 Sentiments
    @Published var movieSentiments: [Int: OnboardingSentiment] = [:]
    
    // Taste Profile
    @Published var isNicheLeaning: Bool = false
    
    var isStep1Valid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !age.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isStep3Valid: Bool {
        movieSentiments.values.contains { $0 != .unseen }
    }
    
    var isStep4Valid: Bool {
        !selectedContexts.isEmpty
    }
    
    var isStep5Valid: Bool {
        true // Optional per requirements
    }
    
    var isStep6Valid: Bool {
        true // Optional per requirements
    }
    
    var isStep7Valid: Bool {
        !selectedVibes.isEmpty
    }
    
    private func updateTasteProfile() {
        let selectedMovies = recognitionMovies.filter { selectedRecognitionIds.contains($0.id) }
        guard !selectedMovies.isEmpty else { return }
        
        // Naive niche calculation: average vote count (as proxy for popularity)
        // Lower vote count = more niche
        let avgVoteCount = selectedMovies.reduce(0.0) { $0 + Double($1.voteCount) } / Double(selectedMovies.count)
        
        // Threshold: if average vote count is below 5000, consider them niche-leaning
        // (This threshold depends on TMDB data distributions but works as a relative proxy)
        isNicheLeaning = avgVoteCount < 5000
    }
    
    init() {
        self.progress = 0.1
    }
    
    func moveToNextStep() {
        actorSearchQuery = "" // Clear search
        let nextIndex = currentStep.rawValue + 1
        if let nextStep = OnboardingStep(rawValue: nextIndex) {
            withAnimation {
                currentStep = nextStep
                progress = Double(nextIndex + 1) / Double(OnboardingStep.allCases.count)
            }
            loadStepData(step: nextStep)
        }
    }
    
    func moveToPreviousStep() {
        actorSearchQuery = "" // Clear search
        let prevIndex = currentStep.rawValue - 1
        if let prevStep = OnboardingStep(rawValue: prevIndex), prevIndex >= 0 {
            withAnimation {
                currentStep = prevStep
                progress = Double(prevIndex + 1) / Double(OnboardingStep.allCases.count)
            }
        }
    }
    
    func loadStepData(step: OnboardingStep) {
        Task {
            await loadData(for: step)
        }
    }
    
    @MainActor
    private func loadData(for step: OnboardingStep) async {
        isLoading = true
        do {
            switch step {
            case .recognition:
                if recognitionMovies.isEmpty {
                    await loadCalibrationSet()
                }
            case .polarity:
                if polarityMovies.isEmpty {
                    // Adapt Polarity: if niche-leaning, show more diverse/challenging titles
                    if isNicheLeaning {
                        // High rated but not necessarily super popular
                        let nicheHits = try await TMDBService.shared.fetchTopRated(page: Int.random(in: 4...8))
                        polarityMovies = nicheHits.shuffled().prefix(4).map { $0 }
                    } else {
                        polarityMovies = try await TMDBService.shared.fetchNowPlaying().shuffled().prefix(4).map { $0 }
                    }
                }
            case .actors:
                if popularActors.isEmpty {
                    popularActors = try await TMDBService.shared.fetchPopularPeople().prefix(18).map { $0 }
                }
            case .era:
                if eraMovies.isEmpty {
                     eraMovies = try await TMDBService.shared.fetchMoviesByEra(startYear: 1990, endYear: 2010).prefix(4).map { $0 }
                }
            case .competition:
                 // Adapt Competition: pick two movies that contrast user's taste
                 let movies = try await (isNicheLeaning ? TMDBService.shared.fetchTopRated(page: 10) : TMDBService.shared.fetchHighlyRatedMovies())
                 if movies.count >= 2 {
                     competitionPair = Array(movies.prefix(2))
                 }
            case .result:
                let recs = try await (isNicheLeaning ? TMDBService.shared.fetchTopRated(page: 2) : TMDBService.shared.fetchTopRated(page: 1))
                recommendedMovie = recs.randomElement()
            default:
                break
            }
        } catch {
            print("Error loading data for step \(step): \(error)")
        }
        isLoading = false
    }

    @MainActor
    private func loadCalibrationSet() async {
        do {
            // TIER 1: High Visibility (Increased to 20)
            let popular = try await TMDBService.shared.fetchTopMovies(page: 1)
            let tier1 = popular.shuffled().prefix(20)
            
            // TIER 2: Cultural Significance (Increased to 25)
            // Fetch two pages for a broader pool
            let topRated1 = try await TMDBService.shared.fetchTopRated(page: Int.random(in: 2...4))
            let topRated2 = try await TMDBService.shared.fetchTopRated(page: Int.random(in: 5...8))
            let tier2 = (topRated1 + topRated2).shuffled().prefix(25)
            
            // TIER 3: Discovery/Niche (Increased to 15)
            let filter = FilterState()
            var nicheFilter = filter
            nicheFilter.minVoteAverage = 7.0
            nicheFilter.minVoteCount = 100
            let nicheCandidates = try await TMDBService.shared.discoverMovies(filter: nicheFilter)
            let tier3 = nicheCandidates.shuffled().prefix(15)
            
            var combined = Array(tier1) + Array(tier2) + Array(tier3)
            
            // Shuffle to break tier clusters
            combined.shuffle()
            
            self.recognitionMovies = combined
        } catch {
            print("Failed to load calibration set: \(error)")
            // Fallback
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            self.recognitionMovies = (try? await TMDBService.shared.fetchTopMovies()) ?? []
        }
    }
    
    // Selection Logics here
    func toggleRecognition(id: Int) {
        if selectedRecognitionIds.contains(id) { 
            selectedRecognitionIds.remove(id) 
        } else { 
            selectedRecognitionIds.insert(id) 
        }
        updateTasteProfile()
    }
    
    func updateSentiment(movieId: Int, sentiment: OnboardingSentiment) {
        if movieSentiments[movieId] == sentiment {
            movieSentiments[movieId] = .unseen
            likedMovies.remove(movieId)
            dislikedMovies.remove(movieId)
        } else {
            movieSentiments[movieId] = sentiment
            
            // Sync with liked/disliked for backward compatibility
            switch sentiment {
            case .loved:
                likedMovies.insert(movieId)
                dislikedMovies.remove(movieId)
            case .disliked:
                dislikedMovies.insert(movieId)
                likedMovies.remove(movieId)
            case .okay, .unseen:
                likedMovies.remove(movieId)
                dislikedMovies.remove(movieId)
            }
        }
    }
    
    func toggleContext(_ context: String) {
        if selectedContexts.contains(context) {
            selectedContexts.remove(context)
        } else {
            selectedContexts.insert(context)
        }
    }
    
    func toggleActor(id: Int) {
         if selectedActors.contains(id) { selectedActors.remove(id) }
         else { selectedActors.insert(id) }
    }
    
    func toggleVibe(_ vibe: String) {
        if selectedVibes.contains(vibe) {
            selectedVibes.remove(vibe)
        } else {
            selectedVibes.insert(vibe)
        }
    }
    
    @Published var selectedDirectorIds: Set<Int> = []
    
    // Search
    @Published var actorSearchQuery = ""
    @Published var searchedPeople: [Person] = []
    private var searchTask: Task<Void, Never>?
    
    func searchPeople(query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchedPeople = []
            return
        }
        
        searchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // Debounce
                let results = try await TMDBService.shared.searchMulti(query: query)
                // Filter for people
                let people = results.filter { $0.mediaType == .person }.map {
                    Person(id: $0.id, name: $0.displayTitle, profilePath: $0.posterPath, knownForDepartment: nil)
                }
                
                await MainActor.run {
                    self.searchedPeople = people
                }
            } catch {
                print("Search people error: \(error)")
            }
        }
    }
    
    func toggleDirector(id: Int) {
         if selectedDirectorIds.contains(id) { selectedDirectorIds.remove(id) }
         else { selectedDirectorIds.insert(id) }
    }

    // Save to Firestore
    func saveResults() {
        guard let user = AuthenticationService.shared.user else { return }
        
        let data: [String: Any] = [
            "name": name,
            "age": age,
            "recognitionIds": Array(selectedRecognitionIds),
            "likedMovies": Array(likedMovies),
            "dislikedMovies": Array(dislikedMovies),
            "selectedContexts": Array(selectedContexts),
            "selectedActors": Array(selectedActors),
            "directors": Array(selectedDirectorIds),
            "selectedVibes": Array(selectedVibes),
            "era": selectedEra ?? "",
            "subtitlePreference": subtitlePreference ?? "",
            "movieSentiments": movieSentiments.reduce(into: [String: String]()) { $0[String($1.key)] = $1.value.rawValue },
            "competitionWinner": winnerId ?? -1,
            "recommendedMovieId": recommendedMovie?.id ?? -1,
            "timestamp": Timestamp()
        ]
        
        Task {
            try? await FirestoreService.shared.saveOnboardingData(userId: user.uid, data: data)
        }
    }
}
