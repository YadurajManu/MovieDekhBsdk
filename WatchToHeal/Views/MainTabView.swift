//
//  MainTabView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

//
//  MainTabView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: TabItem = .home
    @Namespace private var animation
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content Layer
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Floating Liquid Glass Tab Bar
            ZStack {
                // Blur Background with Glass Effect
                LiquidGlassBackground()
                
                // Tab Items
                HStack(spacing: 0) {
                    ForEach(TabItem.allCases, id: \.self) { tab in
                        TabButton(tab: tab, selectedTab: $selectedTab, namespace: animation)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20) // Floating from bottom
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark) // Enforce dark mode vibe for premium feel
    }
}

// MARK: - Tab Button Component
struct TabButton: View {
    let tab: TabItem
    @Binding var selectedTab: TabItem
    var namespace: Namespace.ID
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            ZStack {
                // Animated Selection Pill
                if isSelected {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary.opacity(0.15), Color.appPrimary.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.appPrimary.opacity(0.6), Color.appPrimary.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                        .matchedGeometryEffect(id: "SelectionPill", in: namespace)
                }
                
                // Icon
                Image(systemName: isSelected ? tab.selectedIcon : tab.unselectedIcon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(
                        isSelected ?
                        AnyShapeStyle(
                            LinearGradient(colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                        ) :
                        AnyShapeStyle(Color.white.opacity(0.6))
                    )
                    .scaleEffect(isSelected ? 1.0 : 0.9)
                    .offset(y: isSelected ? -2 : 0) // Subtle lift
            }
            .frame(height: 50) // Tappable Area
            .contentShape(Rectangle()) // Better tap target
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Liquid Glass Background
struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {
            // 1. Ultra Thin Material Base
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.9) // Slightly reduce material opacity itself
            
            // White Overlay REMOVED for more translucency
            
            // 3. Gradient Stroke Border
            RoundedRectangle(cornerRadius: 32)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.4),
                            .white.opacity(0.1),
                            .white.opacity(0.05),
                            .white.opacity(0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10) // Slightly reduced shadow opacity
        // Inner Glow attempt
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.white.opacity(0.05), lineWidth: 1) // Reduced glow
                .blur(radius: 1)
                .mask(RoundedRectangle(cornerRadius: 32).fill(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)))
        )
        .frame(height: 64) // Reduced height from 74 to 64
    }
}

// MARK: - Press Feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    MainTabView()
}
