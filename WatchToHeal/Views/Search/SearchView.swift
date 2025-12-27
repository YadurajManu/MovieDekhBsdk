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
    @State private var selectedSeries: Movie?
    @State private var selectedTrailer: TMDBService.MovieTrailer?
    @State private var selectedActorId: IdentifiableInt?
    @State private var discoveryTab = 0 // 0: Staff Picks, 1: Collections
    @Namespace private var discoveryNamespace
    
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
                                if !viewModel.latestTrailers.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("LATEST TRAILERS")
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.appTextSecondary)
                                            .kerning(1)
                                            .padding(.horizontal, 20)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 20) {
                                                ForEach(viewModel.latestTrailers) { trailer in
                                                    Button(action: { 
                                                        viewModel.searchQuery = "" // Clear keyboard/focus
                                                        selectedTrailer = trailer 
                                                    }) {
                                                        TrailerCard(trailer: trailer)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                }
                                
                                // Discovery Switcher
                                discoverySwitcher
                                
                                if discoveryTab == 0 {
                                    // Staff Picks (Movies)
                                    if !viewModel.staffPicks.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(viewModel.staffPicks) { movie in
                                                    Button(action: { selectedMovie = movie }) {
                                                        MovieCardView(movie: movie, width: 140)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                                    }
                                } else {
                                    // Featured Collections (Lists)
                                    if !viewModel.featuredLists.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 20) {
                                                ForEach(viewModel.featuredLists) { list in
                                                    NavigationLink(destination: ListDetailView(list: list)) {
                                                        StaffPickCard(list: list)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                                    }
                                }
                                
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
                                        HStack {
                                            Text("TRENDING")
                                                .font(.system(size: 14, weight: .black))
                                                .foregroundColor(.appTextSecondary)
                                                .kerning(1)
                                            
                                            Spacer()
                                            
                                            // Premium Window Toggle
                                            HStack(spacing: 0) {
                                                ForEach(["day", "week"], id: \.self) { window in
                                                    Button(action: {
                                                        if viewModel.trendingTimeWindow != window {
                                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                                viewModel.trendingTimeWindow = window
                                                                Task {
                                                                    await viewModel.loadTrendingMovies(region: appViewModel.userProfile?.preferredRegion ?? "US")
                                                                }
                                                            }
                                                        }
                                                    }) {
                                                        Text(window == "day" ? "TODAY" : "THIS WEEK")
                                                            .font(.system(size: 10, weight: .black))
                                                            .padding(.horizontal, 12)
                                                            .padding(.vertical, 6)
                                                            .background(
                                                                viewModel.trendingTimeWindow == window
                                                                ? Color.appPrimary
                                                                : Color.clear
                                                            )
                                                            .foregroundColor(
                                                                viewModel.trendingTimeWindow == window
                                                                ? .black
                                                                : .appTextSecondary
                                                            )
                                                            .cornerRadius(8)
                                                    }
                                                }
                                            }
                                            .padding(2)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(10)
                                        }
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
                                            let isMovie = result.mediaType == .movie
                                            return Movie(
                                                id: result.id,
                                                title: isMovie ? result.displayTitle : nil,
                                                name: result.mediaType == .tv ? result.displayTitle : nil,
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
                                    Button(action: { 
                                        if movie.title != nil {
                                            selectedMovie = movie 
                                        } else {
                                            selectedSeries = movie
                                        }
                                    }) {
                                        SearchMovieRow(movie: movie)
                                            .padding(.horizontal, 20)
                                    }
                                    Divider()
                                        .background(Color.white.opacity(0.05))
                                        .padding(.leading, 96) // Align with content, past the poster
                                }
                                
                                // People results if applicable
                                let people = viewModel.multiSearchResults.filter { $0.mediaType == .person }
                                if !people.isEmpty && viewModel.selectedScope != .movie && viewModel.selectedScope != .tv {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("PEOPLE")
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.appTextSecondary)
                                            .kerning(1)
                                            .padding(.top, 20)
                                            .padding(.horizontal, 20)
                                        
                                        ForEach(people) { person in
                                            Button(action: { selectedActorId = IdentifiableInt(id: person.id) }) {
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
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
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
        .fullScreenCover(item: $selectedSeries) { series in
            SeriesDetailView(seriesId: series.id)
        }
        .fullScreenCover(item: $selectedActorId) { wrapper in
            ActorDetailView(actorId: wrapper.id)
        }
        .sheet(item: $selectedTrailer) { trailer in
            YouTubeView(videoID: trailer.youtubeKey)
        }
        .onAppear {
            print("🔍 SearchView appeared")
            print("📊 Trending movies count: \(viewModel.trendingMovies.count)")
            print("🎬 Trailers count: \(viewModel.latestTrailers.count)")
            print("⭐ Featured lists count: \(viewModel.featuredLists.count)")
            
            // Reload data if empty
            if viewModel.trendingMovies.isEmpty || viewModel.latestTrailers.isEmpty {
                print("📥 Loading trending data...")
                Task {
                    await viewModel.loadTrendingMovies()
                    print("✅ Loaded - Trending: \(viewModel.trendingMovies.count), Trailers: \(viewModel.latestTrailers.count)")
                }
            }
        }
    }
    
    private var discoverySwitcher: some View {
        HStack(spacing: 8) {
            discoveryTabButton(title: "STAFF PICKS", index: 0)
            discoveryTabButton(title: "COLLECTIONS", index: 1)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
    
    private func discoveryTabButton(title: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                discoveryTab = index
            }
        }) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .tracking(1)
                .foregroundColor(discoveryTab == index ? .black : .appTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    ZStack {
                        if discoveryTab == index {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appPrimary)
                                .matchedGeometryEffect(id: "discovery_tab", in: discoveryNamespace)
                        }
                    }
                )
        }
    }
}

struct StaffPickCard: View {
    let list: CommunityList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Stacked Posters
            ZStack(alignment: .bottomTrailing) {
                // Background shadow glow
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 140, height: 210)
                    .blur(radius: 12)
                    .offset(y: 8)
                
                // Poster Stack
                ForEach(Array(list.movies.prefix(3).enumerated()), id: \.offset) { index, movie in
                    if let url = movie.posterURL {
                        CachedAsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12).fill(Color.appCardBackground)
                        }
                        .frame(width: 130, height: 195)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        .offset(x: CGFloat(index) * -12, y: CGFloat(index) * -10)
                        .scaleEffect(1.0 - CGFloat(index) * 0.05)
                        .zIndex(Double(3 - index))
                    }
                }
            }
            .padding(.leading, 24) // Offset for the stack effect
            
            VStack(alignment: .leading, spacing: 4) {
                Text(list.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appText)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 10))
                    Text(list.ownerName)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.appTextSecondary)
            }
            .padding(.leading, 12)
        }
    }
}

