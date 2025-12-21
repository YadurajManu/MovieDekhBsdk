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
    @Published var selectedContext: String?
    @Published var selectedActors: Set<Int> = []
    @Published var selectedVibe: String?
    @Published var selectedEra: String?
    @Published var subtitlePreference: String?
    @Published var winnerId: Int?
    
    @Published var isLoading = false

    // Personal Details
    @Published var name: String = ""
    @Published var age: String = ""
    
    var isStep1Valid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !age.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                    // Increased to 24 for more choices
                    recognitionMovies = try await TMDBService.shared.fetchTopMovies().shuffled().prefix(24).map { $0 }
                }
            case .polarity:
                // Reuse recognition movies or fetch new ones
                if polarityMovies.isEmpty {
                    polarityMovies = try await TMDBService.shared.fetchNowPlaying().shuffled().prefix(4).map { $0 }
                }
            case .actors:
                if popularActors.isEmpty {
                    // Increased to 18
                    popularActors = try await TMDBService.shared.fetchPopularPeople().prefix(18).map { $0 }
                }
            case .era:
                if eraMovies.isEmpty {
                    // Fetch diverse eras: 90s, 2000s, 2010s, 2020s
                    // For simplicity, just fetch one era now, or mix
                     eraMovies = try await TMDBService.shared.fetchMoviesByEra(startYear: 1990, endYear: 2010).prefix(4).map { $0 }
                }
            case .competition:
                 let movies = try await TMDBService.shared.fetchHighlyRatedMovies()
                 if movies.count >= 2 {
                     competitionPair = Array(movies.prefix(2))
                 }
            case .result:
                // In a real app, calculate based on inputs. For now, pick a random top movie
                let recs = try await TMDBService.shared.fetchTopRated()
                recommendedMovie = recs.randomElement()
            default:
                break
            }
        } catch {
            print("Error loading data for step \(step): \(error)")
        }
        isLoading = false
    }
    
    // Selection Logics here
    func toggleRecognition(id: Int) {
        if selectedRecognitionIds.contains(id) { selectedRecognitionIds.remove(id) }
        else { selectedRecognitionIds.insert(id) }
    }
    
    func setPolarity(id: Int, liked: Bool) {
        if liked {
            likedMovies.insert(id)
            dislikedMovies.remove(id)
        } else {
            dislikedMovies.insert(id)
            likedMovies.remove(id)
        }
    }
    
    func toggleActor(id: Int) {
         if selectedActors.contains(id) { selectedActors.remove(id) }
         else { selectedActors.insert(id) }
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
            "context": selectedContext ?? "",
            "actors": Array(selectedActors),
            "directors": Array(selectedDirectorIds),
            "vibe": selectedVibe ?? "",
            "era": selectedEra ?? "",
            "subtitlePreference": subtitlePreference ?? "",
            "competitionWinner": winnerId ?? -1,
            "recommendedMovieId": recommendedMovie?.id ?? -1,
            "timestamp": Timestamp()
        ]
        
        Task {
            try? await FirestoreService.shared.saveOnboardingData(userId: user.uid, data: data)
        }
    }
}
