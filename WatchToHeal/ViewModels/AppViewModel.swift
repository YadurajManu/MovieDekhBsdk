import SwiftUI
import Combine
import FirebaseAuth

class AppViewModel: ObservableObject {
    static let shared = AppViewModel()
    @Published var isAuthenticated: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    @Published var isCheckingAuth: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Removed forced sign-out logic to allow persistent sessions
    
        // Listen to Auth Service
        AuthenticationService.shared.$user
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = (user != nil)
                if let user = user {
                    // Fetch extended profile
                    Task { [weak self] in
                        // 1. Onboarding Status
                        let completed = try? await FirestoreService.shared.checkOnboardingStatus(userId: user.uid)
                        
                        // 2. Profile Data
                        let profile = try? await FirestoreService.shared.fetchUserProfile(userId: user.uid)
                        
                        await MainActor.run {
                            if let completed = completed, completed {
                                self?.hasCompletedOnboarding = true
                                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            }
                            // Init profile if exists, else create default wrapper
                            if let profile = profile {
                                self?.userProfile = profile
                            } else {
                                self?.userProfile = UserProfile(id: user.uid,
                                                              name: user.displayName ?? "User",
                                                              email: user.email ?? "",
                                                              bio: "",
                                                              photoURL: user.photoURL,
                                                              topFavorites: [],
                                                              preferredRegion: "IN", // Default to India
                                                              streamingProviders: [])
                            }
                            self?.isCheckingAuth = false
                        }
                    }
                } else {
                    self?.isCheckingAuth = false
                }
            }
            .store(in: &cancellables)
            
        AuthenticationService.shared.listenToAuthState()
        
        // Keep local manual override for dev/testing if needed, or rely purely on Auth
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        if let user = currentUser {
            Task {
                try? await FirestoreService.shared.saveOnboardingData(userId: user.uid, data: ["completed": true])
            }
        }
    }
    
    func fetchUserProfile() {
        guard let user = currentUser else { return }
        Task {
            let profile = try? await FirestoreService.shared.fetchUserProfile(userId: user.uid)
            await MainActor.run {
                if let profile = profile {
                    self.userProfile = profile
                }
            }
        }
    }
    
    func signOut() {
        try? AuthenticationService.shared.signOut()
        self.userProfile = nil
        self.isAuthenticated = false
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
    
    func deleteAccount() async throws {
        try await AuthenticationService.shared.deleteAccount()
        await MainActor.run {
            // Clear local caches
            WatchlistManager.shared.clearWatchlist()
            HistoryManager.shared.clearHistory()
            
            self.userProfile = nil
            self.isAuthenticated = false
            self.hasCompletedOnboarding = false
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
    }
    
    // MARK: - Admin Flow
    func adminLogin() {
        // Create a mock super-admin profile
        let mockAdmin = UserProfile(
            id: "admin_super_user",
            username: "admin",
            name: "Super Admin",
            email: "admin@gmail.com",
            bio: "System Administrator",
            photoURL: nil,
            topFavorites: [],
            isAdmin: true
        )
        
        self.userProfile = mockAdmin
        self.isAuthenticated = true
        self.hasCompletedOnboarding = true // Admins bypass onboarding
    }
}
