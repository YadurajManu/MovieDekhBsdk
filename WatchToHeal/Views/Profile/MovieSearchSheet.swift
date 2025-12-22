import SwiftUI

struct MovieSearchSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var searchViewModel = SearchViewModel()
    var onSelect: (Movie) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.appTextSecondary)
                    
                    TextField("Search movies...", text: $searchViewModel.searchQuery)
                        .foregroundColor(.appText)
                        .autocapitalization(.none)
                        .onChange(of: searchViewModel.searchQuery) { _ in
                            Task {
                                await searchViewModel.search()
                            }
                        }
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(12)
                .cornerRadius(12)
                .padding()
                
                // Recommendations from Watchlist
                if searchViewModel.searchQuery.isEmpty && !WatchlistManager.shared.watchlistMovies.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("FROM YOUR WATCHLIST")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appPrimary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(WatchlistManager.shared.watchlistMovies) { movie in
                                    Button(action: {
                                        onSelect(movie)
                                        dismiss()
                                    }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            CachedAsyncImage(url: movie.posterURL) { image in
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.white.opacity(0.1))
                                            }
                                            .frame(width: 100, height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                            
                                            Text(movie.displayName)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                                .frame(width: 100)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)
                }
                
                // Results
                if searchViewModel.isSearching {
                    ProgressView()
                        .padding(.top, 50)
                    Spacer()
                } else if !searchViewModel.multiSearchResults.isEmpty {
                    List(searchViewModel.multiSearchResults) { result in
                        // Filter out persons if needed, or just show all
                        if result.mediaType != .person {
                            Button(action: {
                                // Convert SearchResult to Movie
                                let movie = Movie(
                                    id: result.id,
                                    title: result.displayTitle,
                                    posterPath: result.posterPath,
                                    backdropPath: nil,
                                    overview: result.overview ?? "",
                                    releaseDate: result.releaseDate ?? result.firstAirDate ?? "",
                                    voteAverage: result.voteAverage ?? 0.0,
                                    voteCount: result.voteCount ?? 0
                                )
                                onSelect(movie)
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w200\(result.posterPath ?? "")")) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Color.gray
                                        }
                                    }
                                    .frame(width: 40, height: 60)
                                    .cornerRadius(4)
                                    
                                    VStack(alignment: .leading) {
                                        Text(result.displayTitle)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.appText)
                                        
                                        if let date = result.releaseDate ?? result.firstAirDate, !date.isEmpty {
                                            Text(String(date.prefix(4)))
                                                .font(.system(size: 14))
                                                .foregroundColor(.appTextSecondary)
                                        }
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(Color.white.opacity(0.1))
                        }
                    }
                    .listStyle(.plain)
                } else {
                    Spacer()
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Select Movie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
