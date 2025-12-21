import SwiftUI

struct AdminDashboardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Background: Deep Dark Mesh
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                .black, .black, .black,
                Color(hex: "0A0A0A"), .black, Color(hex: "121212"),
                Color.appPrimary.opacity(0.1), .black, .black
            ])
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Premium Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.appText)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("ADMIN TERMINAL")
                            .font(.system(size: 10, weight: .black))
                            .tracking(3)
                            .foregroundColor(.appPrimary)
                        Text("System Control")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.appText)
                    }
                    
                    Spacer()
                    
                    // Invisible balancing element
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Content Switcher
                Group {
                    if selectedTab == 0 {
                        AdminPollsListView()
                    } else {
                        AdminUsersView()
                    }
                }
                .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                
                Spacer()
                
                // Custom Premium Tab Bar
                customTabBar
            }
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(icon: "chart.bar.fill", label: "Polls", index: 0)
            tabButton(icon: "person.3.fill", label: "Users", index: 1)
        }
        .padding(8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.8))
                .shadow(color: .appPrimary.opacity(0.1), radius: 20)
                .overlay(Capsule().stroke(Color.white.opacity(0.05), lineWidth: 1))
        )
        .padding(.horizontal, 40)
        .padding(.bottom, 30)
    }
    
    private func tabButton(icon: String, label: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                if selectedTab == index {
                    Text(label)
                        .font(.system(size: 12, weight: .black))
                        .tracking(1)
                }
            }
            .foregroundColor(selectedTab == index ? .black : .appTextSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(selectedTab == index ? Color.appPrimary : Color.clear)
            .cornerRadius(22)
        }
    }
}

struct AdminPollsListView: View {
    @StateObject private var viewModel = AdminPollsViewModel()
    @State private var showCreatePoll = false
    @State private var selectedFilter = 0 // 0: Active, 1: Passed
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GLOBAL PULSE")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.appText)
                    Text("\(viewModel.activePolls.count + viewModel.passedPolls.count) Engagement Points")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
                Button(action: { showCreatePoll = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("NEW POLL")
                    }
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.appPrimary)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal, 24)
            
            // Filter Pills
            HStack(spacing: 12) {
                filterPill(label: "ACTIVE", count: viewModel.activePolls.count, index: 0)
                filterPill(label: "PASSED", count: viewModel.passedPolls.count, index: 1)
                Spacer()
            }
            .padding(.horizontal, 24)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView().tint(.appPrimary)
                Spacer()
            } else {
                let currentPolls = selectedFilter == 0 ? viewModel.activePolls : viewModel.passedPolls
                
                if currentPolls.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: selectedFilter == 0 ? "bolt.fill" : "archivebox.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.appPrimary.opacity(0.2))
                        Text(selectedFilter == 0 ? "No active polls.\nStart a new debate!" : "No passed polls in the archive.")
                            .font(.system(size: 13))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(currentPolls) { poll in
                                pollRow(poll: poll)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showCreatePoll) {
            AdminPollCreateView {
                // Real-time listener handles refresh
            }
        }
    }
    
    private func filterPill(label: String, count: Int, index: Int) -> some View {
        Button(action: { 
            withAnimation(.spring()) {
                selectedFilter = index 
            }
        }) {
            HStack(spacing: 6) {
                Text(label)
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(selectedFilter == index ? Color.black.opacity(0.2) : Color.white.opacity(0.1))
                    .cornerRadius(6)
            }
            .font(.system(size: 11, weight: .black))
            .foregroundColor(selectedFilter == index ? .black : .appTextSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(selectedFilter == index ? Color.appPrimary : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedFilter == index ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private func pollRow(poll: MoviePoll) -> some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(poll.question)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appText)
                        
                        Text(poll.type == .movie ? "CINEMATIC BATTLE" : "COMMUNITY DEBATE")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.appPrimary)
                    }
                    Spacer()
                    
                    Menu {
                        if !poll.isFinalized && (poll.expiresAt == nil || poll.expiresAt! > Date()) {
                            Button(action: { Task { await viewModel.finalizePoll(poll.id ?? "") } }) {
                                Label("Finalize Now", systemImage: "checkmark.seal.fill")
                            }
                        }
                        Button(role: .destructive, action: { Task { await viewModel.deletePoll(poll.id ?? "") } }) {
                            Label("Delete Poll", systemImage: "trash.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.appTextSecondary)
                            .frame(width: 32, height: 32)
                    }
                }
                
                // Result Bars (Preview)
                VStack(spacing: 8) {
                    ForEach(0..<min(poll.options.count, 2), id: \.self) { index in
                        let percentage = poll.totalVotes > 0 ? Double(poll.votes[index]) / Double(poll.totalVotes) : 0
                        HStack {
                            Text(poll.options[index].text)
                                .font(.system(size: 12))
                                .foregroundColor(.appTextSecondary)
                            Spacer()
                            Text("\(Int(percentage * 100))%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.appPrimary)
                        }
                        
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.appPrimary.opacity(0.3))
                                .frame(width: geo.size.width * CGFloat(percentage), height: 4)
                        }
                        .frame(height: 4)
                    }
                }
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                        Text("\(poll.totalVotes) participants")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.appTextSecondary)
                    
                    Spacer()
                    
                    if let expires = poll.expiresAt {
                        Text(expires > Date() ? "Ends \(expires.timeAgoDisplay())" : "Ended \(expires.timeAgoDisplay())")
                            .font(.system(size: 10))
                            .foregroundColor(expires > Date() ? .appPrimary : .gray)
                    }
                }
            }
            .padding(16)
        }
    }
}

