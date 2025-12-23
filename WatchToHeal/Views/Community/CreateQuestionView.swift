import SwiftUI

struct CreateQuestionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var text: String = ""
    @State private var isSubmitting = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("WHAT'S ON YOUR MIND?")
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundColor(.appPrimary)
                    
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Start a cinematic debate or ask a question...")
                                .font(.system(size: 18))
                                .foregroundColor(.appTextSecondary.opacity(0.4))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $text)
                            .font(.system(size: 18))
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.appText)
                            .frame(maxHeight: .infinity)
                    }
                }
                .padding(24)
                
                Spacer()
                
                publishButton
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.appTextSecondary)
            
            Spacer()
            
            Text("NEW DEBATE")
                .font(.system(size: 14, weight: .black))
                .tracking(3)
                .foregroundColor(.appText)
            
            Spacer()
            
            Button("Cancel") {}.opacity(0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
    
    private var publishButton: some View {
        Button(action: postQuestion) {
            HStack(spacing: 12) {
                if isSubmitting {
                    ProgressView().tint(.black)
                } else {
                    Image(systemName: "sparkles")
                    Text("SPARK DEBATE")
                }
            }
            .font(.system(size: 14, weight: .black))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(!text.isEmpty && !isSubmitting ? Color.appPrimary : Color.white.opacity(0.1))
            .cornerRadius(28)
            .padding(24)
        }
        .disabled(text.isEmpty || isSubmitting)
    }
    
    private func postQuestion() {
        guard let profile = appViewModel.userProfile else { return }
        isSubmitting = true
        
        let question = CommunityQuestion(
            text: text,
            creatorId: profile.id,
            creatorName: profile.name,
            creatorUsername: profile.username ?? profile.name,
            creatorPhotoURL: profile.photoURL?.absoluteString,
            createdAt: Date()
        )
        
        Task {
            do {
                try await FirestoreService.shared.createQuestion(question: question)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error creating question: \(error)")
                isSubmitting = false
            }
        }
    }
}
