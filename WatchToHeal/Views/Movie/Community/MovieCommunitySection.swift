import SwiftUI

struct MovieCommunitySection: View {
    let movieId: Int
    let movieTitle: String
    let moviePoster: String?
    @StateObject private var viewModel: MovieSocialViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    
    @State private var selectedRating: String?
    @State private var selectedTags: Set<String> = []
    @State private var reviewContent: String = ""
    @State private var isSpoiler = false
    @State private var isExpandingSubmission = false
    @State private var showSuccessMessage = false
    
    init(movieId: Int, movieTitle: String, moviePoster: String?) {
        self.movieId = movieId
        self.movieTitle = movieTitle
        self.moviePoster = moviePoster
        _viewModel = StateObject(wrappedValue: MovieSocialViewModel(movieId: movieId, movieTitle: movieTitle, moviePoster: moviePoster))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("YOUR TAKE")
                        .font(.system(size: 14, weight: .black))
                        .kerning(2)
                        .foregroundColor(.appPrimary)
                    Text("Share your reaction with the community")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                }
                Spacer()
            }
            
            if showSuccessMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appPrimary)
                        .font(.system(size: 14))
                    Text("CONSENSUS UPDATED")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.appPrimary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color.appPrimary.opacity(0.1))
                .cornerRadius(12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            if viewModel.isLoading && viewModel.stats.totalVotes == 0 {
                ProgressView().tint(.appPrimary)
            } else {
                let hasRated = viewModel.reviews.contains { $0.userId == appViewModel.userProfile?.id }
                
                if !hasRated {
                    // Cine-Scale Distribution
                    CineScaleRatingView(selectedRating: $selectedRating) { rating in
                        withAnimation { isExpandingSubmission = true }
                    }
                } else if !showSuccessMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.appPrimary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("YOU'VE LOGGED THIS MOVIE")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.appText)
                            Text("Your reaction is part of the pulse")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.04), lineWidth: 1))
                }
                
                if isExpandingSubmission {
                    VStack(spacing: 20) {
                        TagPicker(selectedTags: $selectedTags, selectedRating: selectedRating)
                            .onChange(of: selectedRating) { _ in
                                selectedTags.removeAll()
                            }
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack {
                                Toggle(isOn: $isSpoiler) {
                                    Text("CONTAINS SPOILERS")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(isSpoiler ? .red : .white.opacity(0.4))
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .red))
                                Spacer()
                            }
                            
                            TextField("Say why (optional)", text: $reviewContent, axis: .vertical)
                                .font(.system(size: 13))
                                .foregroundColor(.appText)
                                .padding(12)
                                .frame(minHeight: 50, alignment: .top)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1))
                                .submitLabel(.done)
                                .onSubmit {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            
                            Text("\(reviewContent.count)/200")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(reviewContent.count > 200 ? .red : .white.opacity(0.3))
                        }
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                guard let rating = selectedRating, let profile = appViewModel.userProfile else { return }
                                if reviewContent.count > 200 { return }
                                
                                Task {
                                    await viewModel.submitVote(
                                        rating: rating,
                                        genreTags: Array(selectedTags),
                                        review: reviewContent,
                                        isSpoiler: isSpoiler,
                                        user: profile
                                    )
                                    withAnimation {
                                        isExpandingSubmission = false
                                        selectedRating = nil
                                        selectedTags = []
                                        reviewContent = ""
                                        isSpoiler = false
                                        showSuccessMessage = true
                                    }
                                    
                                    // Auto-hide success message
                                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                                    withAnimation { showSuccessMessage = false }
                                }
                            }) {
                                if viewModel.isSubmitting {
                                    ProgressView().tint(.black)
                                } else {
                                    Text("SUBMIT SCORE")
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundColor(.black)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(selectedRating == nil ? Color.white.opacity(0.1) : Color.appPrimary)
                            .cornerRadius(25)
                            .disabled(viewModel.isSubmitting || selectedRating == nil)
                            
                            if !isExpandingSubmission { // This is just for context, but let's show after submit logic
                                // We'll handle the "Added to community score" after the submit finishes
                            }
                        }
                        
                        Button(action: { 
                            withAnimation { 
                                isExpandingSubmission = false 
                                selectedRating = nil
                            } 
                        }) {
                            Text("Cancel")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Aggregate Stats
                GenrePulseView(consensus: viewModel.stats.genreConsensus, totalVotes: viewModel.stats.totalVotes)
                
                // Gossip Section
                MovieGossipView(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadSocialData()
        }
    }
}
