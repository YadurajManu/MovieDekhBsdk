import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import Combine


class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var user: User?
    
    private init() {
        self.user = Auth.auth().currentUser
    }
    
    func listenToAuthState() {
        _ = Auth.auth().addStateDidChangeListener { auth, user in
            self.user = user
        }
    }
    
    func signUp(email: String, password: String) async throws -> AuthDataResult {
        return try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    func signIn(email: String, password: String) async throws -> AuthDataResult {
        return try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    @MainActor
    func signInWithGoogle() async throws -> AuthDataResult {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
             fatalError("No Client ID found in Firebase configuration")
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw URLError(.cannotFindHost)
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = result.user
        guard let idToken = user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: user.accessToken.tokenString)
        
        return try await Auth.auth().signIn(with: credential)
    }
    

    
    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        // 1. Purge Firestore Data first
        try await FirestoreService.shared.purgeUserData(userId: user.uid)
        
        // 2. Delete Auth User
        try await user.delete()
    }
}
