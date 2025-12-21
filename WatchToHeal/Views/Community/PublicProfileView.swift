import SwiftUI
import FirebaseAuth

struct PublicProfileView: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var friendshipManager = FriendshipManager.shared
    @StateObject private var listsViewModel = CommunityListsViewModel()
    @State private var friendshipStatus: FirestoreService.FriendshipStatus = .none
    @State private var isProcessing = false
    @State private var selectedTab: ProfileTab = .favorites
    
    enum ProfileTab: String, CaseIterable {
        case favorites = "FAVORITES"
        case lists = "LISTS"
    }
    
    // Layout constants for minimalist grid
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            // Subtle premium background glow
            LinearGradient(colors: [Color.appPrimary.opacity(0.05), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    // Refined Header
                    HStack(alignment: .center) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.appText)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.white.opacity(0.08)))
                        }
                        
                        Spacer()
                        
                        if let username = profile.username {
                            Text("@\(username)")
                                .font(.system(size: 12, weight: .black))
                                .tracking(1.5)
                                .foregroundColor(.appPrimary)
                                .opacity(0.8)
                        }
                        
                        Spacer()
                        
                        friendActionButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Profile Info - Centered and Minimal
                    VStack(spacing: 24) {
                        ProfileImageContainer(url: profile.photoURL)
                        
                        VStack(spacing: 12) {
                            Text(profile.name)
                                .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 42))
                                .foregroundColor(.appText)
                                .multilineTextAlignment(.center)
                            
                            if !profile.bio.isEmpty {
                                Text(profile.bio)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.appTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 48)
                                    .lineSpacing(4)
                            }
                        }
                    }
                    
                    // Stats Block - Glassmorphism UI
                    HStack(spacing: 0) {
                        statItem(value: "\(profile.followerCount)", label: "FOLLOWERS")
                        divider
                        statItem(value: "\(profile.followingCount)", label: "FOLLOWING")
                        divider
                        statItem(value: "\(profile.topFavorites.count)", label: "FAVORITES")
                    }
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.04))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    )
                    .padding(.horizontal, 24)
                    
                    // Profile Tab Picker
                    HStack(spacing: 32) {
                        ForEach(ProfileTab.allCases, id: \.self) { tab in
                            Button(action: { 
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 11, weight: .black))
                                        .tracking(2)
                                        .foregroundColor(selectedTab == tab ? .appPrimary : .appTextSecondary)
                                    
                                    Capsule()
                                        .fill(selectedTab == tab ? Color.appPrimary : Color.clear)
                                        .frame(width: 20, height: 3)
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                    
                    if selectedTab == .favorites {
                        favoritesGrid
                    } else {
                        userListsContent
                    }
                    
                    Spacer(minLength: 60)
                }
            }
        }
        .navigationBarHidden(true)
        .task { 
            await checkFriendshipStatus()
            await listsViewModel.fetchUserLists(userId: profile.id)
        }
    }
    
    @ViewBuilder
    private var favoritesGrid: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("HALL OF FAME")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundColor(.appPrimary)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.appPrimary.opacity(0.3))
                    .frame(height: 1)
                    .frame(maxWidth: 40)
            }
            .padding(.horizontal, 24)
            
            if !profile.topFavorites.isEmpty {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(profile.topFavorites) { movie in
                        MinimalPosterCard(movie: movie)
                    }
                }
                .padding(.horizontal, 24)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "film")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.1))
                    Text("No favorites shared yet")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
    
    @ViewBuilder
    private var userListsContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            if listsViewModel.userLists.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.1))
                    Text("No public lists found")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(listsViewModel.userLists) { list in
                        NavigationLink(destination: ListDetailView(list: list)) {
                            CommunityListCard(list: list)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(width: 1, height: 30)
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.appText)
            Text(label)
                .font(.system(size: 9, weight: .black))
                .tracking(1)
                .foregroundColor(.appPrimary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var friendActionButton: some View {
        if isProcessing {
            ProgressView()
                .tint(.appPrimary)
                .scaleEffect(0.8)
                .frame(width: 40, height: 40)
        } else {
            CircleButton(status: friendshipStatus) {
                handleFriendAction()
            }
        }
    }
    
    private func handleFriendAction() {
        Task {
            guard let currentUserId = appViewModel.currentUser?.uid else { return }
            isProcessing = true
            do {
                switch friendshipStatus {
                case .none:
                    try await friendshipManager.sendFriendRequest(from: currentUserId, to: profile.id)
                case .requestSent:
                    try await FirestoreService.shared.cancelFriendRequest(from: currentUserId, to: profile.id)
                case .requestReceived:
                    try await friendshipManager.acceptFriendRequest(from: profile.id, to: currentUserId)
                    appViewModel.fetchUserProfile()
                case .friends:
                    try await friendshipManager.removeFriend(userId: currentUserId, friendId: profile.id)
                    appViewModel.fetchUserProfile()
                }
                await checkFriendshipStatus()
            } catch {
                print("Friend action failed: \(error)")
            }
            isProcessing = false
        }
    }
    
    private func checkFriendshipStatus() async {
        guard let currentUserId = appViewModel.currentUser?.uid else { return }
        friendshipStatus = await friendshipManager.checkFriendshipStatus(userId: currentUserId, otherId: profile.id)
    }
}

// MARK: - Subviews

struct ProfileImageContainer: View {
    let url: URL?
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appPrimary.opacity(0.2), lineWidth: 1)
                .frame(width: 130, height: 130)
            
            if let url = url {
                CachedAsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.appCardBackground)
                }
                .frame(width: 110, height: 110)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 110, height: 110)
                    .foregroundColor(.appTextSecondary.opacity(0.2))
                    .background(Circle().fill(Color.appCardBackground))
            }
        }
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

struct MinimalPosterCard: View {
    let movie: Movie
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let url = movie.posterURL {
                    CachedAsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12).fill(Color.appCardBackground)
                    }
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appCardBackground)
                        .frame(height: 160)
                }
                
                // Minimalist rating dot
                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: 6, height: 6)
                    .padding(8)
                    .opacity(movie.voteAverage > 7 ? 1 : 0)
            }
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            Text(movie.title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.appText)
                .lineLimit(1)
        }
    }
}

struct CircleButton: View {
    let status: FirestoreService.FriendshipStatus
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(background)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(foreground)
            }
        }
        .shadow(color: shadowColor, radius: 10)
    }
    
    var icon: String {
        switch status {
        case .none: return "person.badge.plus"
        case .requestSent: return "paperplane.fill"
        case .requestReceived: return "bell.badge.fill"
        case .friends: return "checkmark"
        }
    }
    
    var background: Color {
        status == .none ? Color.appPrimary : Color.white.opacity(0.08)
    }
    
    var foreground: Color {
        status == .none ? Color.black : Color.appText
    }
    
    var shadowColor: Color {
        status == .none ? Color.appPrimary.opacity(0.3) : Color.clear
    }
}
