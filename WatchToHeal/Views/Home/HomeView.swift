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
    @State private var selectedCategory: MovieCategory?
    @State private var showRecommendations = false
    
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
                    ScrollView {
                        VStack(spacing: 0) {
                            
                            // Hero Carousel (Trending)
                            if !viewModel.tradingMovies.isEmpty {
                                TabView {
                                    ForEach(viewModel.tradingMovies.prefix(5)) { movie in
                                        Button(action: {
                                            selectedMovie = movie
                                        }) {
                                            HeroMovieCard(movie: movie, onDetailsTap: {
                                                selectedMovie = movie
                                            })
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                                .frame(height: 480)
                                .ignoresSafeArea(edges: .top)
                            }
                            
                            VStack(spacing: 32) {
                                
                                // Personalized Recommendations Section
                                if !viewModel.personalizedRecommendations.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack(alignment: .bottom) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("PERSONALIZED")
                                                    .font(.system(size: 11, weight: .black))
                                                    .tracking(1.5)
                                                    .foregroundColor(.appPrimary)
                                                
                                                Text("For You")
                                                    .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 32))
                                                    .foregroundColor(.appText)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: { showRecommendations = true }) {
                                                Text("See All")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.appPrimary)
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(viewModel.personalizedRecommendations.prefix(10)) { movie in
                                                    Button(action: { selectedMovie = movie }) {
                                                        MovieCardView(movie: movie)
                                                            .frame(width: 150, height: 260)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                            .padding(.horizontal, 24)
                                        }
                                    }
                                    .padding(.top, 16)
                                }
                                
                                // Now Playing
                                if !viewModel.nowPlaying.isEmpty {
                                    MovieSectionView(title: "New Releases", movies: viewModel.nowPlaying) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .nowPlaying
                                    }
                                }
                                
                                // Director Sections
                                ForEach(viewModel.famousDirectors.prefix(3), id: \.id) { director in
                                    if let detail = viewModel.directorDetails[director.id],
                                       let movies = viewModel.directorMovies[director.id],
                                       !movies.isEmpty {
                                        DirectorSectionView(
                                            directorId: director.id,
                                            directorName: detail.name,
                                            directorPhotoURL: URL(string: "https://image.tmdb.org/t/p/w185\(detail.profilePath ?? "")"),
                                            movies: movies,
                                            onMovieTap: { movie in
                                                selectedMovie = movie
                                            }
                                        )
                                    }
                                }
                                
                                // Action Movies
                                if !viewModel.actionMovies.isEmpty {
                                    MovieSectionView(title: "Action Packed", movies: viewModel.actionMovies) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .action
                                    }
                                }
                                
                                // Crime & Mystery
                                if !viewModel.crimeMovies.isEmpty || !viewModel.mysteryMovies.isEmpty {
                                    MovieSectionView(title: "Crime & Mystery", movies: viewModel.crimeMovies + viewModel.mysteryMovies) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .crime
                                    }
                                }
                                
                                // Adventure
                                if !viewModel.adventureMovies.isEmpty {
                                    MovieSectionView(title: "Adventure & Quest", movies: viewModel.adventureMovies) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .adventure
                                    }
                                }
                                
                                // Horror Movies
                                if !viewModel.horrorMovies.isEmpty {
                                    MovieSectionView(title: "Horror & Suspense", movies: viewModel.horrorMovies) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .horror
                                    }
                                }
                                
                                // Sci-Fi Movies
                                if !viewModel.sciFiMovies.isEmpty {
                                    MovieSectionView(title: "Sci-Fi & Fantasy", movies: viewModel.sciFiMovies) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .sciFi
                                    }
                                }
                                
                                // Thriller Movies
                                if !viewModel.thrillerMovies.isEmpty {
                                    MovieSectionView(title: "Thrillers", movies: viewModel.thrillerMovies) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .thriller
                                    }
                                }
                                
                                // Comedy Movies
                                if !viewModel.comedyMovies.isEmpty {
                                    MovieSectionView(title: "Comedy Hits", movies: viewModel.comedyMovies) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .comedy
                                    }
                                }
                                
                                // Romance Movies
                                if !viewModel.romanceMovies.isEmpty {
                                    MovieSectionView(title: "Romance & Love Stories", movies: viewModel.romanceMovies) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .romance
                                    }
                                }
                                
                                // Animation Movies
                                if !viewModel.animationMovies.isEmpty {
                                    MovieSectionView(title: "Animated Favorites", movies: viewModel.animationMovies) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .animation
                                    }
                                }
                                
                                // Upcoming
                                if !viewModel.upcoming.isEmpty {
                                    MovieSectionView(title: "Coming Soon", movies: viewModel.upcoming) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .upcoming
                                    }
                                }
                                
                                // Top Rated
                                if !viewModel.topRated.isEmpty {
                                    MovieSectionView(title: "Critically Acclaimed", movies: viewModel.topRated) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .topRated
                                    }
                                }
                                
                                // Drama Movies
                                if !viewModel.dramaMovies.isEmpty {
                                    MovieSectionView(title: "Dramatic Stories", movies: viewModel.dramaMovies) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .drama
                                    }
                                }
                                
                                // War & History
                                if !viewModel.warMovies.isEmpty {
                                    MovieSectionView(title: "War & History", movies: viewModel.warMovies) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .war
                                    }
                                }
                                
                                // WORLD CINEMA SECTIONS
                                Group {
                                    if !viewModel.japaneseMasterpieces.isEmpty {
                                        MovieSectionView(title: "🇯🇵 Japanese Masterpieces", movies: viewModel.japaneseMasterpieces) { movie in
                                            selectedMovie = movie
                                        } onSeeAllTap: {
                                            selectedCategory = .japaneseMasterpieces
                                        }
                                    }
                                    
                                    if !viewModel.koreanMasterpieces.isEmpty {
                                        MovieSectionView(title: "🇰🇷 Korean Thrillers & Dramas", movies: viewModel.koreanMasterpieces) { movie in
                                            selectedMovie = movie
                                        } onSeeAllTap: {
                                            selectedCategory = .koreanMasterpieces
                                        }
                                    }
                                    
                                    if !viewModel.frenchMasterpieces.isEmpty {
                                        MovieSectionView(title: "🇫🇷 French Cinema", movies: viewModel.frenchMasterpieces) { movie in
                                            selectedMovie = movie
                                        } onSeeAllTap: {
                                            selectedCategory = .frenchCinema
                                        }
                                    }
                                    
                                    if !viewModel.indianMasterpieces.isEmpty {
                                        MovieSectionView(title: "🇮🇳 Indian Classics", movies: viewModel.indianMasterpieces) { movie in
                                            selectedMovie = movie
                                        } onSeeAllTap: {
                                            selectedCategory = .indianClassics
                                        }
                                    }
                                }
                                
                                // STREAMING SERVICES
                                Group {
                                    if !viewModel.netflixMovies.isEmpty {
                                        MovieSectionView(title: "New on Netflix", movies: viewModel.netflixMovies) { movie in
                                            selectedMovie = movie
                                        } onSeeAllTap: {
                                            selectedCategory = .netflix
                                        }
                                    }
                                    
                                    if !viewModel.disneyMovies.isEmpty {
                                        MovieSectionView(title: "New on Disney+", movies: viewModel.disneyMovies) { movie in
                                            selectedMovie = movie
                                        } onSeeAllTap: {
                                            selectedCategory = .disney
                                        }
                                    }
                                    
                                    if !viewModel.amazonMovies.isEmpty {
                                        MovieSectionView(title: "New on Amazon Prime", movies: viewModel.amazonMovies) { movie in
                                            selectedMovie = movie
                                        } onSeeAllTap: {
                                            selectedCategory = .amazon
                                        }
                                    }
                                    
                                    if !viewModel.appleTVMovies.isEmpty {
                                        MovieSectionView(title: "New on Apple TV+", movies: viewModel.appleTVMovies) { movie in
                                            selectedMovie = movie
                                        } onSeeAllTap: {
                                            selectedCategory = .appleTV
                                        }
                                    }
                                }
                                
                                // Documentary Movies
                                if !viewModel.documentaryMovies.isEmpty {
                                    MovieSectionView(title: "Documentaries", movies: viewModel.documentaryMovies) { movie in
                                        selectedMovie = movie
                                    } onSeeAllTap: {
                                        selectedCategory = .documentary
                                    }
                                }
                            }
                            .padding(.vertical, 24)
                            .padding(.bottom, 120) // Increased padding for bottom tab bar
                        }
                    }
                    .ignoresSafeArea(edges: .top) // Keep top hero effect
                    .refreshable {
                        await viewModel.loadAllMovies(region: appViewModel.userProfile?.preferredRegion ?? "US")
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedMovie) { movie in
            MovieDetailView(movieId: movie.id)
        }
        .fullScreenCover(item: $selectedCategory) { category in
            CategoryView(category: category)
        }
        .fullScreenCover(isPresented: $showRecommendations) {
            RecommendationsView(viewModel: viewModel)
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadAllMovies(region: appViewModel.userProfile?.preferredRegion ?? "US")
        }
    }
}

#Preview {
    HomeView()
}
