import SwiftUI
import FirebaseAuth
struct FriendsListView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var friendshipManager = FriendshipManager.shared
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var searchQuery = ""
    @State private var selectedFriend: UserProfile?
    
    var filteredFriends: [UserProfile] {
        if searchQuery.isEmpty {
            return friendshipManager.friends
        }
        return friendshipManager.friends.filter { friend in
            friend.name.localizedCaseInsensitiveContains(searchQuery) ||
            (friend.username?.localizedCaseInsensitiveContains(searchQuery) ?? false)
        }
    }
    
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
                        Text("MY FRIENDS")
                            .font(.system(size: 11, weight: .black))
                            .tracking(2)
                            .foregroundColor(.appPrimary)
                        
                        Text("\(friendshipManager.friends.count)")
                            .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 32))
                            .foregroundColor(.appText)
                    }
                    
                    Spacer()
                    
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.appTextSecondary)
                    
                    TextField("Search friends...", text: $searchQuery)
                        .foregroundColor(.appText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                if friendshipManager.friends.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.appPrimary.opacity(0.3))
                        
                        Text("No friends yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                        
                        Text("Start exploring the community!")
                            .font(.system(size: 14))
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if filteredFriends.isEmpty {
                    VStack(spacing: 16) {
                        Text("No friends found matching \"\(searchQuery)\"")
                            .font(.system(size: 16))
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(filteredFriends) { friend in
                                FriendGridCard(friend: friend)
                                    .onTapGesture {
                                        selectedFriend = friend
                                    }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedFriend) { friend in
            PublicProfileView(profile: friend)
        }
        .task {
            if let userId = appViewModel.currentUser?.uid {
                await friendshipManager.loadFriends(userId: userId)
            }
        }
    }
}

struct FriendGridCard: View {
    let friend: UserProfile
    
    var body: some View {
        VStack(spacing: 12) {
            if let photoURL = friend.photoURL {
                CachedAsyncImage(url: photoURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.appCardBackground)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.appTextSecondary.opacity(0.3))
            }
            
            VStack(spacing: 4) {
                Text(friend.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appText)
                    .lineLimit(1)
                
                if let username = friend.username {
                    Text("@\(username)")
                        .font(.system(size: 12))
                        .foregroundColor(.appPrimary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}
