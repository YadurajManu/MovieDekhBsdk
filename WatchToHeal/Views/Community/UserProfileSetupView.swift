import SwiftUI
import FirebaseAuth

struct UserProfileSetupView: View {
    @StateObject private var viewModel = UserProfileSetupViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, bio
    }
    
    var body: some View {
        ZStack {
            backgroundView
            mainContent
            backButtonOverlay
        }
        .onTapGesture {
            focusedField = nil
        }
        .onChange(of: viewModel.setupComplete) { oldValue, newValue in
            if newValue {
                appViewModel.fetchUserProfile()
                dismiss()
            }
        }
    }
    
    private var isValid: Bool {
        viewModel.isUsernameAvailable == true && viewModel.selectedPersona != nil
    }
    
    private var usernameBorderColor: Color {
        if viewModel.isCheckingUsername {
            return Color.appPrimary.opacity(0.3)
        } else if viewModel.isUsernameAvailable == true {
            return Color.green.opacity(0.5)
        } else if viewModel.isUsernameAvailable == false {
            return Color.red.opacity(0.5)
        }
        return Color.white.opacity(0.1)
    }
    
    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 40) {
                headerView
                previewCardView
                formView
                claimButton
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            headerIcon
            
            Text("Cinematic Identity")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.appText)
            
            Text("Claim your unique handle to join the community. You can update persona and bio anytime.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 56)
    }
    
    private var previewCardView: some View {
        IdentityPreviewCard(
            username: viewModel.username,
            bio: viewModel.bio,
            persona: viewModel.selectedPersona,
            photoURL: AuthenticationService.shared.user?.photoURL
        )
        .padding(.horizontal)
    }
    
    private var formView: some View {
        VStack(spacing: 28) {
            usernameSection
            personaSection
            bioSection
        }
        .padding(.horizontal)
    }
    
    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("USERNAME")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.appTextSecondary)
                    .kerning(1)
                
                Spacer()
                
                Text("PERMANENT")
                    .font(.system(size: 9, weight: .black))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.appPrimary.opacity(0.1))
                    .foregroundColor(.appPrimary)
                    .clipShape(Capsule())
            }
            
            HStack {
                Text("@")
                    .foregroundColor(.appTextSecondary)
                    .font(.system(size: 18, weight: .bold))
                
                TextField("username", text: $viewModel.username)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.appText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .username)
                    .onChange(of: viewModel.username) { oldValue, newValue in
                        let filtered = newValue.lowercased().filter { "abcdefghijklmnopqrstuvwxyz0123456789_".contains($0) }
                        if filtered != newValue {
                            viewModel.username = filtered
                        }
                        viewModel.checkUsername()
                    }
                
                if viewModel.isCheckingUsername {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let available = viewModel.isUsernameAvailable {
                    Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(available ? .green : .red)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.02))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(usernameBorderColor, lineWidth: 1)
            )
            
            if viewModel.isUsernameAvailable == false {
                Text("Handle already claimed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            } else if viewModel.username.count > 0 && viewModel.username.count < 3 {
                Text("Must be at least 3 characters")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                    .padding(.leading, 4)
            }
        }
    }
    
    private var personaSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SELECT PERSONA")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.appTextSecondary)
                .kerning(1)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CinematicPersona.allCases, id: \.self) { persona in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedPersona = persona
                            }
                        }) {
                            Text(persona.rawValue)
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(personaBackground(isSelected: viewModel.selectedPersona == persona))
                                .foregroundColor(viewModel.selectedPersona == persona ? .black : .appText)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            
            if let persona = viewModel.selectedPersona {
                Text(persona.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appPrimary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BIO")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.appTextSecondary)
                .kerning(1)
            
            ZStack(alignment: .topLeading) {
                if viewModel.bio.isEmpty {
                    Text("A short cinematic bio...")
                        .foregroundColor(.appTextSecondary.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }
                
                TextEditor(text: $viewModel.bio)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appText)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .focused($focusedField, equals: .bio)
            }
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.02))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            
            if !viewModel.bioSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.bioSuggestions, id: \.self) { suggestion in
                            Button(action: {
                                withAnimation { viewModel.bio = suggestion }
                            }) {
                                Text(suggestion)
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.05))
                                    .foregroundColor(.appTextSecondary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var claimButton: some View {
        Button(action: {
            focusedField = nil
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
                    Image(systemName: "arrow.right")
                }
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(claimButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: isValid ? Color.appPrimary.opacity(0.4) : .clear, radius: 18, y: 8)
        }
        .disabled(!isValid || viewModel.isSaving)
        .padding(.horizontal)
        .padding(.bottom, 40)
    }
    
    private var backButtonOverlay: some View {
        VStack {
            HStack {
                GlassBackButton {
                    dismiss()
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer()
        }
        .zIndex(2)
    }
    
    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.appBackground,
                    Color.appBackground.opacity(0.95),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [Color.appPrimary.opacity(0.22), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private func personaBackground(isSelected: Bool) -> some View {
        if isSelected {
            LinearGradient(
                colors: [Color.appPrimary, Color.appPrimary.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            Color.white.opacity(0.06)
        }
    }
    
    @ViewBuilder
    private var claimButtonBackground: some View {
        if isValid {
            LinearGradient(
                colors: [Color.appPrimary, Color.appPrimary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.white.opacity(0.08)
        }
    }
    
    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appPrimary.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 64, height: 64)
                .shadow(color: Color.appPrimary.opacity(0.35), radius: 18, y: 10)
            
            Image(systemName: "sparkles")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.black)
        }
    }
}
