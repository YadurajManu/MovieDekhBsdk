import SwiftUI

struct MovieGossipView: View {
    @ObservedObject var viewModel: MovieSocialViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("COMMUNITY REVIEWS")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundColor(.appPrimary)
                
                Spacer()
                
                // Filters
                HStack(spacing: 8) {
                    // Sort Menu
                    Menu {
                        Button(action: { viewModel.sortOption = .mostRecent }) {
                            Label("Most Recent", systemImage: "clock")
                        }
                        Button(action: { viewModel.sortOption = .mostLiked }) {
                            Label("Most Liked", systemImage: "heart")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(viewModel.sortOption == .mostRecent ? "Recent" : "Popular")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                    }
                    
                    // Spoiler Filter
                    Button(action: { viewModel.showSpoilers.toggle() }) {
                        Text("Spoilers")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(viewModel.showSpoilers ? .red : .white.opacity(0.4))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(viewModel.showSpoilers ? Color.red.opacity(0.1) : Color.white.opacity(0.05))
                            .cornerRadius(6)
                    }
                }
            }
            
            // Reviews List
            let displayReviews = viewModel.filteredReviews
            if displayReviews.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.appPrimary.opacity(0.2))
                    Text("No reviews yet. Be the first to share your take!")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 16) {
                    ForEach(displayReviews) { review in
                        ReviewRow(review: review, viewModel: viewModel)
                    }
                }
            }
        }
    }
}

struct ReviewRow: View {
    let review: MovieReview
    @ObservedObject var viewModel: MovieSocialViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    
    @State private var isRevealed = false
    @State private var showReplies = false
    @State private var replies: [MovieReply] = []
    @State private var newReplyText = ""
    @State private var isReplying = false
    @State private var isLoadingReplies = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if let photoURL = review.userPhoto, let url = URL(string: photoURL) {
                    CachedAsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.appCardBackground)
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.appTextSecondary.opacity(0.3))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.username)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appText)
                    Text(review.timestamp, style: .relative)
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if review.isSpoiler {
                        Text("SPOILER")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    let color = colorForRating(review.rating)
                    Text(review.rating.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            ZStack {
                Text(review.content)
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)
                    .lineSpacing(4)
                    .blur(radius: (review.isSpoiler && !isRevealed) ? 12 : 0)
                
                if review.isSpoiler && !isRevealed {
                    Button(action: { withAnimation { isRevealed = true } }) {
                        Text("TAP TO REVEAL SPOILER")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(20)
                    }
                }
            }
            
            if !review.genreTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(review.genreTags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.appPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.appPrimary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .blur(radius: (review.isSpoiler && !isRevealed) ? 8 : 0)
            }
            
            // Social Actions
            HStack(spacing: 20) {
                // Like Button
                Button(action: {
                    guard let userId = appViewModel.userProfile?.id, let reviewId = review.id else { return }
                    Task { await viewModel.toggleLike(reviewId: reviewId, userId: userId) }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: review.likedBy.contains(appViewModel.userProfile?.id ?? "") ? "heart.fill" : "heart")
                            .foregroundColor(review.likedBy.contains(appViewModel.userProfile?.id ?? "") ? .red : .appTextSecondary)
                        Text("\(review.likesCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                // Reply Button
                Button(action: {
                    withAnimation {
                        if !showReplies {
                            loadReplies()
                        }
                        showReplies.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text("\(review.repliesCount)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
            }
            .padding(.top, 4)
            
            if showReplies {
                VStack(alignment: .leading, spacing: 12) {
                    if isLoadingReplies {
                        ProgressView().tint(.appPrimary).frame(maxWidth: .infinity)
                    } else {
                        ForEach(replies) { reply in
                            ReplyRow(reply: reply)
                        }
                        
                        // New Reply Input
                        HStack(spacing: 12) {
                            TextField("Write a reply...", text: $newReplyText)
                                .font(.system(size: 13))
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                            
                            Button(action: postReply) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(newReplyText.isEmpty ? .appTextSecondary : .appPrimary)
                            }
                            .disabled(newReplyText.isEmpty || isReplying)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.leading, 12)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(review.isSpoiler ? Color.red.opacity(0.2) : Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func loadReplies() {
        guard let reviewId = review.id else { return }
        isLoadingReplies = true
        Task {
            let fetched = await viewModel.fetchReplies(reviewId: reviewId)
            await MainActor.run {
                self.replies = fetched
                self.isLoadingReplies = false
            }
        }
    }
    
    private func postReply() {
        guard let reviewId = review.id, let user = appViewModel.userProfile else { return }
        isReplying = true
        Task {
            await viewModel.postReply(reviewId: reviewId, content: newReplyText, user: user)
            newReplyText = ""
            isReplying = false
            loadReplies()
        }
    }
    
    private func colorForRating(_ rating: String) -> Color {
        switch rating {
        case "absolute": return .orange
        case "awaara": return .blue
        case "bakwas": return .red
        default: return .appTextSecondary
        }
    }
}

struct ReplyRow: View {
    let reply: MovieReply
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let photoURL = reply.userPhoto, let url = URL(string: photoURL) {
                CachedAsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.appCardBackground)
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.appTextSecondary.opacity(0.3))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reply.username)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.appText)
                    Text(reply.timestamp, style: .relative)
                        .font(.system(size: 8))
                        .foregroundColor(.appTextSecondary)
                }
                
                Text(reply.content)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, 4)
    }
}
