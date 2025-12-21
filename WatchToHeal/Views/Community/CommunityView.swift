import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedUser: UserProfile?
    @State private var showSetup = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                // Animated Background Glow
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(x: 150, y: -200)
                
                VStack(spacing: 0) {
                    // Header
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("COMMUNITY")
                                .font(.system(size: 11, weight: .black))
                                .tracking(2)
                                .foregroundColor(.appPrimary)
                            Text("Film Buffs")
                                .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 40))
                                .foregroundColor(.appText)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.appTextSecondary)
                        
                        TextField("Search by username...", text: $viewModel.searchQuery)
                            .foregroundColor(.appText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: viewModel.searchQuery) { _ in
                                viewModel.performSearch()
                            }
                        
                        if !viewModel.searchQuery.isEmpty {
                            Button(action: { viewModel.searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    
                    if viewModel.isSearching {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.appPrimary)
                            Text("Finding cinephiles...")
                                .font(.system(size: 14))
                                .foregroundColor(.appTextSecondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else if viewModel.searchQuery.isEmpty {
                        // Empty State / Suggestions
                        VStack(spacing: 24) {
                            Image(systemName: "person.2.badge.key.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.appPrimary.opacity(0.3))
                            
                            Text("Find your friends by their\nunique @username")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxHeight: .infinity)
                    } else if viewModel.searchResults.isEmpty {
                        VStack(spacing: 16) {
                            Text("No users found matching \"\(viewModel.searchQuery)\"")
                                .font(.system(size: 16))
                                .foregroundColor(.appTextSecondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        // Results List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.searchResults) { user in
                                    UserSearchResultRow(user: user)
                                        .onTapGesture {
                                            selectedUser = user
                                        }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedUser) { user in
                PublicProfileView(profile: user)
            }
            .onAppear {
                if appViewModel.userProfile?.username == nil {
                    showSetup = true
                }
            }
            .fullScreenCover(isPresented: $showSetup) {
                UserProfileSetupView()
            }
        }
    }
}

struct UserSearchResultRow: View {
    let user: UserProfile
    
    var body: some View {
        HStack(spacing: 16) {
            if let photoURL = user.photoURL {
                CachedAsyncImage(url: photoURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.appCardBackground)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.appTextSecondary.opacity(0.3))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appText)
                
                if let username = user.username {
                    Text("@\(username)")
                        .font(.system(size: 14))
                        .foregroundColor(.appPrimary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.appTextSecondary.opacity(0.3))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}
