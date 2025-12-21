import Foundation
import Combine
import AuthenticationServices

class TraktService: NSObject, ObservableObject {
    static let shared = TraktService()
    
    // Trakt API Credentials
    private let clientID = "b1cdc0fbc8f5a76fa80a54f353f59630b3d945471fea643d5111dde469964372"
    private let clientSecret = "bba82d1308bc02af103cdf03b435ecbadc23fb8201bc6cc35736dce99c63f73f"
    private let redirectURI = "watchtoheal://trakt/callback"
    private let baseURL = "https://api.trakt.tv"
    
    // OAuth State
    @Published var isAuthenticated = false
    @Published var currentUser: TraktUser?
    private var authTokens: TraktAuthTokens?
    
    // Session
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "trakt-api-version": "2",
            "trakt-api-key": clientID
        ]
        return URLSession(configuration: config)
    }()
    
    private override init() {
        super.init()
        loadStoredTokens()
    }
    
    // MARK: - Authentication
    
    func authenticate(presentationAnchor: ASPresentationAnchor) async throws {
        // For now, we'll use device code flow which is simpler for iOS
        try await authenticateWithDeviceCode()
    }
    
    func authenticateWithDeviceCode() async throws {
        // Step 1: Get device code
        let deviceCodeURL = URL(string: "\(baseURL)/oauth/device/code")!
        var request = URLRequest(url: deviceCodeURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["client_id": clientID]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await urlSession.data(for: request)
        let deviceCode = try JSONDecoder().decode(DeviceCodeResponse.self, from: data)
        
        // Step 2: User needs to visit URL and enter code
        // In a real app, show this to the user
        print("Visit: \(deviceCode.verificationUrl)")
        print("Enter code: \(deviceCode.userCode)")
        
        // Step 3: Poll for token
        try await pollForToken(deviceCode: deviceCode.deviceCode, interval: deviceCode.interval)
    }
    
    private func pollForToken(deviceCode: String, interval: Int) async throws {
        let tokenURL = URL(string: "\(baseURL)/oauth/device/token")!
        
        for _ in 0..<30 { // Poll for 5 minutes max
            try await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)
            
            var request = URLRequest(url: tokenURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = [
                "code": deviceCode,
                "client_id": clientID,
                "client_secret": clientSecret
            ]
            request.httpBody = try JSONEncoder().encode(body)
            
            do {
                let (data, response) = try await urlSession.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let tokens = try JSONDecoder().decode(TraktAuthTokens.self, from: data)
                    await MainActor.run {
                        self.authTokens = tokens
                        self.isAuthenticated = true
                        self.saveTokens(tokens)
                    }
                    try await fetchCurrentUser()
                    return
                }
            } catch {
                // Continue polling
                continue
            }
        }
        
        throw TraktError.authenticationTimeout
    }
    
    func refreshTokenIfNeeded() async throws {
        guard let tokens = authTokens, tokens.isExpired else { return }
        
        let refreshURL = URL(string: "\(baseURL)/oauth/token")!
        var request = URLRequest(url: refreshURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "refresh_token": tokens.refreshToken,
            "client_id": clientID,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI,
            "grant_type": "refresh_token"
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await urlSession.data(for: request)
        let newTokens = try JSONDecoder().decode(TraktAuthTokens.self, from: data)
        
        await MainActor.run {
            self.authTokens = newTokens
            self.saveTokens(newTokens)
        }
    }
    
    func logout() {
        authTokens = nil
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "traktTokens")
    }
    
    // MARK: - User
    
    func fetchCurrentUser() async throws {
        try await refreshTokenIfNeeded()
        
        let url = URL(string: "\(baseURL)/users/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authTokens?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await urlSession.data(for: request)
        let user = try JSONDecoder().decode(TraktUser.self, from: data)
        
        await MainActor.run {
            self.currentUser = user
        }
    }
    
    // MARK: - Watch History
    
    func getWatchHistory(limit: Int = 50) async throws -> [TraktWatchHistory] {
        try await refreshTokenIfNeeded()
        
        let url = URL(string: "\(baseURL)/users/me/history/movies?limit=\(limit)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authTokens?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode([TraktWatchHistory].self, from: data)
    }
    
    func scrobbleMovie(tmdbId: Int, progress: Double = 100.0) async throws {
        try await refreshTokenIfNeeded()
        
        let url = URL(string: "\(baseURL)/scrobble/stop")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authTokens?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let scrobble = ScrobbleRequest(
            movie: ScrobbleRequest.MovieIdentifier(
                ids: ScrobbleRequest.MovieIdentifier.IDs(tmdb: tmdbId)
            ),
            progress: progress,
            appVersion: "1.0",
            appDate: ISO8601DateFormatter().string(from: Date())
        )
        
        request.httpBody = try JSONEncoder().encode(scrobble)
        let _ = try await urlSession.data(for: request)
    }
    
    // MARK: - Stats
    
    func getUserStats() async throws -> TraktStats {
        try await refreshTokenIfNeeded()
        
        let url = URL(string: "\(baseURL)/users/me/stats")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authTokens?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode(TraktStats.self, from: data)
    }
    
    // MARK: - Lists
    
    func getUserLists() async throws -> [TraktList] {
        try await refreshTokenIfNeeded()
        
        let url = URL(string: "\(baseURL)/users/me/lists")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authTokens?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode([TraktList].self, from: data)
    }
    
    func getListItems(listId: String) async throws -> [TraktListItem] {
        try await refreshTokenIfNeeded()
        
        let url = URL(string: "\(baseURL)/users/me/lists/\(listId)/items/movies")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authTokens?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode([TraktListItem].self, from: data)
    }
    
    func createList(name: String, description: String?, privacy: String = "private") async throws -> TraktList {
        try await refreshTokenIfNeeded()
        
        let url = URL(string: "\(baseURL)/users/me/lists")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authTokens?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "name": name,
            "description": description ?? "",
            "privacy": privacy,
            "display_numbers": false,
            "allow_comments": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode(TraktList.self, from: data)
    }
    
    func addToList(listId: String, tmdbIds: [Int]) async throws {
        try await refreshTokenIfNeeded()
        
        let url = URL(string: "\(baseURL)/users/me/lists/\(listId)/items")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authTokens?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let movies = tmdbIds.map { tmdbId in
            AddToListRequest.MovieIdentifier(
                ids: AddToListRequest.MovieIdentifier.IDs(tmdb: tmdbId)
            )
        }
        
        let body = AddToListRequest(movies: movies)
        request.httpBody = try JSONEncoder().encode(body)
        let _ = try await urlSession.data(for: request)
    }
    
    // MARK: - Token Storage
    
    private func saveTokens(_ tokens: TraktAuthTokens) {
        if let encoded = try? JSONEncoder().encode(tokens) {
            UserDefaults.standard.set(encoded, forKey: "traktTokens")
        }
    }
    
    private func loadStoredTokens() {
        if let data = UserDefaults.standard.data(forKey: "traktTokens"),
           let tokens = try? JSONDecoder().decode(TraktAuthTokens.self, from: data) {
            self.authTokens = tokens
            self.isAuthenticated = true
            
            Task {
                try? await fetchCurrentUser()
            }
        }
    }
}

// MARK: - Supporting Types

struct DeviceCodeResponse: Codable {
    let deviceCode: String
    let userCode: String
    let verificationUrl: String
    let expiresIn: Int
    let interval: Int
    
    enum CodingKeys: String, CodingKey {
        case interval
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationUrl = "verification_url"
        case expiresIn = "expires_in"
    }
}

enum TraktError: Error {
    case notAuthenticated
    case authenticationTimeout
    case invalidResponse
    case networkError(Error)
}
