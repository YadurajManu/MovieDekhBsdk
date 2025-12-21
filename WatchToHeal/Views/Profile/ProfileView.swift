//
//  ProfileView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var watchlistManager = WatchlistManager.shared
    @StateObject private var historyManager = HistoryManager.shared
    @StateObject private var traktService = TraktService.shared
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var showLogOutAlert = false
    @State private var showTraktAuth = false
    @State private var showStatsDetail = false
    @State private var cacheSize: String = ImageLoader.getCacheSize()
    @State private var rotationOffset: CGFloat = 0
    @State private var showRecommendations = false
    @StateObject private var homeViewModel = HomeViewModel()
    
    @MainActor
    private func shareTopMovies() {
        guard let profile = appViewModel.userProfile, !profile.topFavorites.isEmpty else { return }
        
        // Ensure we capture the Hall of Fame view precisely
        let shareView = TopMovieShareView(
            userName: profile.name,
            topMovies: profile.topFavorites
        )
        
        let renderer = ImageRenderer(content: shareView)
        renderer.scale = 3.0
        
        if let image = renderer.uiImage {
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                activityVC.popoverPresentationController?.sourceView = rootVC.view
                rootVC.present(activityVC, animated: true)
            }
        }
    }
    
    private func shareApp() {
        let text = "Transform your movie watching into a healing journey. Check out WatchToHeal!"
        let url = URL(string: "https://apps.apple.com/app/watchtoheal")!
        let activityVC = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func clearCache() {
        ImageLoader.clearCache()
        cacheSize = ImageLoader.getCacheSize()
    }
    
    // Extracted view elements for better compiler performance
    private var meshGradientBackground: some View {
        MeshGradient(width: 3, height: 3, points: [
            [0, 0], [0.5, 0], [1, 0],
            [0, 0.5], [0.5, 0.5], [1, 0.5],
            [0, 1], [0.5, 1], [1, 1]
        ], colors: [
            .black, .black, .black,
            Color(hex: "1A1A1A"), .black, Color(hex: "0D0D0D"),
            Color.appPrimary.opacity(0.15), .black, .black
        ])
        .ignoresSafeArea()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                meshGradientBackground
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile Header
                        VStack(spacing: 20) {
                            ZStack(alignment: .bottomTrailing) {
                                if let photoURL = appViewModel.userProfile?.photoURL {
                                    CachedAsyncImage(url: photoURL) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle().fill(Color.appCardBackground)
                                    }
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.appPrimary.opacity(0.3), lineWidth: 4))
                                    .shadow(color: .appPrimary.opacity(0.2), radius: 20)
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 120, height: 120)
                                        .foregroundColor(.appTextSecondary.opacity(0.3))
                                        .background(Circle().fill(Color.appCardBackground))
                                        .overlay(Circle().stroke(Color.appPrimary.opacity(0.3), lineWidth: 4))
                                }
                                
                                Button(action: { showEditProfile = true }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.appPrimary)
                                        .background(Circle().fill(Color.black))
                                        .shadow(radius: 5)
                                }
                            }
                            
                            VStack(spacing: 6) {
                                Text(appViewModel.userProfile?.name ?? "Movie Lover")
                                    .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 40))
                                    .foregroundColor(.appText)
                                
                                Text(appViewModel.userProfile?.email ?? "Sign in to sync")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.appTextSecondary)
                                    .opacity(0.7)
                            }
                            
                            if let bio = appViewModel.userProfile?.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.system(size: 14))
                                    .foregroundColor(.appTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Stats Section (Glassmorphic)
                        HStack(spacing: 16) {
                            statCard(value: "\(watchlistManager.watchlistMovies.count)", label: "Watchlist", icon: "bookmark.fill")
                            
                            Button(action: { showStatsDetail = true }) {
                                statCard(value: "\(historyManager.moviesWatchedCount)", label: "Watched", icon: "eye.fill")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            statCard(value: historyManager.formattedWatchTime, label: "Time", icon: "clock.fill")
                        }
                        .padding(.horizontal)
                        
                        // Top 3 Favorites Section (3D Rotating Stack)
                        if let topMovies = appViewModel.userProfile?.topFavorites, !topMovies.isEmpty {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("CINEMATIC HALL OF FAME")
                                            .font(.system(size: 11, weight: .black))
                                            .tracking(2)
                                            .foregroundColor(.appPrimary)
                                        Text("My Absolute Favorites")
                                            .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 28))
                                            .foregroundColor(.appText)
                                    }
                                    Spacer()
                                    Button(action: { shareTopMovies() }) {
                                        Image(systemName: "square.and.arrow.up.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                            .frame(width: 40, height: 40)
                                            .background(Color.appPrimary)
                                            .clipShape(Circle())
                                            .shadow(color: .appPrimary.opacity(0.3), radius: 10)
                                    }
                                }
                                .padding(.horizontal, 24)
                                
                                ZStack {
                                    HStack(spacing: -30) {
                                        ForEach(Array(topMovies.prefix(3).enumerated()), id: \.offset) { index, movie in
                                            let relativeIndex = CGFloat(index) - 1.0
                                            
                                            ZStack(alignment: .bottomTrailing) {
                                                CachedAsyncImage(url: movie.posterURL) { image in
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                } placeholder: {
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(Color.white.opacity(0.05))
                                                }
                                                .frame(width: 140, height: 210)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                                .shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 10)
                                                
                                                Text("\(index + 1)")
                                                    .font(.system(size: 12, weight: .black))
                                                    .foregroundColor(.black)
                                                    .frame(width: 24, height: 24)
                                                    .background(Color.appPrimary)
                                                    .clipShape(Circle())
                                                    .offset(x: 8, y: 8)
                                            }
                                            .rotation3DEffect(
                                                .degrees(Double(relativeIndex * 25) + Double(rotationOffset / 10)),
                                                axis: (x: 0, y: 1, z: 0)
                                            )
                                            .scaleEffect(index == 1 ? 1.1 : 0.9)
                                            .zIndex(index == 1 ? 10 : Double(1 - abs(Int(relativeIndex))))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                    .background(
                                        Ellipse()
                                            .fill(Color.appPrimary.opacity(0.15))
                                            .blur(radius: 50)
                                            .frame(width: 250, height: 120)
                                            .offset(y: 80)
                                    )
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                rotationOffset = value.translation.width
                                            }
                                            .onEnded { _ in
                                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                                    rotationOffset = 0
                                                }
                                            }
                                    )
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Menu Sections
                        VStack(spacing: 24) {
                            // ACCOUNT
                            menuSection(title: "Account") {
                                NavigationLink(destination: EditProfileView()) {
                                    menuItem(icon: "person.text.rectangle", title: "Personal Details")
                                }
                                Divider().background(Color.white.opacity(0.1))
                                NavigationLink(destination: SecuritySettingsView()) {
                                    menuItem(icon: "lock.shield.fill", title: "Security")
                                }
                                Divider().background(Color.white.opacity(0.1))
                                NavigationLink(destination: NotificationSettingsView()) {
                                    menuItem(icon: "bell.badge.fill", title: "Notifications")
                                }
                            }
                            
                            // DISCOVERY & SHARING (New)
                            menuSection(title: "Community") {
                                NavigationLink(destination: UserActivityView(userId: appViewModel.userProfile?.id ?? "")) {
                                    menuItem(icon: "clock.arrow.circlepath", title: "My Activity Log")
                                }
                                Divider().background(Color.white.opacity(0.1))
                                NavigationLink(destination: FriendsListView()) {
                                    menuItem(icon: "person.2.fill", title: "My Friends")
                                }
                                 Divider().background(Color.white.opacity(0.1))
                                NavigationLink(destination: MyCommunityListsView()) {
                                    menuItem(icon: "list.bullet.indent", title: "My Movie Lists")
                                }
                                Divider().background(Color.white.opacity(0.1))
                                NavigationLink(destination: MovieInboxView()) {
                                    menuItem(icon: "paperplane.fill", title: "Movie Nudges")
                                }
                                Divider().background(Color.white.opacity(0.1))
                                NavigationLink(destination: FriendRequestsView()) {
                                    HStack {
                                        Image(systemName: "person.badge.plus")
                                            .foregroundColor(.appPrimary)
                                            .frame(width: 24)
                                        Text("Friend Requests")
                                            .foregroundColor(.appText)
                                        Spacer()
                                        if FriendshipManager.shared.pendingRequestCount > 0 {
                                            Text("\(FriendshipManager.shared.pendingRequestCount)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Capsule().fill(Color.appPrimary))
                                        }
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    .padding()
                                }
                                Divider().background(Color.white.opacity(0.1))
                                Button(action: { showRecommendations = true }) {
                                    menuItem(icon: "sparkles", title: "Personalized For You")
                                }
                                Divider().background(Color.white.opacity(0.1))
                                Button(action: { shareApp() }) {
                                    menuItem(icon: "paperplane.fill", title: "Invite Friends")
                                }
                                Divider().background(Color.white.opacity(0.1))
                                menuItem(icon: "star.bubble.fill", title: "Rate on App Store")
                                Divider().background(Color.white.opacity(0.1))
                                menuItem(icon: "hand.thumbsup.fill", title: "Send Feedback")
                            }
                            
                            // TRAKT
                            menuSection(title: "Integrations") {
                                Button(action: { showTraktAuth = true }) {
                                    HStack {
                                        Image(systemName: "tv.and.mediabox.fill")
                                            .foregroundColor(.appPrimary)
                                            .frame(width: 24)
                                        Text(traktService.isAuthenticated ? "Trakt Connected" : "Connect Trakt")
                                            .foregroundColor(.appText)
                                        Spacer()
                                        if traktService.isAuthenticated {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    .padding()
                                }
                            }
                            
                            // SYSTEM
                            menuSection(title: "System & Storage") {
                                Button(action: {
                                    Task {
                                        await WatchlistManager.shared.syncWithFirestore()
                                        await HistoryManager.shared.loadHistory()
                                    }
                                }) {
                                    menuItem(icon: "arrow.triangle.2.circlepath.icloud", title: "Cloud Sync & Recovery")
                                }
                                Divider().background(Color.white.opacity(0.1))
                                NavigationLink(destination: PreferenceSettingsView()) {
                                    menuItem(icon: "slider.horizontal.3", title: "Preferences")
                                }
                                Divider().background(Color.white.opacity(0.1))
                                Button(action: { clearCache() }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(.appPrimary)
                                            .frame(width: 24)
                                        Text("Clear Image Cache")
                                            .foregroundColor(.appText)
                                        Spacer()
                                        Text(cacheSize)
                                            .font(.system(size: 12))
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    .padding()
                                }
                                Divider().background(Color.white.opacity(0.1))
                                menuItem(icon: "info.circle.fill", title: "About WatchToHeal")
                            }
                            
                            // LOGOUT
                            Button(action: { showLogOutAlert = true }) {
                                GlassCard(cornerRadius: 16) {
                                    HStack {
                                        Image(systemName: "power")
                                        Text("Log Out")
                                            .font(.system(size: 16, weight: .bold))
                                        Spacer()
                                    }
                                    .foregroundColor(.red)
                                    .padding()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showStatsDetail) {
            StatsDetailView()
        }
        .fullScreenCover(isPresented: $showRecommendations) {
            RecommendationsView(viewModel: homeViewModel)
                .task {
                    if homeViewModel.personalizedRecommendations.isEmpty {
                        await homeViewModel.loadPersonalizedRecommendations()
                    }
                }
        }
        .sheet(isPresented: $showTraktAuth) {
            TraktAuthSheet()
        }
        .alert("Log Out", isPresented: $showLogOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                appViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
    
    // MARK: - View Builders
    
    private func statCard(value: String, label: String, icon: String) -> some View {
        GlassCard(cornerRadius: 16) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.appPrimary)
                
                VStack(spacing: 0) {
                    Text(value)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appText)
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    private func menuSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.appTextSecondary)
                .padding(.leading, 8)
            
            GlassCard(cornerRadius: 16) {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }
    
    private func menuItem(icon: String, title: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.appPrimary)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.appText)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding()
    }
}

#Preview {
    ProfileView()
}
