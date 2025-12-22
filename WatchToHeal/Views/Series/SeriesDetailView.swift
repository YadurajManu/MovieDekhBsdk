//
//  SeriesDetailView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 22/12/25.
//

import SwiftUI

struct SeriesDetailView: View {
    let seriesId: Int
    @StateObject private var viewModel = SeriesDetailViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var watchlistManager = WatchlistManager.shared
    @StateObject private var historyManager = HistoryManager.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @State private var selectedSimilarSeries: Movie?
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var showRecommendSheet = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.appBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.appPrimary)
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let series = viewModel.seriesDetail {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Immersive Header - Backdrop bleeding into Safe Area
                            ZStack(alignment: .bottom) {
                                CachedAsyncImage(url: series.backdropURL ?? series.posterURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Rectangle().fill(Color.appCardBackground)
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                                .clipped()
                                
                                // Refined Cinematic Gradient
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
                                        Text(series.displayName)
                                            .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 48))
                                            .foregroundColor(.appText)
                                            .lineLimit(2)
                                            .shadow(color: .black.opacity(0.5), radius: 10)
                                        
                                        HStack(spacing: 12) {
                                            // Primary Rating Badge
                                            HStack(spacing: 4) {
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 12, weight: .bold))
                                                Text(series.rating)
                                                    .font(.system(size: 14, weight: .black))
                                            }
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 12)
                                            .background(Color.appPrimary)
                                            .foregroundColor(.black)
                                            .cornerRadius(8)
                                            
                                            // Subtle Secondary Metadata
                                            HStack(spacing: 8) {
                                                Text(series.year)
                                                Text("•")
                                                Text(series.seasonsFormatted)
                                                
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
                                        
                                        Text(series.genreNames.uppercased())
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
                                // Series Info Pills
                                // Redesigned Info Grid (2x2)
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 12) {
                                    SeriesInfoPill(icon: "tv", text: series.seasonsFormatted)
                                    SeriesInfoPill(icon: "film.stack", text: series.episodesFormatted)
                                    SeriesInfoPill(icon: "clock", text: series.runtimeFormatted)
                                    if let status = series.status {
                                        SeriesInfoPill(icon: "circle.fill", text: status, color: status == "Returning Series" ? .green : .appTextSecondary)
                                    }
                                }
                                .padding(.top, 8)
                                
                                // Redesigned Premium Action Bar
                                HStack(spacing: 12) {
                                    if let trailer = series.youtubeTrailers.first {
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
                                    
                                    ActionBarIcon(icon: watchlistManager.isInWatchlist(series.id) ? "bookmark.fill" : "bookmark", 
                                                 isActive: watchlistManager.isInWatchlist(series.id)) {
                                        let seriesForWatchlist = Movie(id: series.id, title: nil, name: series.name, posterPath: series.posterPath, backdropPath: series.backdropPath, overview: series.overview, releaseDate: nil, firstAirDate: series.firstAirDate, voteAverage: series.voteAverage, voteCount: series.voteCount)
                                        let isAdding = !watchlistManager.isInWatchlist(series.id)
                                        withAnimation { watchlistManager.toggleWatchlist(seriesForWatchlist) }
                                        showToast(message: isAdding ? "Added to Watchlist" : "Removed from Watchlist")
                                    }
                                    
                                    ActionBarIcon(icon: historyManager.isWatched(movieId: series.id) ? "eye.fill" : "eye", 
                                                 isActive: historyManager.isWatched(movieId: series.id)) {
                                        // For series, we'll reuse the history manager logic
                                        showToast(message: "Series tracking coming soon!")
                                    }
                                    
                                    ActionBarIcon(icon: "paperplane", isActive: false) {
                                        showRecommendSheet = true
                                    }
                                }
                                
                                // Community Section
                                MovieCommunitySection(movieId: series.id, movieTitle: series.displayName, moviePoster: series.posterPath)
                                
                                // Overview
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("OVERVIEW")
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundColor(.appPrimary)
                                        .kerning(1)
                                    
                                    Text(series.overview)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.appTextSecondary)
                                        .lineSpacing(6)
                                }
                                
                                // Networks
                                if let networks = series.networks, !networks.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("NETWORKS")
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.appPrimary)
                                            .kerning(1)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(networks) { network in
                                                    VStack(spacing: 8) {
                                                        if let logoURL = network.logoURL {
                                                            CachedAsyncImage(url: logoURL) { image in
                                                                image.resizable().aspectRatio(contentMode: .fit)
                                                            } placeholder: {
                                                                RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05))
                                                            }
                                                            .frame(width: 60, height: 30)
                                                        }
                                                        Text(network.name)
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(.appTextSecondary)
                                                            .lineLimit(1)
                                                    }
                                                    .frame(width: 80)
                                                }
                                            }
                                        }
                                    }
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
                                            }
                                        }
                                    }
                                }
                                
                                // Similar Series
                                if let similar = series.similar?.results, !similar.isEmpty {
                                    VStack(alignment: .leading, spacing: 20) {
                                        Text("MORE LIKE THIS")
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.appPrimary)
                                            .kerning(1)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(similar.prefix(10)) { similarSeries in
                                                    Button(action: {
                                                        selectedSimilarSeries = similarSeries
                                                    }) {
                                                        MovieCardView(movie: similarSeries, width: 130)
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
                    .padding(.top, geometry.safeAreaInsets.top - 12)
                    .padding(.leading, 16)
                
                // Toast Overlay
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
        .fullScreenCover(item: $selectedSimilarSeries) { series in
            SeriesDetailView(seriesId: series.id)
        }
        .sheet(isPresented: $showRecommendSheet) {
            if let series = viewModel.seriesDetail {
                RecommendMovieSheet(
                    movieId: series.id,
                    movieTitle: series.displayName,
                    moviePoster: series.posterPath
                )
            }
        }
        .task {
            await viewModel.loadSeriesDetail(id: seriesId, region: appViewModel.userProfile?.preferredRegion ?? "US")
        }
    }
    
    private func showToast(message: String) {
        toastMessage = message
        withAnimation(.spring()) {
            showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

struct SeriesInfoPill: View {
    let icon: String
    let text: String
    var color: Color = .appTextSecondary
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .bold)) // Slightly larger text
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8) // Allow slight shrinking if needed
        }
        .foregroundColor(color)
        .padding(.vertical, 10) // Increased vertical padding
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity) // Fill the grid cell
        .background(Color.white.opacity(0.04))
        .cornerRadius(12) // More rounded corners
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

#Preview {
    SeriesDetailView(seriesId: 1399) // Game of Thrones
}
