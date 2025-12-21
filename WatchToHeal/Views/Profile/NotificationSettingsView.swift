import SwiftUI
import FirebaseAuth
struct NotificationSettingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var isEnabled: Bool = true
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Stay updated with new releases and personalized healing recommendations.")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 8)
                    
                    GlassCard {
                        VStack(spacing: 0) {
                            Toggle(isOn: $isEnabled) {
                                HStack(spacing: 16) {
                                    Image(systemName: "bell.badge.fill")
                                        .foregroundColor(.appPrimary)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Push Notifications")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.appText)
                                        Text("Alerts for upcoming movies")
                                            .font(.caption)
                                            .foregroundColor(.appTextSecondary)
                                    }
                                }
                            }
                            .padding()
                            .tint(.appPrimary)
                            .onChange(of: isEnabled) { oldValue, newValue in
                                updateSettings(newValue)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            isEnabled = appViewModel.userProfile?.isNotificationEnabled ?? true
        }
    }
    
    private func updateSettings(_ newValue: Bool) {
        guard let userId = appViewModel.currentUser?.uid else { return }
        
        Task {
            do {
                try await FirestoreService.shared.updateUserProfile(userId: userId, data: ["isNotificationEnabled": newValue])
                await MainActor.run {
                    appViewModel.userProfile?.isNotificationEnabled = newValue
                }
            } catch {
                print("Error updating notification settings: \(error)")
            }
        }
    }
}
