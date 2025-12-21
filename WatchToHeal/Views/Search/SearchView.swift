//
//  SearchView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = SearchViewModel()
    @State private var selectedMovie: Movie?
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with Search Bar
                VStack(spacing: 16) {
                    // Title and Close
                    HStack {
                        Text("Search")
                            .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 36))
                            .foregroundColor(.appText)
                        
                        Spacer()
                    }
                    .padding(.top, 10)
                    
                    // Premium Search Bar Area
                    HStack(spacing: 12) {
                        // Search Input
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.appTextSecondary)
                            
                            TextField("Search movies or people...", text: $viewModel.searchQuery)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.appText)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onChange(of: viewModel.searchQuery) { _ in
                                    Task { await viewModel.search() }
                                }
                            
                            if !viewModel.searchQuery.isEmpty {
                                Button(action: { viewModel.clearSearch() }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.appTextSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if !viewModel.searchQuery.isEmpty {
                            Button("Cancel") {
                                withAnimation {
                                    viewModel.clearSearch()
                                    hideKeyboard()
                                }
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.appPrimary)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    
                    // Scope Bar (Tags)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(SearchViewModel.SearchScope.allCases) { scope in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.selectedScope = scope
                                        Task { await viewModel.search() }
                                    }
                                }) {
                                    Text(scope.rawValue)
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(
                                            viewModel.selectedScope == scope
                                            ? Color.appPrimary
                                            : Color.white.opacity(0.05)
                                        )
                                        .foregroundColor(
                                            viewModel.selectedScope == scope
                                            ? .black
                                            : .appText
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .background(Color.appBackground)
                .zIndex(2)
                
                // Integrated Filter Bar
                IntegratedFilterBar(viewModel: viewModel)
                    .background(Color.appBackground)
                    .zIndex(1)
                
                // Content Area
                ZStack {
                    if viewModel.isSearching {
                        VStack {
                            ProgressView()
                                .tint(.appPrimary)
                                .scaleEffect(1.2)
                                .padding(.top, 40)
                            Spacer()
                        }
                    } else if let error = viewModel.errorMessage {
                        EmptyStateView.error(message: error) {
                            Task { await viewModel.search() }
                        }
                    } else if viewModel.searchQuery.isEmpty && !viewModel.isDiscoveryMode {
                        // Recents & Trending Section
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 32) {
                                if !viewModel.recentSearches.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("RECENT")
                                                .font(.system(size: 14, weight: .black))
                                                .foregroundColor(.appTextSecondary)
                                                .kerning(1)
                                            Spacer()
                                            Button("CLEAR") { viewModel.clearAllRecentSearches() }
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.appPrimary)
                                        }
                                        .padding(.horizontal, 20)
                                        
                                        FlowLayout(spacing: 8) {
                                            ForEach(viewModel.recentSearches, id: \.self) { query in
                                                Button(action: { viewModel.selectRecentSearch(query) }) {
                                                    HStack(spacing: 6) {
                                                        Image(systemName: "clock.fill")
                                                            .font(.system(size: 10))
                                                        Text(query)
                                                            .font(.system(size: 14, weight: .medium))
                                                    }
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 8)
                                                    .background(Color.white.opacity(0.05))
                                                    .clipShape(Capsule())
                                                    .foregroundColor(.appText)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                
                                if !viewModel.trendingMovies.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("TRENDING")
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.appTextSecondary)
                                            .kerning(1)
                                            .padding(.horizontal, 20)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(viewModel.trendingMovies.prefix(10)) { movie in
                                                    Button(action: { selectedMovie = movie }) {
                                                        MovieCardView(movie: movie, width: 110)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 100)
                        }
                    } else {
                        // Search Results List (Letterboxd Style)
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                let movies: [Movie] = {
                                    if viewModel.isDiscoveryMode {
                                        return viewModel.searchResults
                                    } else {
                                        return viewModel.multiSearchResults.compactMap { result in
                                            guard result.mediaType != .person else { return nil }
                                            return Movie(
                                                id: result.id,
                                                title: result.displayTitle,
                                                posterPath: result.posterPath,
                                                backdropPath: nil,
                                                overview: result.overview ?? "",
                                                releaseDate: result.releaseDate ?? result.firstAirDate ?? "",
                                                voteAverage: result.voteAverage ?? 0.0,
                                                voteCount: result.voteCount ?? 0,
                                                originalTitle: result.originalTitle
                                            )
                                        }
                                    }
                                }()
                                
                                ForEach(movies) { movie in
                                    Button(action: { selectedMovie = movie }) {
                                        SearchMovieRow(movie: movie)
                                            .padding(.horizontal, 20)
                                    }
                                    Divider()
                                        .background(Color.white.opacity(0.05))
                                        .padding(.leading, 96) // Align with content, past the poster
                                }
                                
                                // People results if applicable
                                let people = viewModel.multiSearchResults.filter { $0.mediaType == .person }
                                if !people.isEmpty && viewModel.selectedScope != .movie {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("PEOPLE")
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.appTextSecondary)
                                            .kerning(1)
                                            .padding(.top, 20)
                                            .padding(.horizontal, 20)
                                        
                                        ForEach(people) { person in
                                            HStack(spacing: 16) {
                                                AsyncImage(url: person.imageURL) { phase in
                                                    if let image = phase.image {
                                                        image.resizable().aspectRatio(contentMode: .fill)
                                                    } else {
                                                        Circle().fill(Color.white.opacity(0.05))
                                                    }
                                                }
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                                
                                                Text(person.displayTitle)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.appText)
                                                
                                                Spacer()
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                            Divider()
                                                .background(Color.white.opacity(0.05))
                                                .padding(.leading, 86)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedMovie) { movie in
            MovieDetailView(movieId: movie.id)
        }
        .task {
            await viewModel.loadTrendingMovies(region: appViewModel.userProfile?.preferredRegion ?? "US")
        }
    }
}

