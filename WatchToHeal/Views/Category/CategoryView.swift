//
//  CategoryView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

enum MovieCategory: String, Identifiable, CaseIterable {
    case nowPlaying = "New Releases"
    case upcoming = "Coming Soon"
    case topRated = "Top Rated"
    case trending = "Trending Now"
    case action = "Action Packed"
    case comedy = "Comedy Hits"
    case drama = "Dramatic Stories"
    case horror = "Horror & Suspense"
    case sciFi = "Sci-Fi & Fantasy"
    case thriller = "Thrillers"
    case romance = "Romance & Love Stories"
    case animation = "Animated Favorites"
    case documentary = "Documentaries"
    case crime = "Crime & Mystery"
    case adventure = "Adventure & Quest"
    case war = "War & History"
    
    // World Cinema
    case indianClassics = "Indian Classics"
    case frenchCinema = "French Cinema"
    case koreanMasterpieces = "Korean Masterpieces"
    case japaneseMasterpieces = "Japanese Masterpieces"
    
    // Streaming Services
    case netflix = "New on Netflix"
    case disney = "New on Disney+"
    case amazon = "New on Amazon Prime"
    case appleTV = "New on Apple TV+"
    
    // TV Series Categories
    case popularSeries = "Popular TV Shows"
    case topRatedSeries = "Critically Acclaimed TV"
    case netflixSeries = "Netflix Series"
    case disneySeries = "Disney+ Series"
    case amazonSeries = "Amazon Prime Series"
    case appleTVSeries = "Apple TV+ Series"
    case actionSeries = "Action & Adventure TV"
    case comedySeries = "Comedy TV"
    case dramaSeries = "TV Dramas"
    case sciFiSeries = "Sci-Fi & Fantasy TV"
    case mysterySeries = "Mystery TV"
    
    var id: String { rawValue }
}

struct CategoryView: View {
    let category: MovieCategory
    @StateObject private var viewModel = CategoryViewModel()
    @State private var selectedMovie: Movie?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.appText)
                            .frame(width: 40, height: 40)
                    }
                    
                    Text(category.rawValue)
                        .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 28))
                        .foregroundColor(.appText)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Content
                if viewModel.isLoading && viewModel.movies.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(.appPrimary)
                        .scaleEffect(1.5)
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            Task {
                                await viewModel.loadMovies(category: category)
                            }
                        }
                        .padding()
                        .background(Color.appPrimary)
                        .foregroundColor(.appBackground)
                        .cornerRadius(8)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 20) {
                            ForEach(viewModel.movies) { movie in
                                Button(action: {
                                    selectedMovie = movie
                                }) {
                                    MovieCardView(movie: movie, width: nil)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onAppear {
                                    // Load more when reaching last item
                                    if movie.id == viewModel.movies.last?.id {
                                        Task {
                                            await viewModel.loadMoreIfNeeded(category: category)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                        
                        // Loading more indicator
                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .tint(.appPrimary)
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedMovie) { movie in
            MovieDetailView(movieId: movie.id)
        }
        .task {
            await viewModel.loadMovies(category: category)
        }
    }
}

#Preview {
    CategoryView(category: .nowPlaying)
}
