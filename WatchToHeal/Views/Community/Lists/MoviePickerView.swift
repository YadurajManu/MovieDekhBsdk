import SwiftUI

struct MoviePickerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var searchViewModel = SearchViewModel()
    var suggestions: [Movie]
    var selectedMovies: [Movie]
    var onToggle: (Movie) -> Void
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("ADD MOVIE")
                        .font(.system(size: 10, weight: .black))
                        .tracking(2)
                        .foregroundColor(.appPrimary)
                    
                    Spacer()
                    
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appPrimary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.appTextSecondary)
                    
                    TextField("Search movies...", text: $searchViewModel.searchQuery)
                        .foregroundColor(.appText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchViewModel.searchQuery) { _ in
                            Task {
                                await searchViewModel.search()
                            }
                        }
                    
                    if !searchViewModel.searchQuery.isEmpty {
                        Button(action: { searchViewModel.clearSearch() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                if searchViewModel.isSearching {
                    ProgressView().tint(.appPrimary).frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if searchViewModel.searchQuery.isEmpty {
                                // Suggestions Section
                                Text("TRENDING SUGGESTIONS")
                                    .font(.system(size: 10, weight: .black))
                                    .tracking(2)
                                    .foregroundColor(.appPrimary)
                                    .padding(.horizontal, 24)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(suggestions) { movie in
                                        MoviePickerRow(movie: movie, isSelected: selectedMovies.contains(where: { $0.id == movie.id })) {
                                            onToggle(movie)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            } else if searchViewModel.multiSearchResults.isEmpty {
                                Text("No movies found.")
                                    .foregroundColor(.appTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 40)
                            } else {
                                // Results List
                                LazyVStack(spacing: 12) {
                                    ForEach(searchViewModel.multiSearchResults.filter { $0.mediaType == .movie }) { result in
                                        let movie = Movie(
                                            id: result.id,
                                            title: result.title ?? "",
                                            posterPath: result.posterPath,
                                            backdropPath: nil,
                                            overview: result.overview ?? "",
                                            releaseDate: result.releaseDate ?? "",
                                            voteAverage: result.voteAverage ?? 0.0,
                                            voteCount: result.voteCount ?? 0
                                        )
                                        MoviePickerRow(movie: movie, isSelected: selectedMovies.contains(where: { $0.id == movie.id })) {
                                            onToggle(movie)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }
}

struct MoviePickerRow: View {
    let movie: Movie
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let path = movie.posterPath {
                    CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w200\(path)")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.appCardBackground
                    }
                    .frame(width: 40, height: 60)
                    .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(movie.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appText)
                    Text(movie.year)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.appPrimary : Color.white.opacity(0.1), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appPrimary)
                            .font(.system(size: 24))
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(isSelected ? Color.appPrimary.opacity(0.1) : Color.white.opacity(0.04)))
        }
    }
}
