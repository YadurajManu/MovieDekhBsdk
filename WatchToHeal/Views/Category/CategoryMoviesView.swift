import SwiftUI

struct CategoryMoviesView: View {
    let title: String
    let movies: [Movie]
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedMovie: Movie?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    Text(title)
                        .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 32))
                        .foregroundColor(.appText)
                        .padding(.top, 80)
                    
                    // Movies Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 16) {
                        ForEach(movies) { movie in
                            Button(action: {
                                selectedMovie = movie
                            }) {
                                MovieCardView(movie: movie, width: 110)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            
            // Fixed Back Button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(.top, 50)
            .padding(.leading, 16)
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedMovie) { movie in
            MovieDetailView(movieId: movie.id)
        }
    }
}
