import SwiftUI

struct CineScaleRatingView: View {
    @Binding var selectedRating: String?
    let onRatingSelected: (String) -> Void
    
    private let ratings = [
        (id: "absolute", title: "GoForIt", subtitle: "Must watch", color: Color.appPrimary, icon: "crown.fill"),
        (id: "awaara", title: "SoSo", subtitle: "Worth a try", color: Color.blue, icon: "hand.thumbsup.fill"),
        (id: "bakwas", title: "Bakwas", subtitle: "Hard pass", color: Color.red, icon: "hand.thumbsdown.fill")
    ]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(ratings, id: \.id) { rating in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        selectedRating = rating.id
                        onRatingSelected(rating.id)
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: rating.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(selectedRating == rating.id ? rating.color : .white.opacity(0.4))
                        
                        VStack(spacing: 1) {
                            Text(rating.title.uppercased())
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(selectedRating == rating.id ? rating.color : .white)
                            
                            Text(rating.subtitle)
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedRating == rating.id ? rating.color.opacity(0.12) : Color.white.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedRating == rating.id ? rating.color.opacity(0.4) : Color.white.opacity(0.04), lineWidth: 1)
                    )
                }
                .scaleEffect(selectedRating == rating.id ? 1.03 : 1.0)
            }
        }
    }
}
