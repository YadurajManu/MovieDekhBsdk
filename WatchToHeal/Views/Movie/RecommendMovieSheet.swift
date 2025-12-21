import SwiftUI
import FirebaseAuth

struct RecommendMovieSheet: View {
    let movieId: Int
    let movieTitle: String
    let moviePoster: String?
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    
    @State private var friends: [UserProfile] = []
    @State private var selectedFriend: UserProfile?
    @State private var note: String = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var searchText = ""
    
    var filteredFriends: [UserProfile] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { ($0.username ?? $0.name).localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Movie Header
                    HStack(spacing: 16) {
                        if let poster = moviePoster, let url = URL(string: "https://image.tmdb.org/t/p/w200\(poster)") {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.white.opacity(0.1)
                            }
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recommend")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.appTextSecondary)
                            Text(movieTitle)
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.appText)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.appTextSecondary)
                        TextField("Search friends...", text: $searchText)
                            .foregroundColor(.appText)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if isLoading {
                        Spacer()
                        ProgressView().tint(.appPrimary)
                        Spacer()
                    } else if friends.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.appTextSecondary)
                            Text("No friends found")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.appTextSecondary)
                            Text("Add friends to start nudging!")
                                .font(.system(size: 14))
                                .foregroundColor(.appTextSecondary.opacity(0.7))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredFriends) { friend in
                                    FriendRecommendationRow(friend: friend, isSelected: selectedFriend?.id == friend.id) {
                                        selectedFriend = friend
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Note Input
                    if selectedFriend != nil {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Message")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.appTextSecondary)
                            
                            TextField("Something like: 'This reminded me of you!'", text: $note)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.appText)
                        }
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Send Button
                    Button(action: sendNudge) {
                        HStack {
                            if isSending {
                                ProgressView().tint(.black)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("SEND NUDGE")
                            }
                        }
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedFriend != nil ? Color.appPrimary : Color.white.opacity(0.1))
                        .cornerRadius(28)
                        .padding()
                    }
                    .disabled(selectedFriend == nil || isSending)
                }
            }
            .navigationTitle("SEND A NUDGE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appPrimary)
                }
            }
            .onAppear(perform: loadFriends)
        }
    }
    
    private func loadFriends() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task {
            do {
                self.friends = try await FirestoreService.shared.fetchFriends(userId: uid)
                self.isLoading = false
            } catch {
                print("Error loading friends: \(error)")
                self.isLoading = false
            }
        }
    }
    
    private func sendNudge() {
        guard let friend = selectedFriend, let sender = appViewModel.userProfile else { return }
        isSending = true
        
        Task {
            do {
                try await FirestoreService.shared.sendRecommendation(
                    sender: sender,
                    recipientId: friend.id,
                    movieId: movieId,
                    movieTitle: movieTitle,
                    moviePoster: moviePoster,
                    note: note
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error sending nudge: \(error)")
                isSending = false
            }
        }
    }
}

struct FriendRecommendationRow: View {
    let friend: UserProfile
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let photoURL = friend.photoURL {
                    AsyncImage(url: photoURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.white.opacity(0.1))
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text((friend.username ?? friend.name).prefix(1).uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.appPrimary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.username ?? friend.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.appText)
                    if !friend.bio.isEmpty {
                        Text(friend.bio)
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Circle()
                    .stroke(isSelected ? Color.appPrimary : Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.appPrimary : Color.clear)
                            .frame(width: 14, height: 14)
                    )
            }
            .padding()
            .background(isSelected ? Color.appPrimary.opacity(0.1) : Color.white.opacity(0.05))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
