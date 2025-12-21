import SwiftUI
import AuthenticationServices

struct TraktAuthSheet: View {
    @StateObject private var traktService = TraktService.shared
    @Environment(\.dismiss) var dismiss
    @State private var isAuthenticating = false
    @State private var deviceCode: String = ""
    @State private var userCode: String = ""
    @State private var verificationURL: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Trakt Logo/Header
                    VStack(spacing: 12) {
                        Image(systemName: "tv.and.mediabox")
                            .font(.system(size: 60))
                            .foregroundColor(.appPrimary)
                        
                        Text("Connect to Trakt")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appText)
                        
                        Text("Track your watch history, get personalized stats, and sync across devices")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    if isAuthenticating {
                        // Authentication in progress
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.appPrimary)
                            
                            if !userCode.isEmpty {
                                VStack(spacing: 16) {
                                    Text("Visit this URL on any device:")
                                        .font(.subheadline)
                                        .foregroundColor(.appTextSecondary)
                                    
                                    Button(action: {
                                        if let url = URL(string: verificationURL) {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Text(verificationURL)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.appPrimary)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.appCardBackground)
                                            .cornerRadius(12)
                                    }
                                    
                                    Text("Enter this code:")
                                        .font(.subheadline)
                                        .foregroundColor(.appTextSecondary)
                                    
                                    Text(userCode)
                                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                                        .foregroundColor(.appPrimary)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.appCardBackground)
                                        .cornerRadius(12)
                                    
                                    Button(action: {
                                        UIPasteboard.general.string = userCode
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.on.doc")
                                            Text("Copy Code")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.appText)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.appCardBackground)
                                        .cornerRadius(8)
                                    }
                                    
                                    Text("Waiting for authorization...")
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                        .padding(.top, 8)
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        // Not authenticated
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                                .opacity(traktService.isAuthenticated ? 1 : 0)
                            
                            if traktService.isAuthenticated {
                                Text("Connected as \(traktService.currentUser?.username ?? "User")")
                                    .font(.headline)
                                    .foregroundColor(.appText)
                                
                                Button(action: {
                                    traktService.logout()
                                    dismiss()
                                }) {
                                    Text("Disconnect")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.appCardBackground)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            } else {
                                Button(action: {
                                    Task {
                                        await startAuthentication()
                                    }
                                }) {
                                    Text("Connect to Trakt")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.appPrimary)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
            .alert("Authentication Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func startAuthentication() async {
        isAuthenticating = true
        
        do {
            // Device code flow doesn't need presentation anchor
            try await traktService.authenticateWithDeviceCode()
            dismiss()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isAuthenticating = false
            }
        }
    }
}
