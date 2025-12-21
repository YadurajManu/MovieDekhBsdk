import SwiftUI

struct GlobalPollsView: View {
    @StateObject private var viewModel = GlobalPollsViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Intro Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("GLOBAL PULSE")
                        .font(.system(size: 10, weight: .black))
                        .tracking(3)
                        .foregroundColor(.appPrimary)
                    
                    Text("The world of cinema, decided by you.")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                
                if viewModel.isLoading && viewModel.polls.isEmpty {
                    VStack {
                        ProgressView().tint(.appPrimary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.polls.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.1))
                        Text("No active polls right now.\nCheck back later!")
                            .font(.system(size: 15))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    LazyVStack(spacing: 24) {
                        ForEach(viewModel.polls) { poll in
                            PollCard(poll: poll) { optionIndex in
                                if let userId = appViewModel.userProfile?.id {
                                    Task {
                                        await viewModel.vote(pollId: poll.id ?? "", optionIndex: optionIndex, userId: userId)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, 16)
            .padding(.bottom, 60)
        }
        .refreshable {
            // Firestore listener handles updates, but we can re-trigger if desired
        }
    }
}
