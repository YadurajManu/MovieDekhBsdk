//
//  MovieSectionView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

struct MovieSectionView: View {
    let title: String
    let movies: [Movie]
    let onMovieTap: (Movie) -> Void
    let onSeeAllTap: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(alignment: .lastTextBaseline) {
                Text(title)
                    .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 28))
                    .foregroundColor(.appText)
                
                Spacer()
                
                Button(action: {
                    onSeeAllTap()
                }) {
                    Text("See All")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(.horizontal, 20)
            
            // Horizontal Scrolling Movies
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(movies.prefix(20)) { movie in
                        Button(action: {
                            onMovieTap(movie)
                        }) {
                            MovieCardView(movie: movie, width: 120)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
