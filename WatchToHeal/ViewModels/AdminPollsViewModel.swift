import Foundation
import FirebaseFirestore
import Combine

@MainActor
class AdminPollsViewModel: ObservableObject {
    @Published var activePolls: [MoviePoll] = []
    @Published var passedPolls: [MoviePoll] = []
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
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    print("Admin listener error: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                let allPolls = documents.compactMap { try? $0.data(as: MoviePoll.self) }
                
                let now = Date()
                self.activePolls = allPolls.filter { poll in
                    if poll.isFinalized { return false }
                    if let expires = poll.expiresAt, expires < now { return false }
                    return true
                }
                
                self.passedPolls = allPolls.filter { poll in
                    if poll.isFinalized { return true }
                    if let expires = poll.expiresAt, expires < now { return true }
                    return false
                }
            }
    }
    
    func finalizePoll(_ pollId: String) async {
        do {
            try await Firestore.firestore().collection("polls").document(pollId).updateData([
                "isFinalized": true
            ])
        } catch {
            print("Finalize error: \(error)")
        }
    }
    
    func deletePoll(_ pollId: String) async {
        do {
            try await Firestore.firestore().collection("polls").document(pollId).delete()
        } catch {
            print("Delete error: \(error)")
        }
    }
}
