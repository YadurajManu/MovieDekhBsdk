import SwiftUI

struct TagPicker: View {
    @Binding var selectedTags: Set<String>
    
    private let availableTags = [
        "Aesthetic", "Mind-bending", "Hidden Gem", "Comfort Watch",
        "Heart-wrenching", "Adrenaline", "Cerebral", "Masterpiece"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WHAT'S THE VIBE?")
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundColor(.appPrimary)
            
            FlowLayout(spacing: 10) {
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
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTags.contains(tag) ? Color.appPrimary : Color.white.opacity(0.05))
                            .foregroundColor(selectedTags.contains(tag) ? .black : .appTextSecondary)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(selectedTags.contains(tag) ? Color.appPrimary : Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            }
            
            Text("Select up to 3 tags")
                .font(.system(size: 10))
                .foregroundColor(.appTextSecondary.opacity(0.5))
        }
    }
}
