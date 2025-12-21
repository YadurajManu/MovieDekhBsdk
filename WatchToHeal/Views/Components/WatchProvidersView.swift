import SwiftUI

struct WatchProvidersView: View {
    let providers: TMDBService.WatchProvidersResponse.CountryProviders
    var preferredProviderIds: Set<Int> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let flatrate = providers.flatrate, !flatrate.isEmpty {
                ProviderPremiumRow(title: "STREAM", providers: flatrate, preferredIds: preferredProviderIds)
            }
            if let rent = providers.rent, !rent.isEmpty {
                ProviderPremiumRow(title: "RENT", providers: rent, preferredIds: preferredProviderIds)
            }
            if let buy = providers.buy, !buy.isEmpty {
                ProviderPremiumRow(title: "BUY", providers: buy, preferredIds: preferredProviderIds)
            }
            
            // JustWatch Link
            if let link = providers.link {
                Link(destination: URL(string: link)!) {
                    HStack {
                        Text("View all on JustWatch")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appPrimary)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.appPrimary)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

struct ProviderPremiumRow: View {
    let title: String
    let providers: [TMDBService.WatchProvidersResponse.Provider]
    var preferredIds: Set<Int> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.appTextSecondary)
                .kerning(1)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(providers) { provider in
                        VStack(spacing: 6) {
                            let isPreferred = preferredIds.contains(provider.id)
                            
                            CachedAsyncImage(url: provider.logoURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1))
                            }
                            .frame(width: 44, height: 44)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isPreferred ? Color.appPrimary : Color.clear, lineWidth: 2)
                            )
                            .shadow(color: isPreferred ? .appPrimary.opacity(0.3) : .black.opacity(0.2), radius: 5, y: 3)
                            
                            Text(provider.providerName)
                                .font(.system(size: 8, weight: isPreferred ? .black : .medium))
                                .foregroundColor(isPreferred ? .appPrimary : .appTextSecondary)
                                .lineLimit(1)
                                .frame(width: 44)
                        }
                    }
                }
            }
        }
    }
}
