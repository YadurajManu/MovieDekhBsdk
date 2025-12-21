import SwiftUI
import FirebaseAuth
struct PreferenceSettingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showAdult: Bool = false
    @State private var selectedRegion: String = "US"
    
    let regions = [
        "US": "United States",
        "IN": "India",
        "GB": "United Kingdom",
        "JP": "Japan",
        "KR": "South Korea",
        "FR": "France"
    ]
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CONTENT PREFERENCES")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.appTextSecondary)
                            .padding(.leading, 8)
                        
                        GlassCard {
                            VStack(spacing: 0) {
                                Toggle(isOn: $showAdult) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "exclamationmark.shield.fill")
                                            .foregroundColor(.appPrimary)
                                            .frame(width: 24)
                                        Text("Adult Content (18+)")
                                            .foregroundColor(.appText)
                                    }
                                }
                                .padding()
                                .tint(.appPrimary)
                                .onChange(of: showAdult) { oldValue, newValue in
                                    updatePreferences(key: "showAdultContent", value: newValue)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("REGIONAL SETTINGS")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.appTextSecondary)
                            .padding(.leading, 8)
                        
                        GlassCard {
                            VStack(spacing: 0) {
                                Picker(selection: $selectedRegion) {
                                    ForEach(regions.keys.sorted(), id: \.self) { key in
                                        Text(regions[key] ?? "").tag(key)
                                    }
                                } label: {
                                    HStack(spacing: 16) {
                                        Image(systemName: "globe")
                                            .foregroundColor(.appPrimary)
                                            .frame(width: 24)
                                        Text("Streaming Region")
                                            .foregroundColor(.appText)
                                    }
                                }
                                .pickerStyle(.navigationLink)
                                .padding()
                                .onChange(of: selectedRegion) { oldValue, newValue in
                                    updatePreferences(key: "preferredRegion", value: newValue)
                                }
                            }
                        }
                        
                        Text("This affects the streaming availability and upcoming releases shown to you.")
                            .font(.caption2)
                            .foregroundColor(.appTextSecondary)
                            .padding(.horizontal, 8)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Preferences")
        .onAppear {
            if let profile = appViewModel.userProfile {
                showAdult = profile.showAdultContent
                selectedRegion = profile.preferredRegion
            }
        }
    }
    
    private func updatePreferences(key: String, value: Any) {
        guard let userId = appViewModel.currentUser?.uid else { return }
        
        Task {
            do {
                try await FirestoreService.shared.updateUserProfile(userId: userId, data: [key: value])
                await MainActor.run {
                    if key == "showAdultContent" { appViewModel.userProfile?.showAdultContent = value as! Bool }
                    if key == "preferredRegion" { appViewModel.userProfile?.preferredRegion = value as! String }
                }
            } catch {
                print("Error updating preferences: \(error)")
            }
        }
    }
}
