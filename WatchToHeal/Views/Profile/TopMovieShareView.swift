import SwiftUI

struct TopMovieShareView: View {
    let userName: String
    let topMovies: [Movie]
    
    var body: some View {
        ZStack {
            // Background: Mesh Gradient
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                .black, .black, .black,
                Color(hex: "1A1A1A"), Color.appPrimary.opacity(0.3), Color(hex: "0D0D0D"),
                Color.appPrimary.opacity(0.15), .black, .black
            ])
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Branding
                VStack(spacing: 8) {
                    Text("WatchToHeal")
                        .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 48))
                        .foregroundColor(.appPrimary)
                    
                    Text("\(userName)'s All-Time Favorites")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 60)
                
                // Top 3 Movies
                VStack(spacing: 30) {
                    ForEach(Array(topMovies.prefix(3).enumerated()), id: \.offset) { index, movie in
                        HStack(spacing: 20) {
                            // Rank Number
                            Text("\(index + 1)")
                                .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 64))
                                .foregroundColor(.appPrimary.opacity(0.5))
                                .frame(width: 40)
                            
                            // Poster
                            CachedAsyncImage(url: movie.posterURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            }
                            .frame(width: 100, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(movie.displayName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.appPrimary)
                                    Text(movie.rating)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("•")
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    Text(movie.year)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                    }
                }
                
                Spacer()
                
                // Footer
                VStack(spacing: 4) {
                    Image(systemName: "film.stack.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.appPrimary)
                    Text("Track your healing journey with cinema")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 60)
            }
        }
        .frame(width: 400, height: 711) // Standard 9:16 aspect ratio relative to width
    }
}
