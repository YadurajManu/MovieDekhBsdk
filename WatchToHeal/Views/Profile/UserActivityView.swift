import SwiftUI

struct UserActivityView: View {
    @StateObject private var viewModel: ActivityViewModel
    @Environment(\.dismiss) var dismiss
    
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: ActivityViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.appText)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.05)))
                    }
                    
                    Spacer()
                    
                    Text("MY ACTIVITY")
                        .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 28))
                        .foregroundColor(.appText)
                    
                    Spacer()
                    
                    // Placeholder for balance
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Overview
                        StatsDashboard(stats: viewModel.stats, streakMessage: viewModel.streakMessage())
                            .padding(.horizontal, 20)
                        
                        // Filters
                        ActivityFilters(selectedFilter: $viewModel.selectedFilter)
                            .padding(.horizontal, 20)
                        
                        // Activity Feed
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.appPrimary)
                                .padding(.top, 40)
                        } else if viewModel.filteredActivities.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.1))
                                Text("No activity found yet")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(.top, 60)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredActivities) { activity in
                                    ActivityRow(activity: activity)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadData()
        }
    }
}

struct StatsDashboard: View {
    let stats: UserStats
    let streakMessage: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Streak Section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ENGAGEMENT STREAK")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.appPrimary)
                        .kerning(1)
                    
                    Text(streakMessage)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appText)
                }
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.appPrimary.opacity(0.1), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Text("\(stats.currentStreak)")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.appPrimary)
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.03))
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.05), lineWidth: 1))
            
            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(title: "RATINGS", value: "\(stats.totalRatings)", icon: "star.fill", color: .appPrimary)
                StatCard(title: "COMMENTS", value: "\(stats.totalComments + stats.totalReplies)", icon: "bubble.left.fill", color: .blue)
                StatCard(title: "LIKES GIVEN", value: "\(stats.totalLikes)", icon: "heart.fill", color: .red)
                StatCard(title: "MAX STREAK", value: "\(stats.longestStreak)", icon: "trophy.fill", color: .orange)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.appText)
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.appText.opacity(0.4))
                    .kerning(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.03))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}

struct ActivityFilters: View {
    @Binding var selectedFilter: ActivityType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(title: "ALL", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                
                FilterChip(title: "RATINGS", isSelected: selectedFilter == .rating) {
                    selectedFilter = .rating
                }
                
                FilterChip(title: "COMMENTS", isSelected: selectedFilter == .comment || selectedFilter == .reply) {
                    selectedFilter = .comment // Simplified mapping for UI
                }
                
                FilterChip(title: "LIKES", isSelected: selectedFilter == .like) {
                    selectedFilter = .like
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(isSelected ? .black : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.appPrimary : Color.white.opacity(0.05))
                .cornerRadius(12)
        }
    }
}

struct ActivityRow: View {
    let activity: UserActivity
    
    var body: some View {
        HStack(spacing: 16) {
            // Movie Poster
            if let poster = activity.moviePoster {
                AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w200\(poster)")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.white.opacity(0.05)
                }
                .frame(width: 50, height: 75)
                .cornerRadius(8)
            } else {
                Color.white.opacity(0.05)
                    .frame(width: 50, height: 75)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    ActivityIcon(type: activity.type)
                    Text(activity.movieTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appText)
                        .lineLimit(1)
                    Spacer()
                    Text(activity.timestamp.timeAgoDisplay())
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                }
                
                if let content = activity.content, !content.isEmpty {
                    Text(content)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                } else if let rating = activity.rating {
                    RatingBadge(rating: rating)
                } else if activity.type == .like {
                    Text("Liked a review")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.02))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.04), lineWidth: 1))
    }
}

struct ActivityIcon: View {
    let type: ActivityType
    
    var body: some View {
        let (icon, color) = info
        Image(systemName: icon)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .frame(width: 20, height: 20)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }
    
    var info: (String, Color) {
        switch type {
        case .rating: return ("star.fill", .appPrimary)
        case .comment: return ("bubble.left.fill", .blue)
        case .reply: return ("arrowshape.turn.up.left.fill", .blue)
        case .like: return ("heart.fill", .red)
        }
    }
}

struct RatingBadge: View {
    let rating: String
    
    var body: some View {
        Text(labelForRating(rating))
            .font(.system(size: 9, weight: .black))
            .foregroundColor(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(4)
    }
    
    var color: Color {
        switch rating.lowercased() {
        case "absolute": return .green
        case "awaara": return .orange
        case "bakwas": return .red
        default: return .appPrimary
        }
    }
    
    private func labelForRating(_ rating: String) -> String {
        switch rating.lowercased() {
        case "absolute": return "GOFORIT"
        case "awaara": return "SOSO"
        case "bakwas": return "BAKWAS"
        default: return rating.uppercased()
        }
    }
}

