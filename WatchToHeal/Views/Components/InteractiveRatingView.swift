import SwiftUI

struct InteractiveRatingView: View {
    @Binding var rating: Int?
    var starSize: CGFloat = 20
    var starSpacing: CGFloat = 4
    var activeColor: Color = .yellow
    var inactiveColor: Color = .white.opacity(0.15)
    var onRatingChanged: ((Int) -> Void)? = nil
    
    @State private var hoverRating: Int? = nil
    private let haptic = UISelectionFeedbackGenerator()
    
    var body: some View {
        HStack(spacing: starSpacing) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: isStarActive(index) ? "star.fill" : "star")
                    .font(.system(size: starSize, weight: .bold))
                    .foregroundColor(isStarActive(index) ? activeColor : inactiveColor)
                    .scaleEffect(isStarActive(index) ? 1.2 : 1.0)
                    .shadow(color: isStarActive(index) ? activeColor.opacity(0.5) : .clear, radius: 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            rating = index
                            haptic.selectionChanged()
                            onRatingChanged?(index)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hoverRating)
            }
        }
    }
    
    private func isStarActive(_ index: Int) -> Bool {
        if let hover = hoverRating {
            return index <= hover
        }
        if let current = rating {
            return index <= current
        }
        return false
    }
}

#Preview {
    VStack(spacing: 40) {
        InteractiveRatingView(rating: .constant(3), starSize: 30)
        InteractiveRatingView(rating: .constant(nil), starSize: 40)
    }
    .preferredColorScheme(.dark)
}
