import SwiftUI

struct GenrePulseView: View {
    let consensus: [String: Int]
    let totalVotes: Int
    
    private let availableTags = [
        ("Aesthetic", "sparkles"),
        ("Mind-bending", "brain.headset"),
        ("Hidden Gem", "diamond.fill"),
        ("Comfort Watch", "couch.fill"),
        ("Heart-wrenching", "heart.broken.fill"),
        ("Adrenaline", "bolt.fill"),
        ("Cerebral", "lightbulb.fill"),
        ("Masterpiece", "star.square.fill")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("GENRE PULSE")
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundColor(.appPrimary)
            
            if totalVotes == 0 {
                Text("No consensus yet. Be the first to pulse!")
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 12) {
                    ForEach(availableTags, id: \.0) { tag, icon in
                        let count = consensus[tag] ?? 0
                        let percentage = totalVotes == 0 ? 0 : Double(count) / Double(totalVotes)
                        
                        HStack(spacing: 12) {
                            Image(systemName: icon)
                                .font(.system(size: 14))
                                .foregroundColor(count > 0 ? .appPrimary : .appTextSecondary.opacity(0.3))
                                .frame(width: 20)
                            
                            Text(tag.uppercased())
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(count > 0 ? .appText : .appTextSecondary.opacity(0.3))
                            
                            Spacer()
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.05))
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.appPrimary)
                                        .frame(width: geo.size.width * CGFloat(percentage))
                                }
                            }
                            .frame(height: 8)
                            .frame(width: 100)
                            
                            Text("\(Int(percentage * 100))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(count > 0 ? .appPrimary : .appTextSecondary.opacity(0.3))
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
