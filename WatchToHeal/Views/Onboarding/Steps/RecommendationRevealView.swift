import SwiftUI

struct RecommendationRevealView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Based on your taste...")
                .font(.title)
                .bold()
                .foregroundColor(.appTextSecondary)
                .padding(.top, 40)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .tint(.appPrimary)
                    .scaleEffect(1.5)
                Spacer()
            } else if let movie = viewModel.recommendedMovie {
                VStack(spacing: 24) {
                    Text("We think you'll love:")
                        .font(.headline)
                        .foregroundColor(.appText)
                    
                    AsyncImage(url: movie.posterURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(16)
                                .shadow(color: .appPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
                        } else {
                            Rectangle().fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(height: 350)
                    
                    Text(movie.displayName)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    Text("Ready to watch tonight?")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
            
            Button(action: onFinish) {
                Text("Start Watching")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appPrimary)
                    .foregroundColor(.black)
                    .cornerRadius(16)
            }
            .padding([.horizontal, .bottom])
        }
        .onAppear {
            if viewModel.recommendedMovie == nil {
                viewModel.loadStepData(step: .result)
            }
        }
    }
}
