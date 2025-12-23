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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: User Info + Rating Badge
            HStack(spacing: 12) {
                if let photoURL = review.userPhoto, let url = URL(string: photoURL) {
                    CachedAsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.appCardBackground)
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.appTextSecondary.opacity(0.2))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.username)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appText)
                    Text(review.timestamp, style: .relative)
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary.opacity(0.6))
                }
                
                Spacer()
                
                // Rating Badge
                let color = colorForRating(review.rating)
                Text(labelForRating(review.rating))
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.12))
                    .cornerRadius(6)
            }
            
            // Content with Spoiler handling
            ZStack(alignment: .leading) {
                Text(review.content)
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)
                    .lineSpacing(4)
                    .blur(radius: (review.isSpoiler && !isRevealed) ? 12 : 0)
                
                if review.isSpoiler && !isRevealed {
                    Button(action: { withAnimation(.spring()) { isRevealed = true } }) {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.slash.fill")
                            Text("SPOILER CONTENT")
                        }
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            // Tags
            if !review.genreTags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(review.genreTags, id: \.self) { tag in
                        Text(tag.uppercased())
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(.appPrimary.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.appPrimary.opacity(0.08))
                            .cornerRadius(4)
                    }
                }
                .blur(radius: (review.isSpoiler && !isRevealed) ? 8 : 0)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.025))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(review.isSpoiler ? Color.red.opacity(0.15) : Color.white.opacity(0.03), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .contextMenu {
            if review.userId == appViewModel.userProfile?.id {
                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteReview(userId: review.userId)
                    }
                } label: {
                    Label("Delete Review", systemImage: "trash")
                }
            }
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
    
    private func labelForRating(_ rating: String) -> String {
        switch rating {
        case "absolute": return "GOFORIT"
        case "awaara": return "SOSO"
        case "bakwas": return "BAKWAS"
        default: return rating.uppercased()
        }
    }
}

struct ReplyRow: View {
    let reply: MovieReply
    let onDelete: () -> Void
    @EnvironmentObject var appViewModel: AppViewModel
    
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
        .contentShape(Rectangle())
        .contextMenu {
            if reply.userId == appViewModel.userProfile?.id {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Reply", systemImage: "trash")
                }
            }
        }
    }
}
