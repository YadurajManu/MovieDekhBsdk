import SwiftUI

struct CommunityListCard: View {
    let list: CommunityList
    
    var body: some View {
        HStack(spacing: 16) {
            // Stacked Poster Preview
            ZStack {
                if list.movies.count >= 3 {
                    moviePoster(at: 2, offset: 8, scale: 0.85, opacity: 0.3)
                    moviePoster(at: 1, offset: 4, scale: 0.92, opacity: 0.6)
                }
                moviePoster(at: 0, offset: 0, scale: 1.0, opacity: 1.0)
            }
            .frame(width: 50, height: 75)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(list.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appText)
                        .lineLimit(1)
                    
                    if list.isRanked {
                        Text("RANKED")
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appPrimary.opacity(0.1))
                            .foregroundColor(.appPrimary)
                            .cornerRadius(4)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    if list.isFeatured {
                        HStack(spacing: 3) {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 7))
                            Text("STAFF PICK")
                        }
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }
                
                Text(list.ownerName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appPrimary)
                
                if !list.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(list.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.appTextSecondary.opacity(0.6))
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "film")
                        Text("\(list.movies.count)")
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                        Text("\(list.likeCount)")
                    }
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.appTextSecondary.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(.appTextSecondary.opacity(0.3))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
    
    @ViewBuilder
    private func moviePoster(at index: Int, offset: CGFloat, scale: CGFloat, opacity: Double) -> some View {
        if list.movies.indices.contains(index) {
            let movie = list.movies[index]
            if let url = movie.posterURL {
                CachedAsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6).fill(Color.appCardBackground)
                }
                .frame(width: 40, height: 60)
                .cornerRadius(6)
                .offset(x: offset)
                .scaleEffect(scale)
                .opacity(opacity)
                .shadow(radius: 2)
            }
        }
    }
}
