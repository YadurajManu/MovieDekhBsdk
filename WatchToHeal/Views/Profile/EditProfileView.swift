import SwiftUI
import FirebaseAuth

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var email: String = "" // Read only for now
    @State private var topFavorites: [Movie?] = [nil, nil, nil]
    
    @State private var showSearchSheet = false
    @State private var activeSlotIndex: Int? = nil
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar (Non-editable for now)
                        if let photoURL = appViewModel.userProfile?.photoURL {
                            AsyncImage(url: photoURL) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    Circle().fill(Color.gray)
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.appPrimary, lineWidth: 2))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        
                        // Form
                        VStack(spacing: 20) {
                            // Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name").font(.caption).foregroundColor(.appTextSecondary)
                                TextField("Name", text: $name)
                                    .padding()
                                    .background(Color.appCardBackground)
                                    .cornerRadius(8)
                                    .foregroundColor(.appText)
                            }
                            
                            // Email (Read Only)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email").font(.caption).foregroundColor(.appTextSecondary)
                                TextField("Email", text: $email)
                                    .padding()
                                    .background(Color.appCardBackground.opacity(0.5))
                                    .cornerRadius(8)
                                    .foregroundColor(.appTextSecondary)
                                    .disabled(true)
                            }
                            
                            // Bio
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Bio").font(.caption).foregroundColor(.appTextSecondary)
                                TextEditor(text: $bio)
                                    .frame(height: 100)
                                    .padding(4)
                                    .background(Color.appCardBackground)
                                    .cornerRadius(8)
                                    .foregroundColor(.appText)
                                    .scrollContentBackground(.hidden) // For TextEditor
                            }
                            
                            // Top 3 Favorites
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Top 3 Favorites").font(.headline).foregroundColor(.appText)
                                
                                HStack(spacing: 12) {
                                    ForEach(0..<3) { index in
                                        Button(action: {
                                            activeSlotIndex = index
                                            showSearchSheet = true
                                        }) {
                                            ZStack {
                                                if let movie = topFavorites[index] {
                                                    AsyncImage(url: movie.posterURL) { phase in
                                                        if let image = phase.image {
                                                            image.resizable().aspectRatio(contentMode: .fill)
                                                        } else {
                                                            Color.appCardBackground
                                                        }
                                                    }
                                                } else {
                                                    Color.appCardBackground
                                                    Image(systemName: "plus")
                                                        .foregroundColor(.appTextSecondary)
                                                }
                                            }
                                            .frame(width: 80, height: 120)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.appTextSecondary.opacity(0.3), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showSearchSheet) {
                MovieSearchSheet { movie in
                    if let index = activeSlotIndex {
                        topFavorites[index] = movie
                    }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        if let profile = appViewModel.userProfile {
            name = profile.name
            bio = profile.bio
            email = profile.email
            
            // Fill slots
            for (index, movie) in profile.topFavorites.prefix(3).enumerated() {
                topFavorites[index] = movie
            }
        }
    }
    
    private func saveProfile() {
        guard let userId = appViewModel.currentUser?.uid else { return }
        isLoading = true
        
        let validFavorites = topFavorites.compactMap { $0 }
        
        Task {
            do {
                // Update text fields
                try await FirestoreService.shared.updateUserProfile(userId: userId, data: [
                    "displayName": name,
                    "bio": bio
                ])
                
                // Update Favorites
                try await FirestoreService.shared.updateTopFavorites(userId: userId, movies: validFavorites)
                
                // Refresh local state
                // Ideally AppViewModel listens or we manual refresh
                 await MainActor.run {
                     // Create updated profile locally or re-fetch
                     var updated = appViewModel.userProfile
                     updated?.name = name
                     updated?.bio = bio
                     updated?.topFavorites = validFavorites
                     appViewModel.userProfile = updated
                     
                     dismiss()
                 }
            } catch {
                print("Error saving profile: \(error)")
            }
            isLoading = false
        }
    }
}