struct AdminUsersView: View {
    @State private var users: [UserProfile] = []
    @State private var searchText = ""
    @State private var isLoading = true
    
    var filteredUsers: [UserProfile] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) || 
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.appTextSecondary)
                TextField("Search members...", text: $searchText)
                    .foregroundColor(.appText)
                    .autocorrectionDisabled()
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            if isLoading {
                Spacer()
                ProgressView().tint(.appPrimary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredUsers) { user in
                            userRow(user: user)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .onAppear(perform: loadUsers)
    }
    
    private func userRow(user: UserProfile) -> some View {
        GlassCard(cornerRadius: 16) {
            HStack(spacing: 16) {
                // Profile Avatar
                if let url = user.photoURL {
                    AsyncImage(url: url) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.white.opacity(0.1))
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.appTextSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appText)
                    Text(user.email)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                Menu {
                    Button(action: { toggleAdmin(for: user) }) {
                        Label(user.isAdmin ? "Revoke Admin" : "Make Admin", 
                              systemImage: user.isAdmin ? "person.badge.minus" : "person.badge.shield.check")
                    }
                    
                    Button(role: .destructive, action: { /* Suspension placeholder */ }) {
                        Label("Suspend User", systemImage: "xmark.octagon.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appPrimary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.appPrimary.opacity(0.1)))
                }
            }
            .padding(12)
            .overlay(alignment: .topTrailing) {
                if user.isAdmin {
                    Text("ADMIN")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.appPrimary)
                        .cornerRadius(4)
                        .offset(x: -8, y: 8)
                }
            }
        }
    }
    
    private func loadUsers() {
        Task {
            do {
                let fetched = try await FirestoreService.shared.fetchAllUsers()
                await MainActor.run {
                    self.users = fetched
                    self.isLoading = false
                }
            } catch {
                print("Error loading users: \(error)")
                self.isLoading = false
            }
        }
    }
    
    private func toggleAdmin(for user: UserProfile) {
        let userId = user.id
        let newStatus = !user.isAdmin
        
        Task {
            do {
                try await FirestoreService.shared.updateUserRole(userId: userId, isAdmin: newStatus)
                // Refresh local UI
                if let index = users.firstIndex(where: { $0.id == userId }) {
                    await MainActor.run {
                        users[index].isAdmin = newStatus
                    }
                }
            } catch {
                print("Error updating user role: \(error)")
            }
        }
    }
}
