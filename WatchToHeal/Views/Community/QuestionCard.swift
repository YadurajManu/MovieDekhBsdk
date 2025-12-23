import SwiftUI

struct QuestionCard: View {
    let question: CommunityQuestion
    var onLike: () -> Void
    var onTap: () -> Void
    @EnvironmentObject var appViewModel: AppViewModel
    
    private var isLiked: Bool {
        guard let userId = appViewModel.userProfile?.id else { return false }
        return question.likedUserIds.contains(userId)
    }
    
    var body: some View {
        Button(action: onTap) {
            GlassCard(cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    // Identity
                    HStack(spacing: 10) {
                        if let photo = question.creatorPhotoURL, let url = URL(string: photo) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.white.opacity(0.1)
                            }
                            .frame(width: 26, height: 26)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.appPrimary.opacity(0.2))
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.appPrimary)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(question.creatorUsername)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.appText)
                            
                            Text("CINE-DEBATE")
                                .font(.system(size: 9, weight: .black))
                                .tracking(0.5)
                                .foregroundColor(.appPrimary)
                        }
                        
                        Spacer()
                        
                        Text(question.createdAt, style: .relative)
                            .font(.system(size: 9))
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    // Question Text
                    Text(question.text)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appText)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                    
                    // Footer
                    HStack(spacing: 20) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onLike()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 13))
                                    .foregroundColor(isLiked ? .red : .appTextSecondary)
                                Text("\(question.likeCount)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        
                        HStack(spacing: 5) {
                            Image(systemName: "bubble.left.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)
                            Text("\(question.replyCount)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.appTextSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.appTextSecondary.opacity(0.5))
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
