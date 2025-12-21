//
//  MainTabView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: TabItem = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .calendar:
                    UpcomingCalendarView()
                case .search:
                    SearchView()
                case .community:
                    CommunityView()
                case .watchlist:
                    WatchlistView(selectedTab: $selectedTab)
                case .profile:
                    ProfileView()
                }
            }
            
            // Custom Tab Bar - WhatsApp Style
            HStack(spacing: 8) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .appBackground : .appTextSecondary)
                            
                            Text(tab.rawValue)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .appBackground : .appTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedTab == tab ?
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.appPrimary)
                            : nil
                        )
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    // Glassmorphism effect
                    Color.black.opacity(0.5)
                    
                    // Blur effect
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.9)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .shadow(color: .black.opacity(0.3), radius: 15, y: -5)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// Placeholder views for other tabs
struct SearchPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("Search")
                .foregroundColor(.appText)
                .font(.title)
        }
    }
}

struct WatchlistPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("Watchlist")
                .foregroundColor(.appText)
                .font(.title)
        }
    }
}

struct ProfilePlaceholderView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("Profile")
                .foregroundColor(.appText)
                .font(.title)
        }
    }
}

#Preview {
    MainTabView()
}
