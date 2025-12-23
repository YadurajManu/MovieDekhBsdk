import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @StateObject private var listsViewModel = CommunityListsViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedUser: UserProfile?
    @State private var selectedList: CommunityList?
    @State private var showSetup = false
    @State private var showCreateList = false
    @State private var showCreatePoll = false
    @State private var showCreateQuestion = false
    @State private var communityScope: CommunityScope = .members
    
    enum CommunityScope: String, CaseIterable {
        case members = "People"
        case lists = "Editorial"
        case pulse = "Pulse"
    }
    
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
                            Text(communityScope == .members ? "Film Buffs" : (communityScope == .lists ? "Editorial" : "Pulse"))
                                .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 40))
                                .foregroundColor(.appText)
                        }
                        Spacer()
                        
                        if communityScope == .lists {
                            Button(action: { showCreateList = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(Color.appPrimary))
                            }
                        } else if communityScope == .pulse {
                            Menu {
                                Button(action: { showCreatePoll = true }) {
                                    Label("Create Poll", systemImage: "chart.bar.fill")
                                }
                                Button(action: { showCreateQuestion = true }) {
                                    Label("Start Debate", systemImage: "sparkles")
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(Color.appPrimary))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Scope Picker
                    HStack(spacing: 0) {
                        ForEach(CommunityScope.allCases, id: \.self) { scope in
                            Button(action: { 
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    communityScope = scope
                                }
                            }) {
                                Text(scope.rawValue)
                                    .font(.system(size: 12, weight: .black))
                                    .tracking(1)
                                    .foregroundColor(communityScope == scope ? .black : .appTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(communityScope == scope ? Color.appPrimary : Color.clear)
                                    .cornerRadius(18)
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(22)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    
                    if communityScope == .members {
                        memberSearchContent
                    } else if communityScope == .lists {
                        communityListsContent
                    } else {
                        PulseView()
                    }
                }
            }
            .navigationDestination(item: $selectedUser) { user in
                PublicProfileView(profile: user)
            }
            .navigationDestination(item: $selectedList) { list in
                ListDetailView(list: list)
            }
            .onAppear {
                if appViewModel.userProfile?.username == nil {
                    showSetup = true
                }
                Task {
                    await listsViewModel.fetchAllLists()
                }
            }
            .fullScreenCover(isPresented: $showSetup) {
                UserProfileSetupView()
            }
            .fullScreenCover(isPresented: $showCreateList) {
                CreateCommunityListView()
            }
            .fullScreenCover(isPresented: $showCreatePoll) {
                CreatePollView()
            }
            .fullScreenCover(isPresented: $showCreateQuestion) {
                CreateQuestionView()
            }
        }
    }
    
    @ViewBuilder
    private var memberSearchContent: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.appTextSecondary)
                
                TextField("Search by username...", text: $viewModel.searchQuery)
                    .foregroundColor(.appText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: viewModel.searchQuery) { _, _ in
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
    
    @ViewBuilder
    private var communityListsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                if listsViewModel.isLoading && listsViewModel.communityLists.isEmpty {
                    ProgressView().tint(.appPrimary).frame(maxWidth: .infinity).padding(.top, 40)
                } else if listsViewModel.communityLists.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 60))
                            .foregroundColor(.appPrimary.opacity(0.3))
                        Text("Be the first to create a list!")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("TRENDING COLLECTIONS")
                            .font(.system(size: 10, weight: .black))
                            .tracking(2)
                            .foregroundColor(.appPrimary)
                        
                        LazyVStack(spacing: 20) {
                            ForEach(listsViewModel.communityLists) { list in
                                CommunityListCard(list: list)
                                    .onTapGesture {
                                        selectedList = list
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 40)
        }
        .refreshable {
            await listsViewModel.fetchAllLists()
        }
    }
}

struct UserSearchResultRow: View {
    let user: UserProfile
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Photo
            if let photoURL = user.photoURL {
                CachedAsyncImage(url: photoURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.appCardBackground)
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.appPrimary.opacity(0.3), lineWidth: 1))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .foregroundColor(.appTextSecondary.opacity(0.3))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Name
                Text(user.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appText)
                
                // Username
                if let username = user.username {
                    Text("@\(username)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.appPrimary)
                }
                
                // Activity Stats Row
                HStack(spacing: 12) {
                    // Favorites Count
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                        Text("\(user.topFavorites.count)")
                    }
                    
                    // Followers Count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 9))
                        Text("\(max(0, user.followerCount))")
                    }
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.appTextSecondary.opacity(0.6))
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
