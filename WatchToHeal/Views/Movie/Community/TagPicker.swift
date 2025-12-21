import SwiftUI

struct TagPicker: View {
    @Binding var selectedTags: Set<String>
    let selectedRating: String?
    
    private var availableTags: [String] {
        switch selectedRating {
        case "absolute":
            return ["Masterpiece", "Aesthetic", "Cerebral", "Mind-bending", "Must-Watch"]
        case "awaara":
            return ["Entertaining", "Decent", "Average", "Comfort Watch", "Mixed Bag"]
        case "bakwas":
            return ["Boring", "Cringe", "Skip It", "Overrated", "Trash"]
        default:
            return ["Hidden Gem", "Heart-wrenching", "Adrenaline", "Masterpiece", "Aesthetic"]
        }
    }
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(availableTags, id: \.self) { tag in
                Button(action: {
                    if selectedTags.contains(tag) {
                        selectedTags.remove(tag)
                    } else {
                        if selectedTags.count < 3 {
                            selectedTags.insert(tag)
                        }
                    }
                }) {
                    Text(tag)
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedTags.contains(tag) ? Color.appPrimary : Color.white.opacity(0.04))
                        .foregroundColor(selectedTags.contains(tag) ? .black : .white.opacity(0.6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedTags.contains(tag) ? Color.appPrimary : Color.white.opacity(0.06), lineWidth: 1)
                        )
                }
            }
        }
    }
}
