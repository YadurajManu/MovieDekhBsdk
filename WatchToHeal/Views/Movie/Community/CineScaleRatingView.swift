import SwiftUI

struct CineScaleRatingView: View {
    @Binding var selectedRating: String?
    let onRatingSelected: (String) -> Void
    
    private let ratings = [
        ("absolute", "ABSOLUTE CINEMA", Color.orange, "crown.fill"),
        ("awaara", "AWAARA CINEMA", Color.blue, "person.fill.questionmark"),
        ("bakwas", "BAKWAS CINEMA", Color.red, "trash.fill")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("RATE THE VIBE")
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundColor(.appPrimary)
            
            HStack(spacing: 12) {
                ForEach(ratings, id: \.0) { id, label, color, icon in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedRating = id
                            onRatingSelected(id)
                        }
                    }) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(selectedRating == id ? color : Color.white.opacity(0.05))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(selectedRating == id ? .black : .white)
                            }
                            
                            Text(label.split(separator: " ").first ?? "")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(selectedRating == id ? color : .appTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedRating == id ? color.opacity(0.1) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedRating == id ? color.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .scaleEffect(selectedRating == id ? 1.05 : 1.0)
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(24)
    }
}
