import Foundation
import FirebaseFirestore
import Combine

@MainActor
class PulseViewModel: ObservableObject {
    // Section-based content
    @Published var trendingPolls: [MoviePoll] = []
    @Published var hotDebates: [CommunityQuestion] = []
    @Published var latestContent: [PulseItem] = []
    @Published var topContributors: [ContributorProfile] = []
    @Published var yourContent: [PulseItem] = []
    
    @Published var isLoading = true
    
    init() {
        // Load all sections on init
        Task {
            await loadAllSections(userId: nil)
        }
    }
    
    func loadAllSections(userId: String?) async {
        isLoading = true
        
        // Load all sections in parallel for maximum speed
        async let trendingTask = loadTrendingPolls()
        async let debatesTask = loadHotDebates()
        async let latestTask = loadLatest()
        async let contributorsTask = loadTopContributors()
        async let yoursTask = loadYourContent(userId: userId)
        
        // Wait for all to complete
        _ = await (trendingTask, debatesTask, latestTask, contributorsTask, yoursTask)
        
        isLoading = false
    }
    
    private func loadTrendingPolls() async {
        do {
            trendingPolls = try await FirestoreService.shared.fetchTrendingPolls(limit: 5)
        } catch {
            print("❌ Failed to load trending polls: \(error)")
        }
    }
    
    private func loadHotDebates() async {
        do {
            hotDebates = try await FirestoreService.shared.fetchHotDebates(limit: 5)
        } catch {
            print("❌ Failed to load hot debates: \(error)")
        }
    }
    
    private func loadLatest() async {
        do {
            latestContent = try await FirestoreService.shared.fetchLatestPulseContent(limit: 10)
        } catch {
            print("❌ Failed to load latest content: \(error)")
        }
    }
    
    private func loadTopContributors() async {
        do {
            topContributors = try await FirestoreService.shared.fetchTopContributors(limit: 3)
        } catch {
            print("❌ Failed to load top contributors: \(error)")
        }
    }
    
    private func loadYourContent(userId: String?) async {
        guard let userId = userId else {
            yourContent = []
            return
        }
        do {
            yourContent = try await FirestoreService.shared.fetchUserContent(userId: userId, limit: 5)
        } catch {
            print("❌ Failed to load your content: \(error)")
        }
    }
    
    // Actions
    func vote(pollId: String, optionIndex: Int, userId: String) async {
        do {
            try await FirestoreService.shared.submitPollVote(pollId: pollId, optionIndex: optionIndex, userId: userId)
            // Refresh trending after vote
            await loadTrendingPolls()
            await loadLatest()
        } catch {
            print("Vote error: \(error)")
        }
    }
    
    func togglePollLike(pollId: String, userId: String) async {
        do {
            try await FirestoreService.shared.togglePollLike(pollId: pollId, userId: userId)
            // Refresh sections
            await loadTrendingPolls()
            await loadLatest()
        } catch {
            print("Poll like error: \(error)")
        }
    }
    
    func toggleQuestionLike(questionId: String, userId: String) async {
        do {
            try await FirestoreService.shared.toggleQuestionLike(questionId: questionId, userId: userId)
            // Refresh sections
            await loadHotDebates()
            await loadLatest()
        } catch {
            print("Question like error: \(error)")
        }
    }
    
    func deleteQuestion(questionId: String) async {
        do {
            try await FirestoreService.shared.deleteQuestion(questionId: questionId)
            // Refresh all sections
            await loadAllSections(userId: nil)
        } catch {
            print("Delete question error: \(error)")
        }
    }
}
