import SwiftUI
import Combine

class StreamingSettingsViewModel: ObservableObject {
    @Published var providers: [TMDBService.WatchProvidersResponse.Provider] = []
    @Published var selectedProviderIds: Set<Int> = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    
    private let tmdbService = TMDBService.shared
    private let firestoreService = FirestoreService.shared
    
    @MainActor
    func loadProviders(currentSelected: [Int], region: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            providers = try await tmdbService.fetchAllWatchProviders(region: region)
            selectedProviderIds = Set(currentSelected)
        } catch {
            print("❌ Error loading watch providers: \(error)")
        }
    }
    
    var filteredProviders: [TMDBService.WatchProvidersResponse.Provider] {
        if searchQuery.isEmpty {
            return providers
        }
        return providers.filter { $0.providerName.lowercased().contains(searchQuery.lowercased()) }
    }
    
    func toggleProvider(_ providerId: Int) {
        if selectedProviderIds.contains(providerId) {
            selectedProviderIds.remove(providerId)
        } else {
            selectedProviderIds.insert(providerId)
        }
    }
    
    @MainActor
    func savePreferences(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await firestoreService.updateStreamingProviders(userId: userId, providerIds: Array(selectedProviderIds))
        } catch {
            print("❌ Error saving streaming preferences: \(error)")
        }
    }
}
