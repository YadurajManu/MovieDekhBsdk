import Foundation
import FirebaseFirestore
import Combine

@MainActor
class CommunityPollsViewModel: ObservableObject {
    @Published var polls: [MoviePoll] = []
    @Published var isLoading = true
    
    private var listener: ListenerRegistration?
    
    init() {
        startListening()
    }
    
    deinit {
        listener?.remove()
    }
    
    func startListening() {
        isLoading = true
        // Listen to all polls, sorted by newest
        listener = Firestore.firestore().collection("polls")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    print("Error listening to community polls: \(error)")
                    return
                }
                
                self.polls = snapshot?.documents.compactMap { try? $0.data(as: MoviePoll.self) } ?? []
            }
    }
    
    func vote(pollId: String, optionIndex: Int, userId: String) async {
        do {
            try await FirestoreService.shared.submitPollVote(pollId: pollId, optionIndex: optionIndex, userId: userId)
        } catch {
            print("Vote error: \(error)")
        }
    }
    
    func toggleLike(pollId: String, userId: String) async {
        do {
            try await FirestoreService.shared.togglePollLike(pollId: pollId, userId: userId)
        } catch {
            print("Like error: \(error)")
        }
    }
    
    func deletePoll(pollId: String) async {
        do {
            try await Firestore.firestore().collection("polls").document(pollId).delete()
        } catch {
            print("Delete error: \(error)")
        }
    }
}
