//
//  LoginView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI
import FirebaseAuth


struct LoginView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isRememberMeChecked = true
    @State private var showForgotPasswordAlert = false
    @State private var resetEmail = ""
    
    var body: some View {
        ZStack {
            AuthBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.appPrimary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        // Title Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Welcome Back")
                                .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 48))
                                .foregroundColor(.appText)
                            
                            Text("Your cinematic journey continues here.")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(.appTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        
                        // Form Card (Glassmorphic)
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("EMAIL")
                                    .font(.system(size: 11, weight: .black))
                                    .tracking(1.5)
                                    .foregroundColor(.appPrimary)
                                
                                TextField("", text: $email)
                                    .placeholder(when: email.isEmpty) {
                                        Text("Email").foregroundColor(.white.opacity(0.4))
                                    }
                                    .padding()
                                    .foregroundColor(.white) // Ensure input text is white
                                    .frame(height: 60)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("PASSWORD")
                                    .font(.system(size: 11, weight: .black))
                                    .tracking(1.5)
                                    .foregroundColor(.appPrimary)
                                
                                HStack {
                                    if showPassword {
                                        TextField("", text: $password)
                                            .placeholder(when: password.isEmpty) {
                                                Text("••••••••").foregroundColor(.white.opacity(0.2))
                                            }
                                    } else {
                                        SecureField("", text: $password)
                                            .placeholder(when: password.isEmpty) {
                                                Text("••••••••").foregroundColor(.white.opacity(0.2))
                                            }
                                    }
                                    
                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.appTextSecondary)
                                    }
                                }
                                .padding()
                                .frame(height: 60)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                            
                            HStack {
                                Button(action: { isRememberMeChecked.toggle() }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: isRememberMeChecked ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(isRememberMeChecked ? .appPrimary : .appTextSecondary)
                                        Text("Remember me")
                                            .font(.system(size: 14))
                                            .foregroundColor(.appTextSecondary)
                                    }
                                }
                                Spacer()
                                Button(action: { 
                                    resetEmail = email 
                                    showForgotPasswordAlert = true 
                                }) {
                                    Text("Forgot Password?")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.appText)
                                }
                            }
                        }
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                if email == "admin@gmail.com" && password == "admin@1234" {
                                    appViewModel.adminLogin()
                                    return
                                }
                                Task {
                                    do {
                                        UserDefaults.standard.set(isRememberMeChecked, forKey: "rememberMe")
                                        let _ = try await AuthenticationService.shared.signIn(email: email, password: password)
                                    } catch {
                                        print("Login Error: \(error)")
                                    }
                                }
                            }) {
                                Text("Log In")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color.appPrimary)
                                    .cornerRadius(18)
                                    .shadow(color: .appPrimary.opacity(0.3), radius: 10, y: 5)
                            }
                            
                            HStack(spacing: 20) {
                                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                                Text("OR CONTINUE WITH").font(.system(size: 10, weight: .bold)).foregroundColor(.appTextSecondary).tracking(1)
                                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                            }
                            .padding(.vertical, 10)
                            
                            VStack(spacing: 16) {

                                
                                Button(action: {
                                    Task {
                                        do {
                                            let result = try await AuthenticationService.shared.signInWithGoogle()
                                            try await FirestoreService.shared.saveUser(user: result.user)
                                        } catch {
                                            print("Google Sign In Error: \(error)")
                                        }
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image("Google")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 20, height: 20)
                                        
                                        Text("Continue with Google")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(.black)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Reset Password", isPresented: $showForgotPasswordAlert) {
            TextField("Enter your email", text: $resetEmail)
                .keyboardType(.emailAddress)
            Button("Cancel", role: .cancel) { }
            Button("Send Link") {
                Task {
                    do {
                        try await AuthenticationService.shared.sendPasswordReset(email: resetEmail)
                    } catch {
                        print("Reset Password Error: \(error)")
                    }
                }
            }
        } message: {
            Text("Enter your email address to receive a password reset link.")
        }
    }
}

// Helper extension for placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    LoginView()
}
