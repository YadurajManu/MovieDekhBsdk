import SwiftUI
import FirebaseAuth
struct PublicProfileView: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var friendshipManager = FriendshipManager.shared
    @State private var friendshipStatus: FirestoreService.FriendshipStatus = .none
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            // Dynamic Background Glow
            Circle()
                .fill(Color.appPrimary.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -150, y: -200)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header with Back Button
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.appText)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                        
                        Spacer()
                        
                        if let username = profile.username {
                            Text("@\(username)")
                                .font(.system(size: 14, weight: .black))
                                .tracking(2)
                                .foregroundColor(.appPrimary)
                        }
                        
                        Spacer()
                        
                        // Dynamic Friend Action Button
                        friendActionButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Profile Info
                    VStack(spacing: 20) {
                        if let photoURL = profile.photoURL {
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
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.appTextSecondary.opacity(0.3))
                                .background(Circle().fill(Color.appCardBackground))
                                .overlay(Circle().stroke(Color.appPrimary.opacity(0.3), lineWidth: 4))
                        }
                        
                        VStack(spacing: 8) {
                            Text(profile.name)
                                .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 40))
                                .foregroundColor(.appText)
                            
                            if !profile.bio.isEmpty {
                                Text(profile.bio)
                                    .font(.system(size: 14))
                                    .foregroundColor(.appTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                    }
                    
                    // Stats
                    HStack(spacing: 24) {
                        statItem(value: "\(profile.followerCount)", label: "FOLLOWERS")
                        statItem(value: "\(profile.followingCount)", label: "FOLLOWING")
                        statItem(value: "\(profile.topFavorites.count)", label: "FAVORITES")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.05)))
                    .padding(.horizontal, 24)
                    
                    // Favorites Grid
                    if !profile.topFavorites.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("CINEMATIC MASTERPIECES")
                                .font(.system(size: 11, weight: .black))
                                .tracking(2)
                                .foregroundColor(.appPrimary)
                                .padding(.horizontal, 24)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                ForEach(profile.topFavorites) { movie in
                                    MovieCardView(movie: movie)
                                        .frame(height: 260)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "film")
                                .font(.system(size: 40))
                                .foregroundColor(.appTextSecondary.opacity(0.3))
                            Text("No favorites shared yet.")
                                .font(.system(size: 14))
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(.top, 40)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await checkFriendshipStatus()
        }
    }
    
    @ViewBuilder
    private var friendActionButton: some View {
        if isProcessing {
            ProgressView()
                .tint(.appPrimary)
                .scaleEffect(0.8)
                .frame(width: 44, height: 44)
        } else {
            switch friendshipStatus {
            case .none:
                Button(action: { sendFriendRequest() }) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.appPrimary))
                        .shadow(color: .appPrimary.opacity(0.3), radius: 10)
                }
                
            case .requestSent:
                Button(action: { cancelFriendRequest() }) {
                    Text("Pending")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.appTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                }
                
            case .requestReceived:
                Button(action: { acceptRequest() }) {
                    Text("Accept")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.appPrimary))
                }
                
            case .friends:
                Button(action: { unfriend() }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.appPrimary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
            }
        }
    }
    
    private func checkFriendshipStatus() async {
        guard let currentUserId = appViewModel.currentUser?.uid else { return }
        friendshipStatus = await friendshipManager.checkFriendshipStatus(userId: currentUserId, otherId: profile.id)
    }
    
    private func sendFriendRequest() {
        guard let currentUserId = appViewModel.currentUser?.uid else { return }
        isProcessing = true
        
        Task {
            try? await friendshipManager.sendFriendRequest(from: currentUserId, to: profile.id)
            await checkFriendshipStatus()
            isProcessing = false
        }
    }
    
    private func acceptRequest() {
        guard let currentUserId = appViewModel.currentUser?.uid else { return }
        isProcessing = true
        
        Task {
            try? await friendshipManager.acceptFriendRequest(from: profile.id, to: currentUserId)
            appViewModel.fetchUserProfile() // Refresh counts
            await checkFriendshipStatus()
            isProcessing = false
        }
    }
    
    private func cancelFriendRequest() {
        guard let currentUserId = appViewModel.currentUser?.uid else { return }
        isProcessing = true
        
        Task {
            try? await FirestoreService.shared.cancelFriendRequest(from: currentUserId, to: profile.id)
            await checkFriendshipStatus()
            isProcessing = false
        }
    }
    
    private func unfriend() {
        guard let currentUserId = appViewModel.currentUser?.uid else { return }
        isProcessing = true
        
        Task {
            try? await friendshipManager.removeFriend(userId: currentUserId, friendId: profile.id)
            appViewModel.fetchUserProfile() // Refresh counts
            await checkFriendshipStatus()
            isProcessing = false
        }
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.appText)
            Text(label)
                .font(.system(size: 10, weight: .black))
                .tracking(1)
                .foregroundColor(.appPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}
