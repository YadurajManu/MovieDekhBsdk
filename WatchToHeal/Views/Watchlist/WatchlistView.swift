//
//  WatchlistView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

struct WatchlistView: View {
    @Binding var selectedTab: TabItem
    @StateObject private var watchlistManager = WatchlistManager.shared
    @State private var selectedMovie: Movie?
    @State private var showDeleteConfirmation = false
    @State private var movieToDelete: Movie?
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Watchlist")
                        .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 32))
                        .foregroundColor(.appText)
                    
                    Spacer()
                    
                    if !watchlistManager.watchlistMovies.isEmpty {
                        Text("\(watchlistManager.watchlistMovies.count) \(watchlistManager.watchlistMovies.count == 1 ? "movie" : "movies")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Content
                if watchlistManager.watchlistMovies.isEmpty {
                    EmptyStateView.emptyWatchlist {
                        selectedTab = .search
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 24) {
                            ForEach(watchlistManager.watchlistMovies) { movie in
                                VStack(alignment: .leading, spacing: 10) {
                                    Button(action: {
                                        selectedMovie = movie
                                    }) {
                                        ZStack(alignment: .topTrailing) {
                                            // Poster only
                                            CachedAsyncImage(url: movie.posterURL) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.white.opacity(0.05))
                                                    .overlay {
                                                        ProgressView().tint(.appPrimary)
                                                    }
                                            }
                                            .frame(height: 250) // Increased height for 2-column layout
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
                                            
                                            // Remove button
                                            Button(action: {
                                                movieToDelete = movie
                                                showDeleteConfirmation = true
                                            }) {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 10, weight: .black))
                                                    .foregroundColor(.black)
                                                    .frame(width: 24, height: 24)
                                                    .background(Color.appPrimary)
                                                    .clipShape(Circle())
                                                    .shadow(radius: 4)
                                            }
                                            .padding(8)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(movie.title)
                                            .font(.system(size: 16, weight: .bold)) // Slightly larger title
                                            .foregroundColor(.appText)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(height: 40, alignment: .top)
                                        
                                        HStack(spacing: 8) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.yellow)
                                                Text(movie.rating)
                                                    .font(.system(size: 13, weight: .bold))
                                            }
                                            
                                            Text(movie.year)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        .foregroundColor(.appText)
                                        
                                        InteractiveRatingView(
                                            rating: .init(get: { movie.userRating }, set: { _ in }),
                                            starSize: 16,
                                            starSpacing: 4
                                        ) { newRating in
                                            watchlistManager.rateMovie(movie, rating: newRating)
                                        }
                                        .padding(.top, 4)
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedMovie) { movie in
            MovieDetailView(movieId: movie.id)
        }
        .alert("Remove from Watchlist?", isPresented: $showDeleteConfirmation, presenting: movieToDelete) { movie in
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                withAnimation {
                    watchlistManager.removeFromWatchlist(movie.id)
                }
            }
        } message: { movie in
            Text("Are you sure you want to remove \"\(movie.title)\" from your watchlist?")
        }
    }
}

#Preview {
    WatchlistView(selectedTab: .constant(.watchlist))
}
