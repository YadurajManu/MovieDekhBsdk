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
                            
                            // Tags Cloud
                            if !list.tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(list.tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.system(size: 10, weight: .black))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(Color.appPrimary.opacity(0.1))
                                                .foregroundColor(.appPrimary)
                                                .cornerRadius(6)
                                        }
                                    }
                                }
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
                            
                            if list.isRanked {
                                Label("RANKED", systemImage: "list.number")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.appPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.appPrimary.opacity(0.1))
                                    .cornerRadius(20)
                            }
                            
                            if list.isFeatured {
                                HStack(spacing: 4) {
                                    Image(systemName: "pin.fill")
                                    Text("STAFF PICK")
                                }
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Movie List - Premium Vertical Layout
                        VStack(spacing: 16) {
                            ForEach(Array(list.movies.enumerated()), id: \.offset) { index, movie in
                                NavigationLink(destination: MovieDetailView(movieId: movie.id)) {
                                    DetailedMovieListRow(movie: movie, index: index + 1, isRanked: list.isRanked)
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
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isLiked.toggle()
            internalLikeCount += isLiked ? 1 : -1
        }
        
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
    var index: Int = 0
    var isRanked: Bool = false
    
    var body: some View {
        HStack(spacing: 14) {
            if isRanked {
                Text(String(format: "%02d", index))
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white.opacity(0.15))
                    .frame(width: 44, alignment: .leading)
                    .lineLimit(1)
            }
            
            if let url = movie.posterURL {
                CachedAsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10).fill(Color.appCardBackground)
                }
                .frame(width: 60, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.displayName)
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
