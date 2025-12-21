import SwiftUI
import Combine

@MainActor
class CommunityListsViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var selectedMovies: [Movie] = []
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    
    // Lists for display
    @Published var userLists: [CommunityList] = []
    @Published var communityLists: [CommunityList] = []
    @Published var isLoading: Bool = false
    @Published var suggestions: [Movie] = []
    
    func createList(ownerId: String, ownerName: String) async -> Bool {
        guard !title.isEmpty else {
            errorMessage = "Please enter a title for your list."
            return false
        }
        
        isSaving = true
        errorMessage = nil
        
        let newList = CommunityList(
            id: UUID().uuidString,
            ownerId: ownerId,
            ownerName: ownerName,
            title: title,
            description: description,
            movies: selectedMovies,
            likeCount: 0,
            commentCount: 0,
            likedBy: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await FirestoreService.shared.createCommunityList(list: newList)
            isSaving = false
            resetForm()
            return true
        } catch {
            errorMessage = "Failed to create list: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
    
    func fetchUserLists(userId: String) async {
        isLoading = true
        do {
            print("Fetching lists for user: \(userId)")
            userLists = try await FirestoreService.shared.fetchUserCommunityLists(userId: userId)
            print("Successfully fetched \(userLists.count) lists for user")
        } catch {
            print("Failed to fetch user lists: \(error.localizedDescription)")
            errorMessage = "Failed to load your collections: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func fetchAllLists() async {
        isLoading = true
        do {
            communityLists = try await FirestoreService.shared.fetchAllCommunityLists()
        } catch {
            print("Failed to fetch all lists: \(error)")
        }
        isLoading = false
    }
    
    func fetchSuggestions() async {
        do {
            suggestions = try await TMDBService.shared.fetchNowPlaying()
        } catch {
            print("Failed to fetch suggestions: \(error)")
        }
    }
    
    func toggleSelection(_ movie: Movie) {
        if let index = selectedMovies.firstIndex(where: { $0.id == movie.id }) {
            selectedMovies.remove(at: index)
        } else {
            selectedMovies.append(movie)
        }
    }
    
    func removeMovie(at offsets: IndexSet) {
        selectedMovies.remove(atOffsets: offsets)
    }
    
    func moveMovie(from source: IndexSet, to destination: Int) {
        selectedMovies.move(fromOffsets: source, toOffset: destination)
    }
    
    private func resetForm() {
        title = ""
        description = ""
        selectedMovies = []
    }
}
