import SwiftUI
import FirebaseAuth

struct MovieInboxView: View {
    @State private var recommendations: [MovieRecommendation] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @Environment(\.dismiss) var dismiss
    
    let reactions = ["🍿", "🎬", "🔥", "❤️", "👍", "😮", "😴"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.appPrimary)
                    }
                    
                    Spacer()
                    
                    Text("MOVIE NUDGES")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.appText)
                        .kerning(2)
                    
                    Spacer()
                    
                    // Empty space for balance
                    Color.clear.frame(width: 20, height: 20)
                }
                .padding()
                .background(Color.black)
                
                if isLoading {
                    Spacer()
                    ProgressView().tint(.appPrimary)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.appPrimary.opacity(0.8))
                        Text("Connection Issue")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.appText)
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { loadRecommendations() }) {
                            Text("RETRY")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(Color.appPrimary)
                                .cornerRadius(20)
                        }
                    }
                    Spacer()
                } else if recommendations.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.appTextSecondary.opacity(0.3))
                        Text("Your inbox is empty")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.appTextSecondary)
                        Text("When friends nudge you with movies,\nthey'll show up here!")
                            .font(.system(size: 14))
                            .foregroundColor(.appTextSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        Button(action: { loadRecommendations() }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Check for updates")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.appPrimary)
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(recommendations) { recommendation in
                                NudgeRow(recommendation: recommendation) { reaction in
                                    updateReaction(recommendation, reaction: reaction)
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        loadRecommendations()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: loadRecommendations)
    }
    
    private func loadRecommendations() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetched = try await FirestoreService.shared.fetchRecommendations(userId: uid)
                await MainActor.run {
                    self.recommendations = fetched
                    self.isLoading = false
                }
            } catch {
                print("Error loading recommendations: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func updateReaction(_ recommendation: MovieRecommendation, reaction: String) {
        guard let id = recommendation.id else { return }
        Task {
            do {
                try await FirestoreService.shared.updateRecommendationReaction(recommendationId: id, reaction: reaction)
                // Local update
                if let index = recommendations.firstIndex(where: { $0.id == id }) {
                    await MainActor.run {
                        recommendations[index].reaction = reaction
                        recommendations[index].isRead = true
                    }
                }
            } catch {
                print("Error updating reaction: \(error)")
            }
        }
    }
}

struct NudgeRow: View {
    let recommendation: MovieRecommendation
    let onReact: (String) -> Void
    
    @State private var showReactionPicker = false
    let reactions = ["🍿", "🎬", "🔥", "❤️", "👍", "😮", "😴"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User & Time
            HStack(spacing: 12) {
                if let photo = recommendation.senderPhoto, let url = URL(string: photo) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.white.opacity(0.1))
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.senderName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appPrimary)
                    Text("nudged you")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                Text(recommendation.timestamp.timeAgoDisplay())
                    .font(.system(size: 10))
                    .foregroundColor(.appTextSecondary)
            }
            
            // Movie Box
            NavigationLink(destination: MovieDetailView(movieId: recommendation.movieId)) {
                HStack(spacing: 12) {
                    if let poster = recommendation.moviePoster, let url = URL(string: "https://image.tmdb.org/t/p/w200\(poster)") {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.white.opacity(0.05)
                        }
                        .frame(width: 50, height: 75)
                        .cornerRadius(6)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.movieTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appText)
                            .lineLimit(1)
                        
                        if !recommendation.note.isEmpty {
                            Text("\"\(recommendation.note)\"")
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .italic()
                                .foregroundColor(.appTextSecondary)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Reaction Bar
            HStack {
                if let reaction = recommendation.reaction {
                    Text("Sent: \(reaction)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.appPrimary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.appPrimary.opacity(0.1))
                        .cornerRadius(20)
                } else {
                    Button(action: { showReactionPicker.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "face.smiling")
                            Text("Reaction")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.appTextSecondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                    }
                }
                Spacer()
            }
            
            if showReactionPicker {
                HStack(spacing: 12) {
                    ForEach(reactions, id: \.self) { reaction in
                        Button(action: {
                            onReact(reaction)
                            showReactionPicker = false
                        }) {
                            Text(reaction)
                                .font(.system(size: 24))
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(recommendation.isRead ? Color.clear : Color.appPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}
