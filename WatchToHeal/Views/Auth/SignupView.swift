//
//  SignupView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI
import FirebaseAuth

struct SignupView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
    var body: some View {
        ZStack {
            AuthBackground()
            
            VStack(spacing: 0) {
                // Header (Close Button)
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
                    VStack(spacing: 32) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Create Account")
                                .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 48))
                                .foregroundColor(.appText)
                            
                            Text("Join the circle of movie lovers.")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(.appTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        
                        // Fields
                        VStack(spacing: 20) {
                            authField(title: "NAME", placeholder: "Your name", text: $name)
                            authField(title: "EMAIL", placeholder: "name@example.com", text: $email, keyboardType: .emailAddress)
                            authSecureField(title: "PASSWORD", placeholder: "Create a password", text: $password)
                        }
                        
                        // Terms
                        Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                            .font(.system(size: 11))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .opacity(0.6)
                        
                        // Signup Button
                        VStack(spacing: 16) {
                            Button(action: {
                                Task {
                                    do {
                                        let result = try await AuthenticationService.shared.signUp(email: email, password: password)
                                        try await FirestoreService.shared.saveUser(user: result.user)
                                    } catch {
                                        print("Signup error: \(error)")
                                    }
                                }
                            }) {
                                Text("Sign Up")
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
                                Text("OR JOIN WITH").font(.system(size: 10, weight: .bold)).foregroundColor(.appTextSecondary).tracking(1)
                                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                            }
                            .padding(.vertical, 10)
                            
                            HStack(spacing: 16) {
                                SocialSignInButton(provider: .apple) {}
                                    .frame(height: 56)
                                
                                SocialSignInButton(provider: .google) {
                                    Task {
                                        do {
                                            let result = try await AuthenticationService.shared.signInWithGoogle()
                                            try await FirestoreService.shared.saveUser(user: result.user)
                                        } catch {
                                            print("Google Sign In Error: \(error)")
                                        }
                                    }
                                }
                                .frame(height: 56)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    @ViewBuilder
    private func authField(title: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .tracking(1.5)
                .foregroundColor(.appPrimary)
            
            TextField("", text: text)
                .placeholder(when: text.wrappedValue.isEmpty) {
                    Text(placeholder).foregroundColor(.white.opacity(0.2))
                }
                .padding()
                .frame(height: 60)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .autocapitalization(.none)
                .keyboardType(keyboardType)
        }
    }
    
    @ViewBuilder
    private func authSecureField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .tracking(1.5)
                .foregroundColor(.appPrimary)
            
            HStack {
                if showPassword {
                    TextField("", text: text)
                        .placeholder(when: text.wrappedValue.isEmpty) {
                            Text(placeholder).foregroundColor(.white.opacity(0.2))
                        }
                } else {
                    SecureField("", text: text)
                        .placeholder(when: text.wrappedValue.isEmpty) {
                            Text(placeholder).foregroundColor(.white.opacity(0.2))
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
    }
}

#Preview {
    SignupView()
}
