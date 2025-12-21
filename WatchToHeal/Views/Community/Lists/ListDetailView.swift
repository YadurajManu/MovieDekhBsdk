import SwiftUI
import FirebaseAuth
struct ListDetailView: View {
    let list: CommunityList
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var comments: [Comment] = []
    @State private var showComments = false
    @State private var isLiked: Bool = false
    @State private var internalLikeCount: Int = 0
    
    init(list: CommunityList) {
        self.list = list
        _internalLikeCount = State(initialValue: list.likeCount)
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            // Subtle glow matching the list's mood
            Circle()
                .fill(Color.appPrimary.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: 100, y: -200)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.appText)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    
                    Spacer()
                    
                    Text("COMMUNITY LIST")
                        .font(.system(size: 10, weight: .black))
                        .tracking(2)
                        .foregroundColor(.appPrimary)
                    
                    Spacer()
                    
                    // Share Button
                    Button(action: { /* Share action */ }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(.appText)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Metadata
                        VStack(alignment: .leading, spacing: 16) {
                            Text(list.title)
                                .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 48))
                                .foregroundColor(.appText)
                                .lineLimit(2)
                            
                            HStack(spacing: 12) {
                                Text("Curated by")
                                    .font(.system(size: 14))
                                    .foregroundColor(.appTextSecondary)
                                
                                Text(list.ownerName)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.appPrimary)
                                
                                Spacer()
                                
                                Text("\(list.movies.count) Movies")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            
                            if !list.description.isEmpty {
                                Text(list.description)
                                    .font(.system(size: 15))
                                    .foregroundColor(.appTextSecondary)
                                    .lineSpacing(4)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Actions
                        HStack(spacing: 20) {
                            Button(action: { toggleLike() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                        .foregroundColor(isLiked ? .red : .white)
                                    Text("\(internalLikeCount)")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                            }
                            
                            Button(action: { showComments = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bubble.left")
                                    Text("\(list.commentCount)")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        // Movie List - Premium Vertical Layout
                        VStack(spacing: 12) {
                            ForEach(list.movies) { movie in
                                NavigationLink(destination: MovieDetailView(movieId: movie.id)) {
                                    DetailedMovieListRow(movie: movie)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showComments) {
            CommentsView(listId: list.id)
        }
        .onAppear {
            checkIfLiked()
        }
    }
    
    private func toggleLike() {
        guard let userId = appViewModel.currentUser?.uid else { return }
        isLiked.toggle()
        internalLikeCount += isLiked ? 1 : -1
        
        Task {
            try? await FirestoreService.shared.likeCommunityList(listId: list.id, userId: userId)
        }
    }
    
    private func checkIfLiked() {
        guard let userId = appViewModel.currentUser?.uid else { return }
        isLiked = list.likedBy.contains(userId)
    }
}

struct DetailedMovieListRow: View {
    let movie: Movie
    
    var body: some View {
        HStack(spacing: 14) {
            if let url = movie.posterURL {
                CachedAsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10).fill(Color.appCardBackground)
                }
                .frame(width: 60, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appText)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(movie.year)
                    Text("•")
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.appPrimary)
                            .font(.system(size: 12))
                        Text(String(format: "%.1f", movie.voteAverage))
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
                
                Text(movie.overview)
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary.opacity(0.6))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(.appTextSecondary.opacity(0.3))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04)))
    }
}
