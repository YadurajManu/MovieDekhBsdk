import SwiftUI

struct DirectorSectionView: View {
    let directorId: Int
    let directorName: String
    let directorPhotoURL: URL?
    let movies: [Movie]
    let onMovieTap: (Movie) -> Void
    @State private var showDirectorDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Director Header
            HStack(spacing: 12) {
                Button(action: { showDirectorDetail = true }) {
                    CachedAsyncImage(url: directorPhotoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.appPrimary, lineWidth: 2)
                    )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(directorName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)
                    
                    Text("Director")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                Button(action: { showDirectorDetail = true }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(.horizontal, 24)
            
            // Movies Horizontal Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(movies.prefix(8)) { movie in
                        Button(action: { onMovieTap(movie) }) {
                            MovieCardView(movie: movie, width: 120)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .fullScreenCover(isPresented: $showDirectorDetail) {
            DirectorDetailView(directorId: directorId, directorName: directorName)
        }
    }
}
