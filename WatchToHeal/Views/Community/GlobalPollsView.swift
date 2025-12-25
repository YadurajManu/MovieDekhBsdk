import SwiftUI

struct PulseView: View {
    @StateObject private var viewModel = PulseViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showCreatePoll = false
    @State private var showCreateQuestion = false
    @State private var selectedQuestion: CommunityQuestion?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Intro Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("PULSE")
                        .font(.system(size: 10, weight: .black))
                        .tracking(3)
                        .foregroundColor(.appPrimary)
                    
                    Text("Cinematic debates and community picks.")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                
                if viewModel.isLoading {
                    VStack {
                        ProgressView().tint(.appPrimary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.trendingPolls.isEmpty && viewModel.hotDebates.isEmpty && viewModel.latestContent.isEmpty {
                    emptyState
                } else {
                    sectionsContent
                }
            }
            .padding(.vertical, 16)
            .padding(.bottom, 60)
        }
        .refreshable {
            await viewModel.loadAllSections(userId: appViewModel.userProfile?.id)
        }
        .sheet(item: $selectedQuestion) { question in
            QuestionDetailView(question: question)
        }
        .fullScreenCover(isPresented: $showCreatePoll) {
            CreatePollView()
        }
        .fullScreenCover(isPresented: $showCreateQuestion) {
            CreateQuestionView()
        }
    }
    
    private var sectionsContent: some View {
        VStack(alignment: .leading, spacing: 40) {
            // 🔥 Trending Polls
            if !viewModel.trendingPolls.isEmpty {
                FeedSection(title: "🔥 Trending Polls", subtitle: "Hottest in last 48h") {
                    ForEach(viewModel.trendingPolls) { poll in
                        PollCard(
                            poll: poll,
                            onVote: { index in
                                if let userId = appViewModel.userProfile?.id {
                                    Task { await viewModel.vote(pollId: poll.id ?? "", optionIndex: index, userId: userId) }
                                }
                            },
                            onLike: {
                                if let userId = appViewModel.userProfile?.id {
                                    Task { await viewModel.togglePollLike(pollId: poll.id ?? "", userId: userId) }
                                }
                            }
                        )
                    }
                }
            }
            
            // 💬 Hot Debates
            if !viewModel.hotDebates.isEmpty {
                FeedSection(title: "💬 Hot Debates", subtitle: "Most active discussions") {
                    ForEach(viewModel.hotDebates) { question in
                        QuestionCard(
                            question: question,
                            onLike: {
                                if let userId = appViewModel.userProfile?.id {
                                    Task { await viewModel.toggleQuestionLike(questionId: question.id ?? "", userId: userId) }
                                }
                            },
                            onTap: {
                                selectedQuestion = question
                            }
                        )
                    }
                }
            }
            
            // ✨ Latest
            if !viewModel.latestContent.isEmpty {
                FeedSection(title: "✨ Latest", subtitle: "Fresh from the community") {
                    ForEach(viewModel.latestContent) { item in
                        switch item {
                        case .poll(let poll):
                            PollCard(
                                poll: poll,
                                onVote: { index in
                                    if let userId = appViewModel.userProfile?.id {
                                        Task { await viewModel.vote(pollId: poll.id ?? "", optionIndex: index, userId: userId) }
                                    }
                                },
                                onLike: {
                                    if let userId = appViewModel.userProfile?.id {
                                        Task { await viewModel.togglePollLike(pollId: poll.id ?? "", userId: userId) }
                                    }
                                }
                            )
                        case .question(let question):
                            QuestionCard(
                                question: question,
                                onLike: {
                                    if let userId = appViewModel.userProfile?.id {
                                        Task { await viewModel.toggleQuestionLike(questionId: question.id ?? "", userId: userId) }
                                    }
                                },
                                onTap: {
                                    selectedQuestion = question
                                }
                            )
                        }
                    }
                }
            }
            
            // 👑 Top Contributors
            if !viewModel.topContributors.isEmpty {
                TopContributorsSection(contributors: viewModel.topContributors)
            }
            
            // 🎬 By You
            if !viewModel.yourContent.isEmpty {
                FeedSection(title: "🎬 By You", subtitle: "Your contributions") {
                    ForEach(viewModel.yourContent) { item in
                        switch item {
                        case .poll(let poll):
                            PollCard(
                                poll: poll,
                                onVote: { index in
                                    if let userId = appViewModel.userProfile?.id {
                                        Task { await viewModel.vote(pollId: poll.id ?? "", optionIndex: index, userId: userId) }
                                    }
                                },
                                onLike: {
                                    if let userId = appViewModel.userProfile?.id {
                                        Task { await viewModel.togglePollLike(pollId: poll.id ?? "", userId: userId) }
                                    }
                                }
                            )
                        case .question(let question):
                            QuestionCard(
                                question: question,
                                onLike: {
                                    if let userId = appViewModel.userProfile?.id {
                                        Task { await viewModel.toggleQuestionLike(questionId: question.id ?? "", userId: userId) }
                                    }
                                },
                                onTap: {
                                    selectedQuestion = question
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.1))
            Text("The pulse is quiet.\nStart a debate or poll!")
                .font(.system(size: 15))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button(action: { showCreatePoll = true }) {
                    Text("POLL")
                        .font(.system(size: 13, weight: .black))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.appPrimary)
                        .foregroundColor(.black)
                        .cornerRadius(20)
                }
                
                Button(action: { showCreateQuestion = true }) {
                    Text("DEBATE")
                        .font(.system(size: 13, weight: .black))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
}

// MARK: - Feed Section Component
struct FeedSection<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content
    
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.appText)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 16) {
                content
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Top Contributors Section
struct TopContributorsSection: View {
    let contributors: [ContributorProfile]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("👑 Top Contributors")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.appText)
                Text("This week's most engaging creators")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(Array(contributors.enumerated()), id: \.element.id) { index, contributor in
                    HStack(spacing: 12) {
                        // Rank badge
                        ZStack {
                            Circle()
                                .fill(rankColor(index))
                                .frame(width: 32, height: 32)
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.black)
                        }
                        
                        // Profile photo
                        if let photoURL = contributor.photoURL, let url = URL(string: photoURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle().fill(Color.white.opacity(0.1))
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 40, height: 40)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(contributor.username)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.appText)
                            Text("\(contributor.postCount) posts • \(Int(contributor.totalEngagement)) engagement")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.appTextSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return Color.appPrimary // Gold
        case 1: return Color.gray.opacity(0.6) // Silver
        case 2: return Color.orange.opacity(0.5) // Bronze
        default: return Color.white.opacity(0.2)
        }
    }
}

// MARK: - Pulse Item Enum
enum PulseItem: Identifiable {
    case poll(MoviePoll)
    case question(CommunityQuestion)
    
    var id: String {
        switch self {
        case .poll(let poll): return "poll_\(poll.id ?? "")"
        case .question(let question): return "question_\(question.id ?? "")"
        }
    }
    
    var createdAt: Date {
        switch self {
        case .poll(let poll): return poll.createdAt
        case .question(let question): return question.createdAt
        }
    }
}
