import SwiftUI

struct PollCard: View {
    let poll: MoviePoll
    var onVote: (Int) -> Void
    @EnvironmentObject var appViewModel: AppViewModel
    
    private var hasVoted: Bool {
        guard let userId = appViewModel.userProfile?.id else { return false }
        return poll.votedUserIds.contains(userId)
    }
    
    private var isExpired: Bool {
        poll.isFinalized || (poll.expiresAt != nil && poll.expiresAt! < Date())
    }
    
    var body: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(isExpired ? .gray : .appPrimary)
                    
                    Text(isExpired ? "FINAL RESULTS" : "ACTIVE POLL")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1)
                        .foregroundColor(isExpired ? .appTextSecondary : .appPrimary)
                    
                    Spacer()
                    
                    Text("\(poll.totalVotes) VOTES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.appTextSecondary)
                }
                
                // Question
                Text(poll.question)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appText)
                    .lineSpacing(4)
                
                // Options
                VStack(spacing: 16) {
                    ForEach(0..<poll.options.count, id: \.self) { index in
                        if hasVoted || isExpired {
                            resultRow(index: index)
                        } else {
                            voteButton(index: index)
                        }
                    }
                }
                
                if isExpired {
                    Text("This poll has concluded. Thanks for participating!")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                } else if hasVoted {
                    Text("Thanks for being part of the pulse! ✨")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.appPrimary.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
            .padding(24)
        }
    }
    
    @ViewBuilder
    private func voteButton(index: Int) -> some View {
        let option = poll.options[index]
        Button(action: { 
            withAnimation(.spring()) {
                onVote(index)
            }
        }) {
            HStack(spacing: 16) {
                if poll.type == .movie, let poster = option.posterPath {
                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w92\(poster)")) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.white.opacity(0.1)
                    }
                    .frame(width: 40, height: 60)
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.text)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.appText)
                    if let secondary = option.secondaryInfo {
                        Text(secondary)
                            .font(.system(size: 10))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 64)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }
    
    @ViewBuilder
    private func resultRow(index: Int) -> some View {
        let option = poll.options[index]
        let percentage = poll.totalVotes > 0 ? Double(poll.votes[index]) / Double(poll.totalVotes) : 0
        let isWinner = isExpired && poll.votes[index] == poll.votes.max()
        
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                if poll.type == .movie, let poster = option.posterPath {
                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w92\(poster)")) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.white.opacity(0.1)
                    }
                    .frame(width: 30, height: 45)
                    .cornerRadius(4)
                    .opacity(isWinner ? 1 : 0.6)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(option.text)
                            .font(.system(size: 14, weight: isWinner ? .bold : .medium))
                            .foregroundColor(isWinner ? .appPrimary : .appText)
                        if isWinner {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.appPrimary)
                        }
                    }
                    
                    if let secondary = option.secondaryInfo {
                        Text(secondary)
                            .font(.system(size: 10))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                Spacer()
                
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isWinner ? .appPrimary : .appTextSecondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isWinner ? Color.appPrimary : Color.white.opacity(0.3))
                        .frame(width: geo.size.width * CGFloat(percentage), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }
}
