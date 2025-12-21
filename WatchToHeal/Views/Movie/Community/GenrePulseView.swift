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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("GENRE PULSE")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundColor(.appPrimary)
                Spacer()
                if totalVotes > 0 {
                    Text("\(totalVotes) VOTES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            if totalVotes == 0 {
                Text("No consensus yet. Be the first to pulse!")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(availableTags, id: \.0) { tag, icon in
                        let count = consensus[tag] ?? 0
                        let percentage = totalVotes == 0 ? 0 : Double(count) / Double(totalVotes)
                        
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(count > 0 ? Color.appPrimary.opacity(0.1) : Color.white.opacity(0.04))
                                    .frame(width: 24, height: 24)
                                Image(systemName: icon)
                                    .font(.system(size: 10))
                                    .foregroundColor(count > 0 ? .appPrimary : .white.opacity(0.2))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tag.uppercased())
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(count > 0 ? .appText : .white.opacity(0.2))
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.white.opacity(0.05))
                                        
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.appPrimary)
                                            .frame(width: geo.size.width * CGFloat(percentage))
                                    }
                                }
                                .frame(height: 3)
                            }
                            
                            Text("\(Int(percentage * 100))%")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(count > 0 ? .appPrimary : .white.opacity(0.2))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.02))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
}
