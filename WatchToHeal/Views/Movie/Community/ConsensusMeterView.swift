import SwiftUI

struct ConsensusMeterView: View {
    let stats: MovieSocialStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("COMMUNITY CONSENSUS")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundColor(.appPrimary)
                Spacer()
                Text("\(stats.totalVotes) VOTES")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
            }
            
            if stats.totalVotes == 0 {
                Text("No consensus yet. Be the first to pulse!")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                HStack(spacing: 24) {
                    // Meter
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.04), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: stats.consensusScore)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [.red, .orange, .appPrimary]),
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360)
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: -2) {
                            Text("\(stats.approvalRating)%")
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(.white)
                            Text("LIKED")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(stats.consensusLabel)
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(getColor(stats.consensusColor))
                        
                        Text("Based on community reviews and Cine-Scale ratings.")
                            .font(.system(size: 11))
                            .foregroundColor(.appTextSecondary.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 12) {
                            statMini(label: "ABSOLUTE", count: stats.ratingCounts["absolute"] ?? 0)
                            statMini(label: "AWAARA", count: stats.ratingCounts["awaara"] ?? 0)
                            statMini(label: "BAKWAS", count: stats.ratingCounts["bakwas"] ?? 0)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 8)
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
    
    private func statMini(label: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .black))
                .foregroundColor(.white.opacity(0.3))
            Text("\(count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private func getColor(_ name: String) -> Color {
        switch name {
        case "appPrimary": return .appPrimary
        case "orange": return .orange
        case "red": return .red
        default: return .appPrimary
        }
    }
}
