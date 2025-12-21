import SwiftUI

struct PersonCardView: View {
    let person: SearchResult
    
    var body: some View {
        VStack(spacing: 8) {
            CachedAsyncImage(url: person.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 30))
                    )
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 4) {
                Text(person.displayTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text("Person")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: 110)
        .padding(8)
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
}
