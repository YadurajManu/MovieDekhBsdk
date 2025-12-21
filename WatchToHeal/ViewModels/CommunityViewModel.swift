import Foundation
import Combine

@MainActor
class CommunityViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [UserProfile] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private var searchTask: Task<Void, Never>?
    
    func performSearch() {
        searchTask?.cancel()
        
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // Debounce 0.5s
            if Task.isCancelled { return }
            
            do {
                let results = try await FirestoreService.shared.searchUsers(query: searchQuery)
                if !Task.isCancelled {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = "Failed to search users"
                    self.isSearching = false
                }
            }
        }
    }
}
