import Foundation
import Combine
import FirebaseAuth

@MainActor
class FriendshipManager: ObservableObject {
    static let shared = FriendshipManager()
    
    @Published var friendRequests: [UserProfile] = []
    @Published var friends: [UserProfile] = []
    @Published var pendingRequestCount: Int = 0
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Auto-refresh when app opens
        AuthenticationService.shared.$user
            .compactMap { $0 }
            .sink { [weak self] user in
                Task { [weak self] in
                    await self?.loadFriendRequests(userId: user.uid)
                    await self?.loadFriends(userId: user.uid)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadFriendRequests(userId: String) async {
        isLoading = true
        do {
            let requests = try await FirestoreService.shared.fetchFriendRequests(userId: userId)
            friendRequests = requests
            pendingRequestCount = requests.count
        } catch {
            print("Error loading friend requests: \(error)")
        }
        isLoading = false
    }
    
    func loadFriends(userId: String) async {
        do {
            friends = try await FirestoreService.shared.fetchFriends(userId: userId)
        } catch {
            print("Error loading friends: \(error)")
        }
    }
    
    func sendFriendRequest(from senderId: String, to recipientId: String) async throws {
        try await FirestoreService.shared.sendFriendRequest(from: senderId, to: recipientId)
    }
    
    func acceptFriendRequest(from senderId: String, to recipientId: String) async throws {
        try await FirestoreService.shared.acceptFriendRequest(from: senderId, to: recipientId)
        await loadFriendRequests(userId: recipientId)
        await loadFriends(userId: recipientId)
    }
    
    func declineFriendRequest(from senderId: String, to recipientId: String) async throws {
        try await FirestoreService.shared.declineFriendRequest(from: senderId, to: recipientId)
        await loadFriendRequests(userId: recipientId)
    }
    
    func removeFriend(userId: String, friendId: String) async throws {
        try await FirestoreService.shared.removeFriend(userId: userId, friendId: friendId)
        await loadFriends(userId: userId)
    }
    
    func checkFriendshipStatus(userId: String, otherId: String) async -> FirestoreService.FriendshipStatus {
        do {
            return try await FirestoreService.shared.checkFriendshipStatus(userId: userId, otherId: otherId)
        } catch {
            print("Error checking friendship status: \(error)")
            return .none
        }
    }
}
