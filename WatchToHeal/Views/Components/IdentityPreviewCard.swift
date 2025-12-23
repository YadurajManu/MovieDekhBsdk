import SwiftUI
import FirebaseAuth

struct IdentityPreviewCard: View {
    let username: String
    let bio: String
    let persona: CinematicPersona?
    let photoURL: URL?
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                // Profile Photo
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.appPrimary, .appPrimary.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    AsyncImage(url: photoURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .foregroundColor(.black.opacity(0.5))
                            .font(.system(size: 24))
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(username.isEmpty ? "username" : username)
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.appText)
                        
                        if let persona = persona {
                            Text(persona.rawValue)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.appPrimary.opacity(0.2))
                                .foregroundColor(.appPrimary)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(bio.isEmpty ? "Your cinematic journey begins here..." : bio)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(16)
        }
        .frame(height: 100)
    }
}
