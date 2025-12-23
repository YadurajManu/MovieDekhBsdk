import SwiftUI
import FirebaseFirestore
import Combine

struct QuestionDetailView: View {
    let question: CommunityQuestion
    @StateObject private var viewModel: QuestionDetailViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    init(question: CommunityQuestion) {
        self.question = question
        self._viewModel = StateObject(wrappedValue: QuestionDetailViewModel(questionId: question.id ?? ""))
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Original Question
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                if let photo = question.creatorPhotoURL, let url = URL(string: photo) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.white.opacity(0.1)
                                    }
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(question.creatorUsername)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.appText)
                                    Text(question.createdAt, style: .date)
                                        .font(.system(size: 11))
                                        .foregroundColor(.appTextSecondary)
                                }
                                Spacer()
                                
                                if question.creatorId == appViewModel.userProfile?.id {
                                    Button(action: {
                                        Task {
                                            await viewModel.deleteQuestion()
                                            dismiss()
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red.opacity(0.6))
                                    }
                                }
                            }
                            
                            Text(question.text)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.appText)
                                .lineSpacing(6)
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    if let userId = appViewModel.userProfile?.id {
                                        Task { await viewModel.toggleQuestionLike(userId: userId) }
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: viewModel.isQuestionLiked(userId: appViewModel.userProfile?.id ?? "") ? "heart.fill" : "heart")
                                            .foregroundColor(viewModel.isQuestionLiked(userId: appViewModel.userProfile?.id ?? "") ? .red : .appTextSecondary)
                                        Text("\(viewModel.questionLikeCount)")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                .foregroundColor(.appTextSecondary)
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "bubble.left.fill")
                                    Text("\(viewModel.replies.count) REPLIES")
                                        .font(.system(size: 12, weight: .black))
                                }
                                .foregroundColor(.appPrimary)
                            }
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(24)
                        
                        Divider().background(Color.white.opacity(0.05))
                        
                        // Replies
                        if viewModel.isLoading {
                            ProgressView().tint(.appPrimary).frame(maxWidth: .infinity).padding()
                        } else {
                            LazyVStack(spacing: 20) {
                                ForEach(viewModel.replies) { reply in
                                    CommunityReplyRow(reply: reply, 
                                            onLike: {
                                                if let userId = appViewModel.userProfile?.id {
                                                    Task { await viewModel.toggleReplyLike(replyId: reply.id ?? "", userId: userId) }
                                                }
                                            },
                                            onDelete: {
                                                Task { await viewModel.deleteReply(replyId: reply.id ?? "") }
                                            },
                                            isOwner: reply.userId == appViewModel.userProfile?.id)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.bottom, 100)
                }
                
                replyInput
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.appTextSecondary)
            }
            Spacer()
            Text("CINE-DEBATE")
                .font(.system(size: 12, weight: .black))
                .tracking(3)
                .foregroundColor(.appText)
            Spacer()
            Button(action: {}) { Image(systemName: "chevron.left").opacity(0) }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    private var replyInput: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.1))
            HStack(spacing: 12) {
                TextField("Add to the debate...", text: $viewModel.replyText)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(25)
                    .foregroundColor(.appText)
                
                Button(action: {
                    if let profile = appViewModel.userProfile {
                        Task { await viewModel.postReply(profile: profile) }
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.replyText.isEmpty ? .gray : .appPrimary)
                }
                .disabled(viewModel.replyText.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.appBackground)
        }
    }
}

struct CommunityReplyRow: View {
    let reply: CommunityReply
    var onLike: () -> Void
    var onDelete: () -> Void
    let isOwner: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let photo = reply.userPhotoURL, let url = URL(string: photo) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.white.opacity(0.1)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(reply.userUsername)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.appPrimary)
                    Spacer()
                    Text(reply.createdAt, style: .relative)
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                    
                    if isOwner {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundColor(.red.opacity(0.5))
                        }
                    }
                }
                
                Text(reply.text)
                    .font(.system(size: 14))
                    .foregroundColor(.appText)
                    .lineSpacing(4)
                
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.system(size: 12))
                        Text("\(reply.likeCount)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.appTextSecondary)
                }
                .padding(.top, 2)
            }
        }
    }
}

@MainActor
class QuestionDetailViewModel: ObservableObject {
    let questionId: String
    @Published var replies: [CommunityReply] = []
    @Published var isLoading = true
    @Published var replyText = ""
    @Published var questionLikeCount = 0
    @Published var likedUserIds: [String] = []
    
    private var replyListener: ListenerRegistration?
    private var questionListener: ListenerRegistration?
    
    init(questionId: String) {
        self.questionId = questionId
        startListening()
    }
    
    deinit {
        replyListener?.remove()
        questionListener?.remove()
    }
    
    func startListening() {
        isLoading = true
        
        // Listen to question for likes/updates
        questionListener = Firestore.firestore().collection("communityQuestions").document(questionId)
            .addSnapshotListener { snapshot, _ in
                if let data = snapshot?.data() {
                    self.questionLikeCount = data["likeCount"] as? Int ?? 0
                    self.likedUserIds = data["likedUserIds"] as? [String] ?? []
                }
            }
            
        // Listen to replies
        replyListener = Firestore.firestore().collection("communityQuestions").document(questionId)
            .collection("replies")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                self.replies = snapshot?.documents.compactMap { try? $0.data(as: CommunityReply.self) } ?? []
                self.isLoading = false
            }
    }
    
    func isQuestionLiked(userId: String) -> Bool {
        likedUserIds.contains(userId)
    }
    
    func toggleQuestionLike(userId: String) async {
        try? await FirestoreService.shared.toggleQuestionLike(questionId: questionId, userId: userId)
    }
    
    func deleteQuestion() async {
        try? await FirestoreService.shared.deleteQuestion(questionId: questionId)
    }
    
    func postReply(profile: UserProfile) async {
        let reply = CommunityReply(
            text: replyText,
            userId: profile.id,
            userName: profile.name,
            userUsername: profile.username ?? profile.name,
            userPhotoURL: profile.photoURL?.absoluteString,
            createdAt: Date()
        )
        
        do {
            try await FirestoreService.shared.addReply(questionId: questionId, reply: reply)
            replyText = ""
        } catch {
            print("Error posting reply: \(error)")
        }
    }
    
    func toggleReplyLike(replyId: String, userId: String) async {
        try? await FirestoreService.shared.toggleReplyLike(questionId: questionId, replyId: replyId, userId: userId)
    }
    
    func deleteReply(replyId: String) async {
        try? await FirestoreService.shared.deleteReply(questionId: questionId, replyId: replyId)
    }
}
