//
//  MovieDetailView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

struct MovieDetailView: View {
    let movieId: Int
    @StateObject private var viewModel = MovieDetailViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var watchlistManager = WatchlistManager.shared
    @StateObject private var historyManager = HistoryManager.shared
    @StateObject private var traktService = TraktService.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @State private var selectedSimilarMovie: Movie?
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var showRecommendSheet = false
    @State private var selectedActorId: IdentifiableInt?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.appBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.appPrimary)
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let movie = viewModel.movieDetail {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Immersive Header - Backdrop bleeding into Safe Area
                            ZStack(alignment: .bottom) {
                                CachedAsyncImage(url: movie.backdropURL ?? movie.posterURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Rectangle().fill(Color.appCardBackground)
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                                .clipped()
                                
                                // Refined Cinematic Gradient with multi-stop anchoring
                                LinearGradient(
                                    stops: [
                                        .init(color: .black.opacity(0.6), location: 0),
                                        .init(color: .clear, location: 0.4),
                                        .init(color: .appBackground.opacity(0.5), location: 0.7),
                                        .init(color: .appBackground, location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                
                                // Floating Content Container
                                VStack(alignment: .leading, spacing: 20) {
                                    Spacer()
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(movie.title)
                                            .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 48))
                                            .foregroundColor(.appText)
                                            .lineLimit(2)
                                            .shadow(color: .black.opacity(0.5), radius: 10)
                                        
                                        HStack(spacing: 12) {
                                            // Primary Rating Badge
                                            PremiumRatingBadge(rating: movie.voteAverage, size: .medium)
                                            
                                            // Subtle Secondary Metadata
                                            HStack(spacing: 8) {
                                                Text(movie.year)
                                                Text("•")
                                                Text(movie.runtimeFormatted)
                                                
                                                // Availability Indicator
                                                if let providers = viewModel.watchProviders,
                                                   let preferredIds = appViewModel.userProfile?.streamingProviders,
                                                   !(providers.flatrate ?? []).filter({ Set(preferredIds).contains($0.id) }).isEmpty {
                                                    Text("•")
                                                    Image(systemName: "play.fill")
                                                        .font(.system(size: 10))
                                                    Text("STREAMING")
                                                        .foregroundColor(.appPrimary)
                                                }
                                            }
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.appTextSecondary)
                                        }
                                        
                                        Text(movie.genreNames.uppercased())
                                            .font(.system(size: 10, weight: .black))
                                            .kerning(2)
                                            .foregroundColor(.appPrimary.opacity(0.8))
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.bottom, 20)
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                            
                            // Info Section
                            VStack(alignment: .leading, spacing: 32) {
                                // Redesigned Premium Action Bar
                                HStack(spacing: 12) {
                                    if let trailer = movie.youtubeTrailers.first {
                                        Button(action: {
                                            if let url = trailer.youtubeURL { openURL(url) }
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "play.fill")
                                                    .font(.system(size: 12, weight: .black))
                                                Text("TRAILER")
                                                    .font(.system(size: 14, weight: .black))
                                            }
                                            .foregroundColor(.black)
                                            .frame(height: 52)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.appPrimary)
                                            .cornerRadius(16)
                                            .shadow(color: .appPrimary.opacity(0.3), radius: 10, y: 5)
                                        }
                                    }
                                    
                                    ActionBarIcon(icon: watchlistManager.isInWatchlist(movie.id) ? "bookmark.fill" : "bookmark", 
                                                 isActive: watchlistManager.isInWatchlist(movie.id)) {
                                        let movieForWatchlist = Movie(id: movie.id, title: movie.title, posterPath: movie.posterPath, backdropPath: movie.backdropPath, overview: movie.overview, releaseDate: movie.releaseDate, voteAverage: movie.voteAverage, voteCount: movie.voteCount)
                                        let isAdding = !watchlistManager.isInWatchlist(movie.id)
                                        withAnimation { watchlistManager.toggleWatchlist(movieForWatchlist) }
                                        showToast(message: isAdding ? "Added to Watchlist" : "Removed from Watchlist")
                                    }
                                    
                                    ActionBarIcon(icon: historyManager.isWatched(movieId: movie.id) ? "eye.fill" : "eye", 
                                                 isActive: historyManager.isWatched(movieId: movie.id)) {
                                        if historyManager.isWatched(movieId: movie.id) {
                                            historyManager.removeFromHistory(movieId: movie.id)
                                            showToast(message: "Removed from History")
                                        } else {
                                            historyManager.addToHistory(movie: movie)
                                            showToast(message: "Marked as Watched")
                                        }
                                    }
                                    
                                    ActionBarIcon(icon: "paperplane", isActive: false) {
                                        showRecommendSheet = true
                                    }
                                }
                                
                                // Cinephile Community Section - Teased earlier
                                MovieCommunitySection(movieId: movie.id, movieTitle: movie.title, moviePoster: movie.posterPath)
                                
                                // Overview
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("OVERVIEW")
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundColor(.appPrimary)
                                        .kerning(1)
                                    
                                    Text(movie.overview)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.appTextSecondary)
                                        .lineSpacing(6)
                                }
                                
                                // Cast
                                if !viewModel.cast.isEmpty {
                                    VStack(alignment: .leading, spacing: 20) {
                                        Text("TOP CAST")
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.appPrimary)
                                            .kerning(1)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 20) {
                                                ForEach(viewModel.cast.prefix(12)) { member in
                                                    Button(action: { selectedActorId = IdentifiableInt(id: member.id) }) {
                                                        VStack(spacing: 12) {
                                                            CachedAsyncImage(url: member.profileURL) { image in
                                                                image.resizable().scaledToFill()
                                                            } placeholder: {
                                                                Circle().fill(Color.white.opacity(0.05))
                                                            }
                                                            .frame(width: 70, height: 70)
                                                            .clipShape(Circle())
                                                            .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
                                                            
                                                            VStack(spacing: 2) {
                                                                Text(member.name)
                                                                    .font(.system(size: 12, weight: .bold))
                                                                    .foregroundColor(.appText)
                                                                    .lineLimit(1)
                                                                
                                                                Text(member.character)
                                                                    .font(.system(size: 10))
                                                                    .foregroundColor(.appTextSecondary)
                                                                    .lineLimit(1)
                                                            }
                                                            .frame(width: 80)
                                                        }
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Similar Movies
                                if let similar = movie.similar?.results, !similar.isEmpty {
                                    VStack(alignment: .leading, spacing: 20) {
                                        Text("MORE LIKE THIS")
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.appPrimary)
                                            .kerning(1)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(similar.prefix(10)) { similarMovie in
                                                    Button(action: {
                                                        selectedSimilarMovie = similarMovie
                                                    }) {
                                                        MovieCardView(movie: similarMovie, width: 130)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Where to Watch - Moved to Bottom
                                if let providers = viewModel.watchProviders {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("WHERE TO WATCH")
                                                .font(.system(size: 10, weight: .black))
                                                .kerning(2)
                                                .foregroundColor(.appPrimary)
                                            Spacer()
                                            Rectangle().fill(Color.appPrimary.opacity(0.2)).frame(height: 1)
                                        }
                                        
                                        WatchProvidersView(
                                            providers: providers,
                                            preferredProviderIds: Set(appViewModel.userProfile?.streamingProviders ?? [])
                                        )
                                        .padding(16)
                                        .background(Color.white.opacity(0.04))
                                        .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 60)
                            .background(Color.appBackground)
                        }
                    }
                    .ignoresSafeArea()
                }
                
                // Fixed Back Button Overlay
                GlassBackButton(action: { dismiss() })
                    .padding(.top, 16)
                    .padding(.leading, 16)
                
                // Elegant Toast Overlay
                if showToast, let message = toastMessage {
                    VStack {
                        Spacer()
                        Text(message)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.appPrimary)
                            .cornerRadius(25)
                            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .padding(.bottom, 100)
                    .frame(maxWidth: .infinity)
                    .zIndex(100)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedSimilarMovie) { movie in
            MovieDetailView(movieId: movie.id)
        }
        .fullScreenCover(item: $selectedActorId) { wrapper in
            ActorDetailView(actorId: wrapper.id)
        }
        .sheet(isPresented: $showRecommendSheet) {
            if let movie = viewModel.movieDetail {
                RecommendMovieSheet(
                    movieId: movie.id,
                    movieTitle: movie.title,
                    moviePoster: movie.posterPath
                )
            }
        }
        .task {
            await viewModel.loadMovieDetail(id: movieId, region: appViewModel.userProfile?.preferredRegion ?? "US")
        }
    }
    
    private func showToast(message: String) {
        toastMessage = message
        withAnimation(.spring()) {
            showToast = true
        }
        
        // Auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

struct MetadataPill: View {
    let text: String
    let icon: String
    var color: Color = .white.opacity(0.1)
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .black))
            Text(text)
                .font(.system(size: 9, weight: .black))
                .lineLimit(1)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(color == .appPrimary ? color : Color.white.opacity(0.04))
        .foregroundColor(color == .appPrimary ? .black : .white.opacity(0.6))
        .cornerRadius(6)
    }
}


struct ActionBarIcon: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? Color.appPrimary : Color.white.opacity(0.04))
                    .frame(width: 52, height: 52)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(isActive ? Color.appPrimary : Color.white.opacity(0.06), lineWidth: 1))
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isActive ? .black : .appText)
            }
        }
    }
}
