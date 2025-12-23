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
                
                if viewModel.isLoading && viewModel.polls.isEmpty && viewModel.questions.isEmpty {
                    VStack {
                        ProgressView().tint(.appPrimary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.polls.isEmpty && viewModel.questions.isEmpty {
                    emptyState
                } else {
                    feedContent
                }
            }
            .padding(.vertical, 16)
            .padding(.bottom, 60)
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
    
    private var feedContent: some View {
        LazyVStack(spacing: 24) {
            // Mixed Feed logic (sorted by date)
            let mixedItems: [PulseItem] = (
                viewModel.polls.map { .poll($0) } + 
                viewModel.questions.map { .question($0) }
            ).sorted { $0.createdAt > $1.createdAt }
            
            ForEach(mixedItems) { item in
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
        .padding(.horizontal, 24)
    }
}

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
