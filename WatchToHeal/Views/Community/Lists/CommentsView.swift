import SwiftUI

struct CommentsView: View {
    let listId: String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var commentText: String = ""
    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var showCelebration = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ZStack {
                        if isLoading {
                            ProgressView().tint(.appPrimary).frame(maxHeight: .infinity)
                        } else if comments.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.1))
                                Text("No comments yet.\nStart the conversation!")
                                    .font(.system(size: 14))
                                    .foregroundColor(.appTextSecondary.opacity(0.6))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 24) {
                                    ForEach(comments) { comment in
                                        CommentRow(comment: comment) {
                                            deleteComment(comment)
                                        }
                                    }
                                }
                                .padding(24)
                            }
                        }
                        
                        if showCelebration {
                            LottieView(name: "congratulation") {
                                withAnimation { showCelebration = false }
                            }
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                        }
                    }
                    
                    // Comment Input
                    VStack(spacing: 0) {
                        Divider().background(Color.white.opacity(0.1))
                        
                        HStack(spacing: 16) {
                            if let url = appViewModel.userProfile?.photoURL {
                                CachedAsyncImage(url: url) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle().fill(Color.appCardBackground)
                                }
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                            }
                            
                            TextField("Wait, this list needs...", text: $commentText)
                                .font(.system(size: 15))
                                .foregroundColor(.appText)
                            
                            Button(action: postComment) {
                                Text("Post")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(commentText.isEmpty ? .appTextSecondary : .appPrimary)
                            }
                            .disabled(commentText.isEmpty)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color.appBackground)
                    }
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear(perform: loadComments)
        }
    }
    
    private func loadComments() {
        isLoading = true
        Task {
            do {
                comments = try await FirestoreService.shared.fetchComments(listId: listId)
            } catch {
                print("Failed to load comments: \(error)")
            }
            isLoading = false
        }
    }
    
    private func postComment() {
        guard let profile = appViewModel.userProfile else { return }
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let newComment = Comment(
            id: UUID().uuidString,
            userId: profile.id,
            userName: profile.name,
            userPhotoURL: profile.photoURL,
            text: text,
            createdAt: Date()
        )
        
        commentText = ""
        withAnimation {
            comments.insert(newComment, at: 0)
            showCelebration = true
        }
        
        Task {
            try? await FirestoreService.shared.addComment(listId: listId, comment: newComment)
        }
    }
    
    private func deleteComment(_ comment: Comment) {
        withAnimation {
            comments.removeAll { $0.id == comment.id }
        }
        
        Task {
            try? await FirestoreService.shared.deleteComment(listId: listId, commentId: comment.id)
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let onDelete: () -> Void
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let url = comment.userPhotoURL {
                CachedAsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.appCardBackground)
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                Circle().fill(Color.appCardBackground)
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.white.opacity(0.1)))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.userName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appText)
                    
                    Spacer()
                    
                    Text(comment.createdAt.timeAgoDisplay())
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary.opacity(0.6))
                }
                
                Text(comment.text)
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)
                    .lineSpacing(4)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            if comment.userId == appViewModel.userProfile?.id {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Comment", systemImage: "trash")
                }
            }
        }
    }
}

