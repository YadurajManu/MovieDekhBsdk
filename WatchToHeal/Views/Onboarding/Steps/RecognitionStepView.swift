import SwiftUI

struct RecognitionStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                Text("Which of these have you watched?")
                    .font(.title3)
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.appText)
                Text("Select multiple if applicable.")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.top)
            .padding(.bottom, 16)
            
            // Content - Scrollable Grid
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(viewModel.recognitionMovies) { movie in
                            Button(action: {
                                viewModel.toggleRecognition(id: movie.id)
                            }) {
                                ZStack(alignment: .topTrailing) {
                                    CachedAsyncImage(url: movie.posterURL) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle().fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(viewModel.selectedRecognitionIds.contains(movie.id) ? Color.appPrimary : Color.clear, lineWidth: 3)
                                    )
                                    
                                    if viewModel.selectedRecognitionIds.contains(movie.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.appPrimary)
                                            .background(Color.white.clipShape(Circle()))
                                            .padding(6)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            
            // Footer - Fixed at bottom
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
