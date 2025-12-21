import SwiftUI

struct PublicProfileView: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            // Dynamic Background Glow
            Circle()
                .fill(Color.appPrimary.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -150, y: -200)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header with Back Button
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.appText)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                        
                        Spacer()
                        
                        if let username = profile.username {
                            Text("@\(username)")
                                .font(.system(size: 14, weight: .black))
                                .tracking(2)
                                .foregroundColor(.appPrimary)
                        }
                        
                        Spacer()
                        
                        // Action/Follow (Placeholder)
                        Button(action: { }) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 18))
                                .foregroundColor(.appText)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Profile Info
                    VStack(spacing: 20) {
                        if let photoURL = profile.photoURL {
                            CachedAsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle().fill(Color.appCardBackground)
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.appPrimary.opacity(0.3), lineWidth: 4))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.appTextSecondary.opacity(0.3))
                                .background(Circle().fill(Color.appCardBackground))
                                .overlay(Circle().stroke(Color.appPrimary.opacity(0.3), lineWidth: 4))
                        }
                        
                        VStack(spacing: 8) {
                            Text(profile.name)
                                .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 40))
                                .foregroundColor(.appText)
                            
                            if !profile.bio.isEmpty {
                                Text(profile.bio)
                                    .font(.system(size: 14))
                                    .foregroundColor(.appTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                    }
                    
                    // Stats
                    HStack(spacing: 24) {
                        statItem(value: "\(profile.followerCount)", label: "FOLLOWERS")
                        statItem(value: "\(profile.followingCount)", label: "FOLLOWING")
                        statItem(value: "\(profile.topFavorites.count)", label: "FAVORITES")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.05)))
                    .padding(.horizontal, 24)
                    
                    // Favorites Grid
                    if !profile.topFavorites.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("CINEMATIC MASTERPIECES")
                                .font(.system(size: 11, weight: .black))
                                .tracking(2)
                                .foregroundColor(.appPrimary)
                                .padding(.horizontal, 24)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                ForEach(profile.topFavorites) { movie in
                                    MovieCardView(movie: movie)
                                        .frame(height: 260)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "film")
                                .font(.system(size: 40))
                                .foregroundColor(.appTextSecondary.opacity(0.3))
                            Text("No favorites shared yet.")
                                .font(.system(size: 14))
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(.top, 40)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.appText)
            Text(label)
                .font(.system(size: 10, weight: .black))
                .tracking(1)
                .foregroundColor(.appPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}
