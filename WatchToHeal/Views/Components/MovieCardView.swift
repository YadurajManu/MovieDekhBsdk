//
//  MovieCardView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    let width: CGFloat?

    init(movie: Movie, width: CGFloat? = nil) {
        self.movie = movie
        self.width = width
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Movie Poster
            CachedAsyncImage(url: movie.posterURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay {
                        ProgressView()
                            .tint(.appPrimary)
                    }
            }
            .frame(width: width, height: width != nil ? width! * 1.5 : nil)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
            
            // Movie Info
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(movie.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.appText)
                    .lineLimit(1)
                
                // Rating and Year
                HStack(spacing: 8) {
                    PremiumRatingBadge(rating: movie.voteAverage, size: .small)
                    
                    Text(movie.year)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(width: width)
    }
}
