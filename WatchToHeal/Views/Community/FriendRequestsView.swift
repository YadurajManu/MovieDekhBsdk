import SwiftUI
import FirebaseAuth
struct FriendRequestsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var friendshipManager = FriendshipManager.shared
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.appText)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("FRIEND REQUESTS")
                            .font(.system(size: 11, weight: .black))
                            .tracking(2)
                            .foregroundColor(.appPrimary)
                        
                        Text("\(friendshipManager.friendRequests.count)")
                            .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 32))
                            .foregroundColor(.appText)
                    }
                    
                    Spacer()
                    
                    // Placeholder for balance
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                if friendshipManager.isLoading {
                    VStack(spacing: 16) {
                        ProgressView().tint(.appPrimary)
                        Text("Loading requests...")
                            .font(.system(size: 14))
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if friendshipManager.friendRequests.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.appPrimary.opacity(0.3))
                        
                        Text("No friend requests")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(friendshipManager.friendRequests) { user in
                                FriendRequestCard(user: user)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct FriendRequestCard: View {
    let user: UserProfile
    @StateObject private var friendshipManager = FriendshipManager.shared
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var isProcessing = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Photo
            if let photoURL = user.photoURL {
                CachedAsyncImage(url: photoURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.appCardBackground)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.appTextSecondary.opacity(0.3))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appText)
                
                if let username = user.username {
                    Text("@\(username)")
                        .font(.system(size: 14))
                        .foregroundColor(.appPrimary)
                }
            }
            
            Spacer()
            
            if isProcessing {
                ProgressView()
                    .tint(.appPrimary)
                    .scaleEffect(0.8)
            } else {
                HStack(spacing: 8) {
                    Button(action: { acceptRequest() }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 36, height: 36)
                            .background(Color.appPrimary)
                            .clipShape(Circle())
                    }
                    
                    Button(action: { declineRequest() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.appText)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
    
    private func acceptRequest() {
        guard let currentUserId = appViewModel.currentUser?.uid else { return }
        isProcessing = true
        
        Task {
            try? await friendshipManager.acceptFriendRequest(from: user.id, to: currentUserId)
            appViewModel.fetchUserProfile() // Refresh counts
            isProcessing = false
        }
    }
    
    private func declineRequest() {
        guard let currentUserId = appViewModel.currentUser?.uid else { return }
        isProcessing = true
        
        Task {
            try? await friendshipManager.declineFriendRequest(from: user.id, to: currentUserId)
            isProcessing = false
        }
    }
}
