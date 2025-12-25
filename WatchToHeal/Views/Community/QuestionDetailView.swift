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
            
            // Suggestions Overlay
            if !viewModel.suggestedUsers.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.suggestedUsers) { user in
                            Button(action: {
                                viewModel.selectMention(user: user)
                            }) {
                                HStack(spacing: 12) {
                                    if let photo = user.photoURL {
                                        AsyncImage(url: photo) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.gray
                                        }
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.gray)
                                            .frame(width: 32, height: 32)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(user.username ?? user.name)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.appText)
                                        if user.username != nil {
                                            Text(user.name)
                                                .font(.system(size: 12))
                                                .foregroundColor(.appTextSecondary)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            Divider().background(Color.white.opacity(0.1))
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color.appBackground)
                .cornerRadius(12)
                .shadow(radius: 10)
                .padding(.horizontal, 16)
                .transition(.opacity)
            }
            
            HStack(spacing: 12) {
                TextField("Add to the debate...", text: $viewModel.replyText)
                    .onChange(of: viewModel.replyText) { _, newValue in
                        viewModel.checkForMentions(text: newValue)
                    }
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
                Text(parsedText(from: reply.text))
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .textSelection(.enabled)
                
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

    private func parsedText(from text: String) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.foregroundColor = .appText
        
        do {
            let pattern = /@\w+/
            for match in text.matches(of: pattern) {
                if let range = attributed.range(of: match.output) {
                    attributed[range].foregroundColor = .appPrimary
                    attributed[range].font = .system(size: 14, weight: .bold)
                }
            }
        } catch {
            print("Regex error: \(error)")
        }
        
        return attributed
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
    @Published var suggestedUsers: [UserProfile] = []
    
    private var mentionTask: Task<Void, Never>?
    
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
        
        guard !questionId.isEmpty else {
            print("⚠️ QuestionDetailViewModel: questionId is empty, skipping listeners")
            isLoading = false
            return
        }
        
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
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                self.replies = snapshot?.documents.compactMap { try? $0.data(as: CommunityReply.self) } ?? []
                self.isLoading = false
            }
    }
    
    func isQuestionLiked(userId: String) -> Bool {
        likedUserIds.contains(userId)
    }
    
    func toggleQuestionLike(userId: String) async {
        guard !questionId.isEmpty else { return }
        try? await FirestoreService.shared.toggleQuestionLike(questionId: questionId, userId: userId)
    }
    
    func deleteQuestion() async {
        guard !questionId.isEmpty else { return }
        try? await FirestoreService.shared.deleteQuestion(questionId: questionId)
    }
    
    func postReply(profile: UserProfile) async {
        guard !questionId.isEmpty else { return }
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
        guard !questionId.isEmpty else { return }
        try? await FirestoreService.shared.toggleReplyLike(questionId: questionId, replyId: replyId, userId: userId)
    }
    
    func deleteReply(replyId: String) async {
        guard !questionId.isEmpty else { return }
        try? await FirestoreService.shared.deleteReply(questionId: questionId, replyId: replyId)
    }
    
    func checkForMentions(text: String) {
        mentionTask?.cancel()
        suggestedUsers = []
        
        guard let lastWord = text.split(separator: " ").last,
              lastWord.hasPrefix("@") else {
            return
        }
        
        let query = String(lastWord.dropFirst())
        guard !query.isEmpty else { return }
        
        mentionTask = Task {
            do {
                // Determine if this is a newly started query or continuation
                // Small delay to debounce typing
                try await Task.sleep(nanoseconds: 300_000_000) 
                
                let users = try await FirestoreService.shared.searchUsers(query: query)
                await MainActor.run {
                    self.suggestedUsers = users
                }
            } catch {
                print("Error searching users: \(error)")
            }
        }
    }
    
    func selectMention(user: UserProfile) {
        // Robust replacement: find the last occurrence of "@" and replace up to the end
        guard let range = replyText.range(of: "@", options: .backwards) else { return }
        
        let prefix = replyText[..<range.lowerBound]
        // We replace everything after the last '@' with the new mention + space
        replyText = String(prefix) + "@" + (user.username ?? user.name) + " "
        suggestedUsers = []
    }
}
