//
//  MoviePosterView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

struct MoviePosterView: View {
    let movie: Movie
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster Image
            AsyncImage(url: movie.posterURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            Image(systemName: "film")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.title)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Movie Title
            Text(movie.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Year and Rating
            HStack(spacing: 8) {
                Text(movie.year)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text(movie.rating)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
}
