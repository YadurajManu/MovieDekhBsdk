import SwiftUI

struct CineScaleRatingView: View {
    @Binding var selectedRating: String?
    let onRatingSelected: (String) -> Void
    
    private let ratings = [
        (id: "absolute", title: "Loved", subtitle: "Absolute", color: Color.orange, icon: "heart.fill"),
        (id: "awaara", title: "Meh", subtitle: "Awaara", color: Color.blue, icon: "hand.thumbsup.fill"),
        (id: "bakwas", title: "Bad", subtitle: "Bakwas", color: Color.red, icon: "hand.thumbsdown.fill")
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
                    VStack(spacing: 6) {
                        Image(systemName: rating.icon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(selectedRating == rating.id ? rating.color : .white.opacity(0.4))
                        
                        VStack(spacing: 2) {
                            Text(rating.title.uppercased())
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(selectedRating == rating.id ? rating.color : .white)
                            
                            Text(rating.subtitle)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedRating == rating.id ? rating.color.opacity(0.15) : Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedRating == rating.id ? rating.color.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
                .scaleEffect(selectedRating == rating.id ? 1.05 : 1.0)
            }
        }
    }
}
