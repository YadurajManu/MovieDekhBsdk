import SwiftUI
import FirebaseAuth

struct SecuritySettingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showingDeleteAlert = false
    @State private var showingErrorAlert = false
    @State private var showingResetAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACCOUNT SECURITY")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.appTextSecondary)
                            .padding(.leading, 8)
                        
                        GlassCard {
                            VStack(spacing: 0) {
                                Button(action: resetPassword) {
                                    HStack {
                                        Image(systemName: "key.fill")
                                            .foregroundColor(.appPrimary)
                                            .frame(width: 24)
                                        Text("Reset Password")
                                            .foregroundColor(.appText)
                                        Spacer()
                                        Image(systemName: "envelope.fill")
                                            .font(.caption)
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    .padding()
                                }
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                HStack {
                                    Image(systemName: "envelope.badge.shield.half.filled")
                                        .foregroundColor(.appPrimary)
                                        .frame(width: 24)
                                    Text("Two-Factor Auth")
                                        .foregroundColor(.appText)
                                    Spacer()
                                    Text("Coming Soon")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.appPrimary.opacity(0.2))
                                        .foregroundColor(.appPrimary)
                                        .clipShape(Capsule())
                                }
                                .padding()
                                .opacity(0.6)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DANGER ZONE")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.leading, 8)
                        
                        GlassCard {
                            Button(action: { showingDeleteAlert = true }) {
                                HStack {
                                    Image(systemName: "person.fill.xmark")
                                        .foregroundColor(.red)
                                        .frame(width: 24)
                                    Text("Delete Account")
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Security")
        .alert("Password Reset", isPresented: $showingResetAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Delete Account?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action is permanent and cannot be undone. All your ratings, watchlist, and profile data will be purged.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func resetPassword() {
        guard let email = appViewModel.currentUser?.email else { return }
        
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                await MainActor.run {
                    alertMessage = "A password reset link has been sent to \(email)."
                    showingResetAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func deleteAccount() {
        Task {
            do {
                try await appViewModel.deleteAccount()
            } catch {
                await MainActor.run {
                    if let err = error as NSError?, err.code == AuthErrorCode.requiresRecentLogin.rawValue {
                        alertMessage = "For security, you must sign in again before deleting your account."
                    } else {
                        alertMessage = error.localizedDescription
                    }
                    showingErrorAlert = true
                }
            }
        }
    }
}
