import SwiftUI

struct PolarityStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("How did you feel about these?")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.appText)
                Text("Did you enjoy them or not really?")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.top)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.polarityMovies) { movie in
                            HStack(spacing: 16) {
                                AsyncImage(url: movie.posterURL) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Rectangle().fill(Color.gray.opacity(0.3))
                                    }
                                }
                                .frame(width: 60, height: 90)
                                .cornerRadius(8)
                                
                                Text(movie.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.appText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 12) {
                                    Button(action: { viewModel.setPolarity(id: movie.id, liked: true) }) {
                                        Image(systemName: viewModel.likedMovies.contains(movie.id) ? "hand.thumbsup.fill" : "hand.thumbsup")
                                            .foregroundColor(viewModel.likedMovies.contains(movie.id) ? .green : .gray)
                                            .font(.title2)
                                    }
                                    
                                    Button(action: { viewModel.setPolarity(id: movie.id, liked: false) }) {
                                        Image(systemName: viewModel.dislikedMovies.contains(movie.id) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                            .foregroundColor(viewModel.dislikedMovies.contains(movie.id) ? .red : .gray)
                                            .font(.title2)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            
            Button(action: { viewModel.moveToNextStep() }) {
                Text("Next")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appPrimary)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}
