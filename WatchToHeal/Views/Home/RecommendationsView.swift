import SwiftUI

struct RecommendationsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: HomeViewModel
    @State private var selectedMovie: Movie?
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            // Dynamic Background Glow
            Circle()
                .fill(Color.appPrimary.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -150, y: -200)
            
            VStack(spacing: 0) {
                // Custom Navigation Header
                HStack(spacing: 20) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.appText)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Personalized")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.appPrimary)
                            .tracking(2)
                        
                        Text("For You")
                            .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 36))
                            .foregroundColor(.appText)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                if viewModel.isLoadingRecommendations {
                    VStack(spacing: 20) {
                        ProgressView()
                            .tint(.appPrimary)
                            .scaleEffect(1.5)
                        
                        Text("Curating your next masterpiece...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if viewModel.personalizedRecommendations.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(.appPrimary.opacity(0.5))
                        
                        Text("Add more movies to your watchlist or history to get smarter recommendations.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            Task {
                                await viewModel.loadPersonalizedRecommendations()
                            }
                        }) {
                            Text("Try Again")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(Color.appPrimary))
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(viewModel.personalizedRecommendations) { movie in
                                Button(action: { selectedMovie = movie }) {
                                    MovieCardView(movie: movie)
                                        .frame(height: 280)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .refreshable {
                        await viewModel.loadPersonalizedRecommendations()
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedMovie) { movie in
            MovieDetailView(movieId: movie.id)
        }
    }
}
