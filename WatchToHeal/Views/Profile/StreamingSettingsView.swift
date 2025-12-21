import SwiftUI

struct StreamingSettingsView: View {
    @StateObject private var viewModel = StreamingSettingsViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STREAMING SERVICES")
                            .font(.system(size: 11, weight: .black))
                            .tracking(2)
                            .foregroundColor(.appPrimary)
                        Text("Your Platforms")
                            .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 32))
                            .foregroundColor(.appText)
                    }
                    .padding(.leading, 12)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.appTextSecondary)
                    TextField("Search providers...", text: $viewModel.searchQuery)
                        .foregroundColor(.appText)
                        .textFieldStyle(.plain)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                if viewModel.isLoading && viewModel.providers.isEmpty {
                    ProgressView().tint(.appPrimary).frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("SELECT YOUR SUBSCRIPTIONS")
                                .font(.system(size: 10, weight: .black))
                                .tracking(2)
                                .foregroundColor(.appTextSecondary)
                                .padding(.horizontal, 24)
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.filteredProviders) { provider in
                                    ProviderCard(
                                        provider: provider,
                                        isSelected: viewModel.selectedProviderIds.contains(provider.id),
                                        action: { viewModel.toggleProvider(provider.id) }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 120)
                    }
                }
            }
            
            // Bottom Save Bar
            VStack {
                Spacer()
                
                Button(action: {
                    Task {
                        if let userId = appViewModel.userProfile?.id {
                            await viewModel.savePreferences(userId: userId)
                            appViewModel.fetchUserProfile() // Refresh local profile
                            dismiss()
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView().tint(.black)
                        } else {
                            Text("Save Preferences")
                                .font(.system(size: 16, weight: .bold))
                            Image(systemName: "checkmark.seal.fill")
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
                    .shadow(color: .appPrimary.opacity(0.4), radius: 20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100) // Increased to avoid custom bottom tab bar
                .background(
                    LinearGradient(
                        colors: [.appBackground.opacity(0), .appBackground.opacity(0.9), .appBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .task {
            let current = appViewModel.userProfile?.streamingProviders ?? []
            let region = appViewModel.userProfile?.preferredRegion ?? "US"
            await viewModel.loadProviders(currentSelected: current, region: region)
        }
        .navigationBarHidden(true)
    }
}

struct ProviderCard: View {
    let provider: TMDBService.WatchProvidersResponse.Provider
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    CachedAsyncImage(url: provider.logoURL) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.white.opacity(0.1)
                    }
                    .frame(width: 64, height: 64)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                    
                    if isSelected {
                        // More premium selection overlay
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.appPrimary.opacity(0.2))
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .background(Circle().fill(Color.appPrimary))
                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                            .shadow(radius: 5)
                    }
                }
                
                Text(provider.providerName)
                    .font(.system(size: 11, weight: isSelected ? .black : .bold))
                    .foregroundColor(isSelected ? .appPrimary : .appTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 30)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isSelected ? Color.appPrimary.opacity(0.08) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? Color.appPrimary : Color.white.opacity(0.05), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
