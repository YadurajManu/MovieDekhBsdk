import SwiftUI

struct CompetitionStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Guess which movie is rated higher")
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.appText)
                Text("Test your film intuition.")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.top, 20)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.competitionPair.count >= 2 {
                HStack(spacing: 16) {
                    ForEach(viewModel.competitionPair.prefix(2)) { movie in
                        Button(action: {
                            viewModel.winnerId = movie.id
                            // Tiny delay to show selection then move on
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                viewModel.moveToNextStep()
                            }
                        }) {
                            VStack {
                                AsyncImage(url: movie.posterURL) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Rectangle().fill(Color.gray.opacity(0.3))
                                    }
                                }
                                .frame(height: 240)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.winnerId == movie.id ? Color.appPrimary : Color.clear, lineWidth: 4)
                                )
                                
                                Text(movie.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                            }
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .onAppear {
            if viewModel.competitionPair.isEmpty {
                 // Trigger load if empty (should be loaded by previous step logic usually, but here safeguard)
                 viewModel.loadStepData(step: .competition)
            }
        }
    }
}
