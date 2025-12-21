import Foundation
import Combine

@MainActor
class ActivityViewModel: ObservableObject {
    @Published var activities: [UserActivity] = []
    @Published var stats = UserStats()
    @Published var isLoading = false
    @Published var selectedFilter: ActivityType? = nil
    
    private let firestoreService = FirestoreService.shared
    private let userId: String
    
    var filteredActivities: [UserActivity] {
        if let filter = selectedFilter {
            if filter == .comment {
                return activities.filter { $0.type == .comment || $0.type == .reply }
            }
            return activities.filter { $0.type == filter }
        }
        return activities
    }
    
    init(userId: String) {
        self.userId = userId
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Perform sync first to ensure all activities are present
            try? await firestoreService.syncPastActivities(userId: userId)
            
            async let fetchedActivities = firestoreService.fetchUserActivities(userId: userId)
            async let fetchedStats = firestoreService.getUserStats(userId: userId)
            
            self.activities = try await fetchedActivities
            self.stats = try await fetchedStats
        } catch {
            print("Error loading activity data: \(error)")
        }
    }
    
    func streakMessage() -> String {
        if stats.currentStreak == 0 {
            return "Start your streak today! 🚀"
        } else if stats.currentStreak == 1 {
            return "1 day streak! Keep it up! 🔥"
        } else {
            return "\(stats.currentStreak) day streak! You're on fire! 🔥"
        }
    }
}
