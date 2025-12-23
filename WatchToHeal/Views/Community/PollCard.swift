import SwiftUI

struct PollCard: View {
    let poll: MoviePoll
    var onVote: (Int) -> Void
    var onLike: () -> Void
    @EnvironmentObject var appViewModel: AppViewModel
    
    private var hasVoted: Bool {
        guard let userId = appViewModel.userProfile?.id else { return false }
        return poll.votedUserIds.contains(userId)
    }
    
    private var isExpired: Bool {
        poll.isFinalized || (poll.expiresAt != nil && poll.expiresAt! < Date())
    }
    
    private var isLiked: Bool {
        guard let userId = appViewModel.userProfile?.id else { return false }
        return poll.likedUserIds.contains(userId)
    }
    
    var body: some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 14) {
                // Identity
                HStack(spacing: 10) {
                    if let photo = poll.creatorPhotoURL, let url = URL(string: photo) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.white.opacity(0.1)
                        }
                        .frame(width: 26, height: 26)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.appPrimary.opacity(0.2))
                            .frame(width: 26, height: 26)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.appPrimary)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(poll.creatorUsername ?? "Curator")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appText)
                        
                        Text(poll.category ?? (poll.creatorId == nil ? "OFFICIAL" : "COMMUNITY"))
                            .font(.system(size: 9, weight: .black))
                            .tracking(0.5)
                            .foregroundColor(poll.creatorId == nil ? .appPrimary : .appTextSecondary)
                    }
                    
                    Spacer()
                    
                    if isExpired {
                        Text("CLOSED")
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                // Question
                Text(poll.question)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appText)
                    .lineSpacing(2)
                
                // Options
                VStack(spacing: 10) {
                    ForEach(0..<poll.options.count, id: \.self) { index in
                        if hasVoted || isExpired {
                            resultRow(index: index)
                        } else {
                            voteButton(index: index)
                        }
                    }
                }
                
                // Footer Interactions
                HStack(spacing: 20) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onLike()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 13))
                                .foregroundColor(isLiked ? .red : .appTextSecondary)
                            Text("\(poll.likedUserIds.count)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                    
                    HStack(spacing: 5) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.appTextSecondary)
                        Text("\(poll.totalVotes)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(16)
        }
    }
    
    @ViewBuilder
    private func voteButton(index: Int) -> some View {
        let option = poll.options[index]
        Button(action: { 
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring()) {
                onVote(index)
            }
        }) {
            HStack(spacing: 12) {
                if poll.type == .movie, let poster = option.posterPath {
                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w92\(poster)")) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.white.opacity(0.1)
                    }
                    .frame(width: 32, height: 48)
                    .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(option.text)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appText)
                        .lineLimit(1)
                    if let secondary = option.secondaryInfo {
                        Text(secondary)
                            .font(.system(size: 9))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 54)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }
    
    @ViewBuilder
    private func resultRow(index: Int) -> some View {
        let option = poll.options[index]
        let percentage = poll.totalVotes > 0 ? Double(poll.votes[index]) / Double(poll.totalVotes) : 0
        let isWinner = isExpired && poll.votes[index] == poll.votes.max()
        
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                if poll.type == .movie, let poster = option.posterPath {
                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w92\(poster)")) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.white.opacity(0.1)
                    }
                    .frame(width: 24, height: 36)
                    .cornerRadius(4)
                    .opacity(isWinner ? 1 : 0.6)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(option.text)
                            .font(.system(size: 13, weight: isWinner ? .bold : .medium))
                            .foregroundColor(isWinner ? .appPrimary : .appText)
                            .lineLimit(1)
                        if isWinner {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.appPrimary)
                        }
                    }
                    
                    if let secondary = option.secondaryInfo {
                        Text(secondary)
                            .font(.system(size: 9))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                Spacer()
                
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isWinner ? .appPrimary : .appTextSecondary)
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(isWinner ? Color.appPrimary : Color.white.opacity(0.2))
                    .frame(width: (UIScreen.main.bounds.width - 64) * CGFloat(percentage), height: 6)
            }
        }
        .padding(.vertical, 2)
    }
}
