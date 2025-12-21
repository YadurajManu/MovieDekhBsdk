import SwiftUI
import Combine
import FirebaseAuth

class AppViewModel: ObservableObject {
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
                                                              topFavorites: [])
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
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
}
