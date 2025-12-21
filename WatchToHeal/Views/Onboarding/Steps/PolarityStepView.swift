import SwiftUI

struct PolarityStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            // Visual Anchor
            LinearGradient(
                stops: [
                    .init(color: .appPrimary.opacity(0.1), location: 0),
                    .init(color: .clear, location: 0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .frame(height: 300)
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("WHICH OF THESE DID YOU LIKE?")
                        .font(.system(size: 14, weight: .black))
                        .kerning(2)
                        .foregroundColor(.appPrimary)
                    
                    Text("Your reactions help us understand your specific genre and tone preferences.")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 24)
                .padding(.bottom, 24)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(.appPrimary)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(viewModel.polarityMovies) { movie in
                                let currentSentiment = viewModel.movieSentiments[movie.id] ?? .unseen
                                
                                HStack(spacing: 12) {
                                    // Compact Poster
                                    CachedAsyncImage(url: movie.posterURL) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle().fill(Color.white.opacity(0.05))
                                    }
                                    .frame(width: 48, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .opacity(currentSentiment == .unseen ? 0.6 : 1.0)
                                    
                                    // Title
                                    Text(movie.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(currentSentiment == .unseen ? .appTextSecondary : .appText)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // 3-State Reaction Row
                                    HStack(spacing: 8) {
                                        // Loved
                                        ReactionButton(icon: "heart.fill", color: .appPrimary, isActive: currentSentiment == .loved) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                viewModel.updateSentiment(movieId: movie.id, sentiment: .loved)
                                            }
                                        }
                                        
                                        // Okay
                                        ReactionButton(icon: "face.smiling", color: .white, isActive: currentSentiment == .okay) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                viewModel.updateSentiment(movieId: movie.id, sentiment: .okay)
                                            }
                                        }
                                        
                                        // Disliked
                                        ReactionButton(icon: "xmark.circle.fill", color: .red, isActive: currentSentiment == .disliked) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                viewModel.updateSentiment(movieId: movie.id, sentiment: .disliked)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(Color.white.opacity(currentSentiment != .unseen ? 0.05 : 0.02))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(currentSentiment != .unseen ? Color.appPrimary.opacity(0.2) : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            
            // Footer
            VStack {
                Spacer()
                Button(action: { 
                    withAnimation {
                        viewModel.moveToNextStep()
                    }
                }) {
                    Text("CONTINUE")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(viewModel.isStep3Valid ? .black : .white.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.isStep3Valid ? Color.appPrimary : Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: viewModel.isStep3Valid ? Color.appPrimary.opacity(0.3) : .clear, radius: 10, y: 5)
                }
                .disabled(!viewModel.isStep3Valid)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0), .black.opacity(0.8), .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct ReactionButton: View {
    let icon: String
    let color: Color
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isActive ? color.opacity(0.2) : Color.white.opacity(0.03))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(isActive ? color : .white.opacity(0.2))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
