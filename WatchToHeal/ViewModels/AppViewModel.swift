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
    
    // Deep Link State
    @Published var deepLinkDestination: DeepLinkDestination?
    
    enum DeepLinkDestination: Identifiable {
        case movie(id: Int)
        case show(id: Int)
        case person(id: Int, name: String)
        
        var id: String {
            switch self {
            case .movie(let id): return "movie_\(id)"
            case .show(let id): return "show_\(id)"
            case .person(let id, _): return "person_\(id)"
            }
        }
    }
    
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

    
    // MARK: - Deep Link Handler
    func handleDeepLink(_ url: URL) {
        // Support both custom scheme (if registered) and https fallback
        guard url.scheme == "watchtoheal" || url.host == "watchtoheal.com" else { return }
        
        // URL Structure: https://watchtoheal.com/type/id?name=EncodedName
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        guard pathComponents.count >= 2,
              let id = Int(pathComponents[1])
        else { return }
        
        let type = pathComponents[0] // movie, show, person
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        let name = components.queryItems?.first(where: { $0.name == "name" })?.value ?? "Unknown"
        
        Task { @MainActor in
            switch type {
            case "movie":
                self.deepLinkDestination = .movie(id: id)
            case "show":
                self.deepLinkDestination = .show(id: id)
            case "person":
                self.deepLinkDestination = .person(id: id, name: name)
            default:
                break
            }
        }
    }
}

