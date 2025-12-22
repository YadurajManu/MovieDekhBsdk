//
//  HomeView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedMovie: Movie?
    @State private var selectedSeries: Movie?
    @State private var selectedCategory: MovieCategory?
    @State private var showRecommendations = false
    @State private var showProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.appBackground.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.tradingMovies.isEmpty {
                    // Skeleton Loading State
                    ScrollView {
                        VStack(spacing: 32) {
                            SkeletonHeroCard()
                            SkeletonMovieSection()
                            SkeletonMovieSection()
                            SkeletonMovieSection()
                            SkeletonMovieSection()
                            SkeletonMovieSection()
                        }
                        .padding(.vertical, 24)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    // Error State
                    EmptyStateView.error(message: errorMessage) {
                        Task {
                            await viewModel.loadAllMovies()
                        }
                    }
                } else {
                    ZStack(alignment: .top) {
                        ScrollView {
                            VStack(spacing: 0) {
                                if viewModel.selectedSegment == .movies {
                                    movieContent
                                } else {
                                    seriesContent
                                }
                            }
                        }
                        .ignoresSafeArea(edges: .top)
                        .refreshable {
                            await viewModel.loadAllMovies(region: appViewModel.userProfile?.preferredRegion ?? "US")
                        }
                        
                        // Custom Header Removed
                    }
                }

            }
        }
        .fullScreenCover(item: $selectedMovie) { movie in
            MovieDetailView(movieId: movie.id)
        }
        .fullScreenCover(item: $selectedSeries) { series in
            SeriesDetailView(seriesId: series.id)
        }
        .fullScreenCover(item: $selectedCategory) { category in
            CategoryView(category: category)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .fullScreenCover(isPresented: $showRecommendations) {
            RecommendationsView(viewModel: viewModel)
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadAllMovies(region: appViewModel.userProfile?.preferredRegion ?? "US")
        }
    }
    
    @ViewBuilder
    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(HomeSegment.allCases, id: \.self) { segment in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        viewModel.selectedSegment = segment
                    }
                }) {
                    Text(segment.rawValue.uppercased())
                        .font(.system(size: 11, weight: .black)) // Reduced size
                        .kerning(1.2)
                        .foregroundColor(viewModel.selectedSegment == segment ? .black : .white.opacity(0.7))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedSegment == segment ? Color.appPrimary : Color.clear)
                        )
                }
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
        )
        .padding(.top, -30) // Overlap the Hero Card
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var movieContent: some View {
        VStack(spacing: 0) { // Changed to 0 to manage spacing manually
            // Hero Section (Trending Movies)
            if let heroMovie = viewModel.tradingMovies.first {
                HeroMovieCard(movie: heroMovie) {
                    selectedMovie = heroMovie
                }
                .padding(.top, -20)
            }
            
            // Tab Switcher
            tabSwitcher
            
            VStack(spacing: 32) { // Inner VStack for lists
                // Personalized Recommendations
                if !viewModel.personalizedRecommendations.isEmpty {
                    MovieSectionView(title: "Recommended for You", movies: viewModel.personalizedRecommendations) { movie in
                        selectedMovie = movie
                    } onSeeAllTap: {
                        showRecommendations = true
                    }
                }
                
                // Now Playing
                MovieSectionView(title: "Now Playing in Theaters", movies: viewModel.nowPlaying) { movie in
                    selectedMovie = movie
                } onSeeAllTap: {
                    selectedCategory = .nowPlaying
                }
                
                // Trending
                MovieSectionView(title: "Trending Movies", movies: viewModel.tradingMovies) { movie in
                    selectedMovie = movie
                } onSeeAllTap: {
                    selectedCategory = .trending
                }
                
                // Directors Spotlights
                ForEach(viewModel.famousDirectors.prefix(2), id: \.id) { director in
                    if let movies = viewModel.directorMovies[director.id], !movies.isEmpty {
                        MovieSectionView(title: "Director Spotlight: \(director.name)", movies: movies) { movie in
                            selectedMovie = movie
                        } onSeeAllTap: {}
                    }
                }
                
                 // Action Movies
                MovieSectionView(title: "Adrenaline Rush", movies: viewModel.actionMovies) { movie in
                    selectedMovie = movie
                } onSeeAllTap: {}
                
                // Comedy Movies
                MovieSectionView(title: "Laughter Therapy", movies: viewModel.comedyMovies) { movie in
                    selectedMovie = movie
                } onSeeAllTap: {}
                
                // Netflix
                MovieSectionView(title: "Popular on Netflix", movies: viewModel.netflixMovies) { movie in
                    selectedMovie = movie
                } onSeeAllTap: {}

                // Disney+
                MovieSectionView(title: "Disney+ Favorites", movies: viewModel.disneyMovies) { movie in
                    selectedMovie = movie
                } onSeeAllTap: {}
            }
            .padding(.top, 10)
        }
        .padding(.bottom, 100)
    }
    
    @ViewBuilder
    private var seriesContent: some View {
        VStack(spacing: 0) { // Zero spacing for Hero overlap
            // Hero Section (Trending TV)
            if let heroSeries = viewModel.tradingSeries.first {
                HeroMovieCard(movie: heroSeries) {
                    selectedSeries = heroSeries
                }
                .padding(.top, -20)
            }
            
            // Tab Switcher
            tabSwitcher
            
            VStack(spacing: 32) {
                // Trending Series
                MovieSectionView(title: "Popular TV Shows", movies: viewModel.tradingSeries) { series in
                    selectedSeries = series
                } onSeeAllTap: {
                    selectedCategory = .popularSeries
                }
                
                // Top Rated Series
                MovieSectionView(title: "Critically Acclaimed", movies: viewModel.topRatedSeries) { series in
                    selectedSeries = series
                } onSeeAllTap: {
                    selectedCategory = .topRatedSeries
                }
                
                // Netflix Series
                MovieSectionView(title: "Netflix Originals", movies: viewModel.netflixSeries) { series in
                    selectedSeries = series
                } onSeeAllTap: {
                    selectedCategory = .netflixSeries
                }
                
                // Disney+ Series
                MovieSectionView(title: "Disney+ Originals", movies: viewModel.disneySeries) { series in
                    selectedSeries = series
                } onSeeAllTap: {
                    selectedCategory = .disneySeries
                }
                
                // Amazon Series
                MovieSectionView(title: "Amazon Prime Video", movies: viewModel.amazonSeries) { series in
                    selectedSeries = series
                } onSeeAllTap: {
                    selectedCategory = .amazonSeries
                }
                
                // Apple TV+ Series
                MovieSectionView(title: "Apple TV+ Originals", movies: viewModel.appleTVSeries) { series in
                    selectedSeries = series
                } onSeeAllTap: {
                    selectedCategory = .appleTVSeries
                }
                
                // Action & Adventure Series
                MovieSectionView(title: "Action & Adventure TV", movies: viewModel.actionSeries) { series in
                    selectedSeries = series
                } onSeeAllTap: {
                    selectedCategory = .actionSeries
                }
                
                // Drama Series
                MovieSectionView(title: "Compelling Dramas", movies: viewModel.dramaSeries) { series in
                    selectedSeries = series
                } onSeeAllTap: {
                    selectedCategory = .dramaSeries
                }
                
                // Sci-Fi Series
                MovieSectionView(title: "Sci-Fi & Fantasy", movies: viewModel.sciFiSeries) { series in
                    selectedSeries = series
                } onSeeAllTap: {
                    selectedCategory = .sciFiSeries
                }
                
                // Mystery Series
                MovieSectionView(title: "Mystery & Suspense", movies: viewModel.mysterySeries) { series in
                    selectedSeries = series
                } onSeeAllTap: {
                    selectedCategory = .mysterySeries
                }
                
                // Comedy Series
                MovieSectionView(title: "Comedy Series", movies: viewModel.comedySeries) { series in
                    selectedSeries = series
                } onSeeAllTap: {
                    selectedCategory = .comedySeries
                }
            }
            .padding(.top, 10)
        }
        .padding(.bottom, 100)
    }
}

#Preview {
    HomeView()
}
