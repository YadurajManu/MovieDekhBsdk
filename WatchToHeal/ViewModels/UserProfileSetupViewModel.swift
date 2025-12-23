import Foundation
import SwiftUI
import Combine
@MainActor
class UserProfileSetupViewModel: ObservableObject {
    @Published var username = ""
    @Published var bio = ""
    @Published var isCheckingUsername = false
    @Published var isUsernameAvailable: Bool?
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var setupComplete = false
    
    @Published var selectedPersona: CinematicPersona? {
        didSet {
            updateBioSuggestions()
        }
    }
    @Published var bioSuggestions: [String] = []
    
    private var checkTask: Task<Void, Never>?
    
    func checkUsername() {
        checkTask?.cancel()
        
        let cleaned = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count >= 3 else {
            isUsernameAvailable = nil
            return
        }
        
        isCheckingUsername = true
        
        checkTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if Task.isCancelled { return }
            
            do {
                let available = try await FirestoreService.shared.isUsernameAvailable(cleaned)
                if !Task.isCancelled {
                    self.isUsernameAvailable = available
                    self.isCheckingUsername = false
                }
            } catch {
                if !Task.isCancelled {
                    self.isCheckingUsername = false
                }
            }
        }
    }
    
    func saveProfile(userId: String) async {
        guard isUsernameAvailable == true else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            try await FirestoreService.shared.setUsername(userId: userId, username: username)
            
            var profileData: [String: Any] = [:]
            if !bio.isEmpty {
                profileData["bio"] = bio
            }
            if let persona = selectedPersona {
                profileData["persona"] = persona.rawValue
            }
            
            if !profileData.isEmpty {
                try await FirestoreService.shared.updateUserProfile(userId: userId, data: profileData)
            }
            
            setupComplete = true
        } catch {
            errorMessage = "Failed to save profile. Please try again."
        }
        
        isSaving = false
    }
    
    private func updateBioSuggestions() {
        if let persona = selectedPersona {
            bioSuggestions = persona.suggestions
        }
    }
}
