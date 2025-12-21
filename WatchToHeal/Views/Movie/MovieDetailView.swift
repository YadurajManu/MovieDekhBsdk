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
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle().fill(Color.appCardBackground)
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                                .clipped()
                                
                                // Enhanced Cinematic Gradient
                                LinearGradient(
                                    colors: [
                                        .black.opacity(0.4),
                                        .clear,
                                        .appBackground.opacity(0.8),
                                        .appBackground
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: geometry.size.height * 0.5)
                                
                                // Floating Poster & Initial Info
                                HStack(alignment: .bottom, spacing: 20) {
                                    CachedAsyncImage(url: movie.posterURL) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle().fill(Color.appCardBackground)
                                    }
                                    .frame(width: 100, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 10)
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(movie.title)
                                            .font(.system(size: 28, weight: .black, design: .rounded))
                                            .foregroundColor(.appText)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.8)
                                        
                                        HStack(spacing: 8) {
                                            MetadataPill(text: movie.year, icon: "calendar")
                                            MetadataPill(text: movie.rating, icon: "star.fill", color: .appPrimary)
                                            MetadataPill(text: movie.runtimeFormatted, icon: "clock")
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                            
                            // Info Section
                            VStack(alignment: .leading, spacing: 32) {
                                // Subtitle / Genres
                                Text(movie.genreNames)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.appTextSecondary)
                                    .padding(.top, 8)
                                    .kerning(1)
                                
                                // Redesigned Premium Action Bar
                                HStack(spacing: 16) {
                                    if let trailer = movie.youtubeTrailers.first {
                                        Button(action: {
                                            if let url = trailer.youtubeURL { openURL(url) }
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "play.fill")
                                                Text("TRAILER")
                                            }
                                            .font(.system(size: 16, weight: .black))
                                            .foregroundColor(.black)
                                            .frame(height: 56)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.appPrimary)
                                            .cornerRadius(28)
                                            .shadow(color: .appPrimary.opacity(0.3), radius: 10, y: 5)
                                        }
                                    }
                                    
                                    Button(action: {
                                        let movieForWatchlist = Movie(id: movie.id, title: movie.title, posterPath: movie.posterPath, backdropPath: movie.backdropPath, overview: movie.overview, releaseDate: movie.releaseDate, voteAverage: movie.voteAverage, voteCount: movie.voteCount)
                                        withAnimation { watchlistManager.toggleWatchlist(movieForWatchlist) }
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(watchlistManager.isInWatchlist(movie.id) ? Color.appPrimary : Color.white.opacity(0.05))
                                                .frame(width: 56, height: 56)
                                            Image(systemName: watchlistManager.isInWatchlist(movie.id) ? "bookmark.fill" : "bookmark")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(watchlistManager.isInWatchlist(movie.id) ? .black : .appText)
                                        }
                                    }
                                    
                                    Button(action: {
                                        if historyManager.isWatched(movieId: movie.id) {
                                            historyManager.removeFromHistory(movieId: movie.id)
                                        } else {
                                            historyManager.addToHistory(movie: movie)
                                        }
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(historyManager.isWatched(movieId: movie.id) ? Color.appPrimary : Color.white.opacity(0.05))
                                                .frame(width: 56, height: 56)
                                            Image(systemName: historyManager.isWatched(movieId: movie.id) ? "eye.fill" : "eye")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(historyManager.isWatched(movieId: movie.id) ? .black : .appText)
                                        }
                                    }
                                    
                                    // Share Button
                                    if let movie = viewModel.movieDetail {
                                        ShareLink(item: URL(string: "https://www.themoviedb.org/movie/\(movie.id)")!, 
                                                  subject: Text("Check out this movie!"),
                                                  message: Text("I found this amazing movie on WatchToHeal: \(movie.title)")) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.white.opacity(0.05))
                                                    .frame(width: 56, height: 56)
                                                Image(systemName: "square.and.arrow.up")
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(.appText)
                                            }
                                        }
                                    }
                                }
                                
                                // Cinephile Community Section
                                MovieCommunitySection(movieId: movie.id, movieTitle: movie.title, moviePoster: movie.posterPath)
                                
                                // Where to Watch
                                if let providers = viewModel.watchProviders {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Image(systemName: "tv.fill")
                                                .foregroundColor(.appPrimary)
                                            Text("WHERE TO WATCH")
                                                .font(.system(size: 14, weight: .black))
                                                .kerning(1)
                                        }
                                        
                                        WatchProvidersView(providers: providers)
                                            .padding(20)
                                            .background(Color.white.opacity(0.03))
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                            )
                                    }
                                }
                                
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
                                                    VStack(spacing: 12) {
                                                        CachedAsyncImage(url: member.profileURL) { image in
                                                            image.resizable().aspectRatio(contentMode: .fill)
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
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 60)
                            .background(Color.appBackground)
                        }
                    }
                    .ignoresSafeArea()
                }
                
                // Fixed Back Button Overlay
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(.top, geometry.safeAreaInsets.top + 8)
                .padding(.leading, 16)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedSimilarMovie) { movie in
            MovieDetailView(movieId: movie.id)
        }
        .task {
            await viewModel.loadMovieDetail(id: movieId, region: appViewModel.userProfile?.preferredRegion ?? "US")
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
                .font(.system(size: 10, weight: .black))
            Text(text)
                .font(.system(size: 11, weight: .black))
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(color == .appPrimary ? color : Color.white.opacity(0.05))
        .foregroundColor(color == .appPrimary ? .black : .white)
        .cornerRadius(8)
        .fixedSize(horizontal: true, vertical: false)
    }
}
