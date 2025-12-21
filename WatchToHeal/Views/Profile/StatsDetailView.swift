import SwiftUI

struct StatsDetailView: View {
    @StateObject private var historyManager = HistoryManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        
                        Text("DETAILED ANALYSIS")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.appTextSecondary)
                            .kerning(2)
                            .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Total Watch Time Card
                    GlassCard(cornerRadius: 30) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("TOTAL WATCH TIME")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.appTextSecondary)
                                    .kerning(1)
                                
                                Spacer()
                                
                                Image(systemName: "timer")
                                    .foregroundColor(.appPrimary)
                                    .font(.system(size: 20))
                            }
                            
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(historyManager.formattedWatchTime)
                                    .font(.system(size: 48, weight: .black))
                                    .foregroundColor(.white)
                                
                                Text("LIFETIME")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.appPrimary)
                            }
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.appPrimary)
                                    .frame(width: 6, height: 6)
                                
                                Text("Across \(historyManager.moviesWatchedCount) cinematic experiences")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 20)
                    
                    // Time of Day Analysis
                    VStack(alignment: .leading, spacing: 20) {
                        Text("WATCHING PATTERNS")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.appTextSecondary)
                            .kerning(1)
                            .padding(.horizontal, 24)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            TimeStatCard(icon: "sun.max.fill", title: "MORNING", count: historyManager.timeOfDayStats["Morning"] ?? 0)
                            TimeStatCard(icon: "sun.min.fill", title: "AFTERNOON", count: historyManager.timeOfDayStats["Afternoon"] ?? 0)
                            TimeStatCard(icon: "sunset.fill", title: "EVENING", count: historyManager.timeOfDayStats["Evening"] ?? 0)
                            TimeStatCard(icon: "moon.stars.fill", title: "NIGHT", count: historyManager.timeOfDayStats["Night"] ?? 0)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Top Genres
                    VStack(alignment: .leading, spacing: 20) {
                        Text("GENRE FOCUS")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.appTextSecondary)
                            .kerning(1)
                            .padding(.horizontal, 24)
                        
                        GlassCard(cornerRadius: 30) {
                            VStack(spacing: 24) {
                                let sortedGenres = historyManager.genreDistribution.sorted(by: { $0.value > $1.value }).prefix(5)
                                
                                ForEach(Array(sortedGenres), id: \.key) { key, value in
                                    GenreRow(genre: key, count: value, total: historyManager.moviesWatchedCount)
                                }
                                
                                if sortedGenres.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "film.stack")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white.opacity(0.1))
                                        Text("No data yet. Start watching!")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    .padding(.vertical, 40)
                                }
                            }
                            .padding(24)
                        }
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
        GlassCard(cornerRadius: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.appPrimary)
                        .shadow(color: .appPrimary.opacity(0.5), radius: 4)
                }
                
                VStack(spacing: 4) {
                    Text("\(count)")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.appTextSecondary)
                        .kerning(1)
                }
            }
            .padding(.vertical, 24)
        }
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
        VStack(spacing: 12) {
            HStack {
                Text(genre.uppercased())
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                    .kerning(1)
                
                Spacer()
                
                Text("\(count) MOVIES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.appPrimary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.appPrimary, .appPrimary.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .shadow(color: .appPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .frame(height: 8)
        }
    }
}
