import Foundation
import FirebaseFirestore
import Combine

@MainActor
class PulseViewModel: ObservableObject {
    @Published var polls: [MoviePoll] = []
    @Published var questions: [CommunityQuestion] = []
    @Published var isLoading = true
    
    private var pollListener: ListenerRegistration?
    private var questionListener: ListenerRegistration?
    
    init() {
        startListening()
    }
    
    deinit {
        pollListener?.remove()
        questionListener?.remove()
    }
    
    func startListening() {
        isLoading = true
        
        // Listen to Polls
        pollListener = Firestore.firestore().collection("polls")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Polls listener error: \(error)")
                    return
                }
                self.polls = snapshot?.documents.compactMap { try? $0.data(as: MoviePoll.self) } ?? []
                self.checkLoading()
            }
            
        // Listen to Questions
        questionListener = Firestore.firestore().collection("communityQuestions")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Questions listener error: \(error)")
                    return
                }
                self.questions = snapshot?.documents.compactMap { try? $0.data(as: CommunityQuestion.self) } ?? []
                self.checkLoading()
            }
    }
    
    private func checkLoading() {
        // Simple loading check
        self.isLoading = false
    }
    
    // Actions
    func vote(pollId: String, optionIndex: Int, userId: String) async {
        do {
            try await FirestoreService.shared.submitPollVote(pollId: pollId, optionIndex: optionIndex, userId: userId)
        } catch {
            print("Vote error: \(error)")
        }
    }
    
    func togglePollLike(pollId: String, userId: String) async {
        do {
            try await FirestoreService.shared.togglePollLike(pollId: pollId, userId: userId)
        } catch {
            print("Poll like error: \(error)")
        }
    }
    
    func toggleQuestionLike(questionId: String, userId: String) async {
        do {
            try await FirestoreService.shared.toggleQuestionLike(questionId: questionId, userId: userId)
        } catch {
            print("Question like error: \(error)")
        }
    }
    
    func deleteQuestion(questionId: String) async {
        do {
            try await FirestoreService.shared.deleteQuestion(questionId: questionId)
        } catch {
            print("Delete question error: \(error)")
        }
    }
}
