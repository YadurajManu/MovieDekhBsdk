import SwiftUI
import FirebaseAuth
struct UserProfileSetupView: View {
    @StateObject private var viewModel = UserProfileSetupViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            // Background Glow
            Circle()
                .fill(Color.appPrimary.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -150, y: -200)
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.appPrimary)
                    
                    Text("Your Cinematic Identity")
                        .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 36))
                        .foregroundColor(.appText)
                    
                    Text("Claim your unique handle to join the community.")
                        .font(.system(size: 16))
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                
                VStack(spacing: 24) {
                    // Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("USERNAME")
                            .font(.system(size: 11, weight: .black))
                            .tracking(2)
                            .foregroundColor(.appPrimary)
                        
                        HStack {
                            Text("@")
                                .foregroundColor(.appPrimary)
                                .font(.system(size: 18, weight: .bold))
                            
                            TextField("username", text: $viewModel.username)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .foregroundColor(.appText)
                                .onChange(of: viewModel.username) { newValue in
                                    // Limit to letters, numbers and underscores
                                    let filtered = newValue.lowercased().filter { "abcdefghijklmnopqrstuvwxyz0123456789_".contains($0) }
                                    if filtered != newValue {
                                        viewModel.username = filtered
                                    }
                                    viewModel.checkUsername()
                                }
                            
                            if viewModel.isCheckingUsername {
                                ProgressView()
                                    .tint(.appPrimary)
                                    .scaleEffect(0.8)
                            } else if let available = viewModel.isUsernameAvailable {
                                Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(available ? .green : .red)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                        
                        if let available = viewModel.isUsernameAvailable, !available {
                            Text("This username is already taken")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if viewModel.username.count > 0 && viewModel.username.count < 3 {
                            Text("Must be at least 3 characters")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                    
                    // Bio Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BIO")
                            .font(.system(size: 11, weight: .black))
                            .tracking(2)
                            .foregroundColor(.appPrimary)
                        
                        TextField("A short cinematic bio...", text: $viewModel.bio, axis: .vertical)
                            .lineLimit(3...5)
                            .foregroundColor(.appText)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Confirm Button
                Button(action: {
                    Task {
                        if let userId = appViewModel.currentUser?.uid {
                            await viewModel.saveProfile(userId: userId)
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isSaving {
                            ProgressView().tint(.black)
                        } else {
                            Text("Claim Identity")
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isUsernameAvailable == true ? Color.appPrimary : Color.appPrimary.opacity(0.3))
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .disabled(viewModel.isUsernameAvailable != true || viewModel.isSaving)
            }
        }
        .onChange(of: viewModel.setupComplete) { complete in
            if complete {
                appViewModel.fetchUserProfile() // Refresh local profile
                dismiss()
            }
        }
    }
}
