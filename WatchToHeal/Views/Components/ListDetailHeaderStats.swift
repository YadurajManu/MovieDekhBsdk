import SwiftUI

struct ListDetailHeaderStats: View {
    let movies: [Movie]
    
    var body: some View {
        HStack(spacing: 20) {
            statItem(icon: "clock", value: totalRuntimeFormatted)
            statItem(icon: "star.fill", value: averageRatingFormatted, iconColor: .appPrimary)
            statItem(icon: "film", value: topGenresFormatted)
        }
    }
    
    private func statItem(icon: String, value: String, iconColor: Color = .white) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(iconColor.opacity(0.8))
            
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.appTextSecondary)
        }
    }
    
    // MARK: - Calculations
    
    private var totalRuntimeFormatted: String {
        let totalMinutes = movies.compactMap { $0.runtime }.reduce(0, +)
        guard totalMinutes > 0 else { return "--" }
        
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var averageRatingFormatted: String {
        let ratings = movies.map { $0.voteAverage }.filter { $0 > 0 }
        guard !ratings.isEmpty else { return "--" }
        
        let average = ratings.reduce(0, +) / Double(ratings.count)
        return String(format: "%.1f Avg", average)
    }
    
    private var topGenresFormatted: String {
        let allGenres = movies.compactMap { $0.genres }.flatMap { $0 }
        let counts = allGenres.reduce(into: [String: Int]()) { $0[$1.name, default: 0] += 1 }
        
        let sortedGenres = counts.sorted { $0.value > $1.value }
            .prefix(2)
            .map { $0.key }
        
        if sortedGenres.isEmpty { return "Multiple" }
        return sortedGenres.joined(separator: " • ")
    }
}
