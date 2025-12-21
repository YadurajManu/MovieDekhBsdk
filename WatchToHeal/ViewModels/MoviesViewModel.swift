//
//  MoviesViewModel.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import Foundation
import Combine

@MainActor
class MoviesViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadTopMovies() async {
        isLoading = true
        errorMessage = nil
        
        do {
            movies = try await TMDBService.shared.fetchTopMovies()
        } catch {
            errorMessage = "Failed to load movies: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
