import SwiftUI
import Combine

struct DirectorDetailView: View {
    let directorId: Int
    let directorName: String
    
    @StateObject private var viewModel = DirectorDetailViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var selectedMovie: Movie?
    @State private var isBioExpanded = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.appBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.appPrimary)
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let detail = viewModel.directorDetail {
                    ScrollView {
                        VStack(spacing: 0) {
                            
                            // 1. Stylish Header with background blur or gradient
                            ZStack(alignment: .bottom) {
                                // Background Backdrop (using profile or a best tagged image if we had it, fallback to profile)
                                if let imagePath = detail.profilePath {
                                    CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(imagePath)")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: 350)
                                            .clipped()
                                            .overlay(Material.ultraThinMaterial) // Glass effect
                                            .opacity(0.6)
                                    } placeholder: {
                                        Rectangle().fill(Color.appBackground).frame(height: 350)
                                    }
                                }
                                
                                LinearGradient(colors: [.clear, .appBackground], startPoint: .top, endPoint: .bottom)
                                    .frame(height: 200)
                                
                                // Profile Image & Name
                                VStack(spacing: 16) {
                                    if let profilePath = detail.profilePath {
                                        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w342\(profilePath)")) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 140, height: 140)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.appPrimary, lineWidth: 3))
                                                .shadow(color: .appPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                                        } placeholder: {
                                            Circle().fill(Color.gray.opacity(0.3)).frame(width: 140, height: 140)
                                        }
                                    }
                                    
                                    VStack(spacing: 4) {
                                        Text(detail.name)
                                            .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 40))
                                            .foregroundColor(.appText)
                                            .shadow(radius: 2)
                                        
                                        Text(detail.knownForDepartment ?? "Director")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                            .foregroundColor(.appPrimary)
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                            .frame(height: 350)
                            
                            VStack(spacing: 24) {
                                // 2. Personal Info Stats (Born, Origin, Age)
                                HStack(spacing: 20) {
                                    if let birthday = detail.birthday {
                                        InfoStatItem(label: "Born", value: formatDate(birthday))
                                        
                                        // Calculate Age
                                        if let age = calculateAge(birthday: birthday, deathday: detail.deathday) {
                                            Divider().frame(height: 30).background(Color.appTextSecondary.opacity(0.3))
                                            InfoStatItem(label: "Age", value: "\(age)")
                                        }
                                    }
                                    
                                    if let place = detail.placeOfBirth {
                                        Divider().frame(height: 30).background(Color.appTextSecondary.opacity(0.3))
                                        InfoStatItem(label: "From", value: place, lineLimit: 1)
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(Color.appCardBackground.opacity(0.5))
                                .cornerRadius(16)
                                .padding(.horizontal, 20)
                                
                                // 3. Biography with Expansion
                                if let bio = detail.biography, !bio.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Biography")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.appText)
                                        
                                        Text(bio)
                                            .font(.system(size: 15))
                                            .foregroundColor(.appTextSecondary)
                                            .lineSpacing(5)
                                            .lineLimit(isBioExpanded ? nil : 4)
                                            .overlay(
                                                LinearGradient(colors: [.clear, .appBackground], startPoint: .top, endPoint: .bottom)
                                                    .opacity(isBioExpanded ? 0 : 1)
                                            )
                                        
                                        Button(action: { withAnimation { isBioExpanded.toggle() } }) {
                                            Text(isBioExpanded ? "Read Less" : "Read More")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.appPrimary)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                
                                // 4. Photos Carousel (Profiles)
                                if let images = detail.images?.profiles, !images.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Photos")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.appText)
                                            .padding(.horizontal, 20)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 12) {
                                                ForEach(images.prefix(10)) { image in
                                                    CachedAsyncImage(url: image.url) { img in
                                                        img
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                    } placeholder: {
                                                        Rectangle().fill(Color.appCardBackground)
                                                    }
                                                    .frame(width: 100, height: 150)
                                                    .cornerRadius(12)
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                }
                                
                                // 5. Filmography Grid
                                if !viewModel.movies.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("Filmography")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.appText)
                                            Spacer()
                                            Text("\(viewModel.movies.count) Movies")
                                                .font(.subheadline)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        .padding(.horizontal, 20)
                                        
                                        LazyVGrid(columns: [
                                            GridItem(.flexible(), spacing: 12),
                                            GridItem(.flexible(), spacing: 12),
                                            GridItem(.flexible(), spacing: 12)
                                        ], spacing: 16) {
                                            ForEach(viewModel.movies) { movie in
                                                Button(action: {
                                                    selectedMovie = movie
                                                }) {
                                                    MovieCardView(movie: movie, width: (geometry.size.width - 64) / 3) // Dynamic width
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                
                                Spacer(minLength: 50)
                            }
                        }
                    }
                }
                
                // Fixed Back Button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Material.thinMaterial)
                        .clipShape(Circle())
                }
                .padding(.top, geometry.safeAreaInsets.top + 8)
                .padding(.leading, 20)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedMovie) { movie in
            MovieDetailView(movieId: movie.id)
        }
        .task {
            await viewModel.loadDirector(id: directorId)
        }
    }
    
    // Helpers
    func formatDate(_ dateString: String) -> String {
        // Simple formatter, ideal would be DateFormatter logic
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return dateString
    }
    
    func calculateAge(birthday: String, deathday: String?) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let birthDate = formatter.date(from: birthday) else { return nil }
        let endDate = deathday != nil ? formatter.date(from: deathday!) : Date()
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: endDate ?? Date())
        return ageComponents.year
    }
}

struct InfoStatItem: View {
    let label: String
    let value: String
    var lineLimit: Int? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.appTextSecondary)
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.appText)
                .lineLimit(lineLimit)
                .minimumScaleFactor(0.8)
        }
    }
}

@MainActor
class DirectorDetailViewModel: ObservableObject {
    @Published var directorDetail: PersonDetail?
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    
    func loadDirector(id: Int) async {
        isLoading = true
        
        do {
            async let detailTask = TMDBService.shared.fetchPersonDetails(id: id)
            async let moviesTask = TMDBService.shared.fetchPersonMovieCredits(id: id)
            
            let (detail, movieList) = try await (detailTask, moviesTask)
            
            self.directorDetail = detail
            self.movies = movieList
        } catch {
            print("Error loading director: \(error)")
        }
        
        isLoading = false
    }
}

