import SwiftUI

struct StatsDetailView: View {
    @StateObject private var historyManager = HistoryManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.appCardBackground)
                                .clipShape(Circle())
                        }
                        
                        Text("Detailed Analysis")
                            .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 28))
                            .foregroundColor(.appText)
                            .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Total Watch Time Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Total Watch Time")
                            .font(.headline)
                            .foregroundColor(.appTextSecondary)
                        
                        HStack(alignment: .bottom, spacing: 12) {
                            Text(historyManager.formattedWatchTime)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.appPrimary)
                            
                            Text("Lifetime")
                                .font(.subheadline)
                                .foregroundColor(.appTextSecondary)
                                .padding(.bottom, 6)
                        }
                        
                        Text("Across \(historyManager.moviesWatchedCount) movies")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.appCardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Time of Day Analysis
                    VStack(alignment: .leading, spacing: 20) {
                        Text("When You Watch")
                            .font(.headline)
                            .foregroundColor(.appText)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 12) {
                            TimeStatCard(icon: "sun.max.fill", title: "Morning", count: historyManager.timeOfDayStats["Morning"] ?? 0)
                            TimeStatCard(icon: "sun.min.fill", title: "Afternoon", count: historyManager.timeOfDayStats["Afternoon"] ?? 0)
                        }
                        .padding(.horizontal, 20)
                        
                        HStack(spacing: 12) {
                            TimeStatCard(icon: "sunset.fill", title: "Evening", count: historyManager.timeOfDayStats["Evening"] ?? 0)
                            TimeStatCard(icon: "moon.stars.fill", title: "Night", count: historyManager.timeOfDayStats["Night"] ?? 0)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Top Genres
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Genre Breakdown")
                            .font(.headline)
                            .foregroundColor(.appText)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            let sortedGenres = historyManager.genreDistribution.sorted(by: { $0.value > $1.value }).prefix(5)
                            
                            ForEach(Array(sortedGenres), id: \.key) { key, value in
                                GenreRow(genre: key, count: value, total: historyManager.moviesWatchedCount)
                            }
                            
                            if sortedGenres.isEmpty {
                                Text("No data yet. Start watching!")
                                    .foregroundColor(.appTextSecondary)
                                    .padding()
                            }
                        }
                        .padding(20)
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct TimeStatCard: View {
    let icon: String
    let title: String
    let count: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.appPrimary)
            
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.appText)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
}

struct GenreRow: View {
    let genre: String
    let count: Int
    let total: Int
    
    var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(genre)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.appText)
                
                Spacer()
                
                Text("\(count) movies")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appBackground)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appPrimary)
                        .frame(width: geometry.size.width * percentage, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
