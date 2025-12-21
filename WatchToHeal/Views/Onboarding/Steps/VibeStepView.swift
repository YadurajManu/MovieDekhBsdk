import SwiftUI

struct VibeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Pick the vibe you'd watch right now.")
                .font(.title2)
                .bold()
                .foregroundColor(.appText)
                .padding(.top, 40)
            
            Spacer()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                    ForEach(viewModel.vibes, id: \.self) { vibe in
                        Button(action: {
                            viewModel.selectedVibe = vibe
                        }) {
                            Text(vibe)
                                .fontWeight(.medium)
                                .foregroundColor(viewModel.selectedVibe == vibe ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(viewModel.selectedVibe == vibe ? Color.appPrimary : Color.appCardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .scaleEffect(viewModel.selectedVibe == vibe ? 1.02 : 1.0)
                                .animation(.spring(response: 0.3), value: viewModel.selectedVibe)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            
            Spacer()
            
            Button(action: { viewModel.moveToNextStep() }) {
                Text("Next")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.selectedVibe != nil ? Color.appPrimary : Color.gray)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .disabled(viewModel.selectedVibe == nil)
            .padding([.horizontal, .bottom])
        }
    }
}
