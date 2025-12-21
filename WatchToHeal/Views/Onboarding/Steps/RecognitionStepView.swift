import SwiftUI

struct RecognitionStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            // Visual Anchor - Subtle Top Gradient
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
                    Text("CALIBRATE YOUR TASTE")
                        .font(.system(size: 14, weight: .black))
                        .kerning(2)
                        .foregroundColor(.appPrimary)
                    
                    Text("Which of these have you watched?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.appText)
                        .multilineTextAlignment(.center)
                    
                    Text("Pick anything you’ve seen. This takes under a minute.")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.top, 24)
                .padding(.bottom, 24)
                
                // Content - Scrollable Grid
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(.appPrimary)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.recognitionMovies) { movie in
                                let isSelected = viewModel.selectedRecognitionIds.contains(movie.id)
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.toggleRecognition(id: movie.id)
                                    }
                                }) {
                                    ZStack(alignment: .topTrailing) {
                                        CachedAsyncImage(url: movie.posterURL) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle().fill(Color.white.opacity(0.05))
                                        }
                                        .frame(height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .opacity(isSelected ? 1.0 : 0.7)
                                        .grayscale(isSelected ? 0.0 : 0.3)
                                        .scaleEffect(isSelected ? 0.95 : 1.0)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? Color.appPrimary : Color.white.opacity(0.05), lineWidth: isSelected ? 2 : 1)
                                        )
                                        
                                        if isSelected {
                                            ZStack {
                                                Circle()
                                                    .fill(.ultraThinMaterial)
                                                    .frame(width: 24, height: 24)
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .black))
                                                    .foregroundColor(.appPrimary)
                                            }
                                            .padding(8)
                                            .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            
            // Footer - Fixed high-contrast button
            VStack {
                Spacer()
                Button(action: { 
                    withAnimation {
                        viewModel.moveToNextStep() 
                    }
                }) {
                    Text("CONTINUE")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(!viewModel.selectedRecognitionIds.isEmpty ? .black : .white.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(!viewModel.selectedRecognitionIds.isEmpty ? Color.appPrimary : Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: !viewModel.selectedRecognitionIds.isEmpty ? Color.appPrimary.opacity(0.3) : .clear, radius: 10, y: 5)
                }
                .disabled(viewModel.selectedRecognitionIds.isEmpty)
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
