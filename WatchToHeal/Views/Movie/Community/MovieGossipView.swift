import SwiftUI

struct MovieGossipView: View {
    let reviews: [MovieReview]
    @Binding var newReviewContent: String
    let onPost: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("MOVIE GOSSIP")
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundColor(.appPrimary)
            
            // Post Comment Box
            VStack(spacing: 12) {
                TextField("Spill the beans... what did you think?", text: $newReviewContent, axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundColor(.appText)
                    .padding()
                    .frame(minHeight: 80, alignment: .top)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                
                HStack {
                    Spacer()
                    Button(action: onPost) {
                        Text("POST GOSSIP")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.appPrimary)
                            .cornerRadius(20)
                    }
                    .disabled(newReviewContent.isEmpty)
                    .opacity(newReviewContent.isEmpty ? 0.5 : 1.0)
                }
            }
            .padding(.bottom, 10)
            
            // Reviews List
            if reviews.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.appPrimary.opacity(0.2))
                    Text("Silence in the theater... start the gossip!")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 16) {
                    ForEach(reviews) { review in
                        ReviewRow(review: review)
                    }
                }
            }
        }
    }
}

struct ReviewRow: View {
    let review: MovieReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if let photoURL = review.userPhoto, let url = URL(string: photoURL) {
                    CachedAsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.appCardBackground)
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.appTextSecondary.opacity(0.3))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.username)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appText)
                    Text(review.timestamp, style: .relative)
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                let color = colorForRating(review.rating)
                Text(review.rating.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text(review.content)
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
                .lineSpacing(4)
            
            if !review.genreTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(review.genreTags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.appPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.appPrimary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func colorForRating(_ rating: String) -> Color {
        switch rating {
        case "absolute": return .orange
        case "awaara": return .blue
        case "bakwas": return .red
        default: return .appTextSecondary
        }
    }
}
