import SwiftUI
import Combine

@MainActor
class ActorDetailViewModel: ObservableObject {
    @Published var person: PersonDetail?
    @Published var topCredits: [CombinedCredit] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tmdbService = TMDBService.shared
    
    func loadActorDetail(id: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let personDetail = tmdbService.fetchPersonDetails(id: id)
            async let credits = tmdbService.fetchPersonCombinedCredits(id: id)
            
            let (fetchedPerson, fetchedCredits) = try await (personDetail, credits)
            
            self.person = fetchedPerson
            
            // Sort credits by popularity/vote average and take top 20
            // We'll filter for cast roles mostly, or important crew roles if needed.
            let allCredits = fetchedCredits.cast + fetchedCredits.crew
            
            // Deduplicate by ID
            var uniqueCredits: [Int: CombinedCredit] = [:]
            for credit in allCredits {
                if uniqueCredits[credit.id] == nil {
                    uniqueCredits[credit.id] = credit
                } else {
                    // If duplicate, prefer the one with a poster if the existing one doesn't have one
                    if uniqueCredits[credit.id]?.posterPath == nil && credit.posterPath != nil {
                        uniqueCredits[credit.id] = credit
                    }
                }
            }
            
            self.topCredits = uniqueCredits.values
                .sorted { $0.voteAverage > $1.voteAverage }
                .prefix(20)
                .map { $0 }
            
            isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
