import Foundation
import FirebaseFirestore
import Combine

@MainActor
class GlobalPollsViewModel: ObservableObject {
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
        listener = Firestore.firestore().collection("polls")
            .order(by: "createdAt", descending: true)
            .limit(to: 10)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    print("Error listening to polls: \(error)")
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
}
