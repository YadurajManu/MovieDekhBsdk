import SwiftUI

struct MovieCommunitySection: View {
    let movieId: Int
    @StateObject private var viewModel: MovieSocialViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    
    @State private var selectedRating: String?
    @State private var selectedTags: Set<String> = []
    @State private var reviewContent: String = ""
    @State private var isExpandingSubmission = false
    
    init(movieId: Int) {
        self.movieId = movieId
        _viewModel = StateObject(wrappedValue: MovieSocialViewModel(movieId: movieId))
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CINEPHILE COMMUNITY")
                        .font(.system(size: 10, weight: .black))
                        .tracking(2)
                        .foregroundColor(.appPrimary)
                    Text("The Consensus")
                        .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 32))
                        .foregroundColor(.appText)
                }
                Spacer()
            }
            
            if viewModel.isLoading && viewModel.stats.totalVotes == 0 {
                ProgressView().tint(.appPrimary)
            } else {
                // Cine-Scale Distribution
                CineScaleRatingView(selectedRating: $selectedRating) { rating in
                    withAnimation { isExpandingSubmission = true }
                }
                
                if isExpandingSubmission {
                    VStack(spacing: 24) {
                        TagPicker(selectedTags: $selectedTags)
                        
                        TextField("Any specific gossip? (Optional)", text: $reviewContent, axis: .vertical)
                            .font(.system(size: 14))
                            .foregroundColor(.appText)
                            .padding()
                            .frame(minHeight: 100, alignment: .top)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        Button(action: {
                            guard let rating = selectedRating, let profile = appViewModel.userProfile else { return }
                            Task {
                                await viewModel.submitVote(
                                    rating: rating,
                                    genreTags: Array(selectedTags),
                                    review: reviewContent,
                                    user: profile
                                )
                                withAnimation {
                                    isExpandingSubmission = false
                                    selectedRating = nil
                                    selectedTags = []
                                    reviewContent = ""
                                }
                            }
                        }) {
                            if viewModel.isSubmitting {
                                ProgressView().tint(.black)
                            } else {
                                Text("SUBMIT TO CONSENSUS")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.appPrimary)
                        .cornerRadius(28)
                        .disabled(viewModel.isSubmitting)
                        
                        Button(action: { withAnimation { isExpandingSubmission = false } }) {
                            Text("Cancel")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Aggregate Stats
                GenrePulseView(consensus: viewModel.stats.genreConsensus, totalVotes: viewModel.stats.totalVotes)
                
                // Gossip Section
                MovieGossipView(
                    reviews: viewModel.reviews,
                    newReviewContent: $reviewContent,
                    onPost: {
                        guard let profile = appViewModel.userProfile else { return }
                        Task {
                            await viewModel.submitVote(
                                rating: selectedRating ?? "awaara", // Default if just commenting
                                genreTags: Array(selectedTags),
                                review: reviewContent,
                                user: profile
                            )
                            reviewContent = ""
                        }
                    }
                )
            }
        }
        .task {
            await viewModel.loadSocialData()
        }
    }
}
