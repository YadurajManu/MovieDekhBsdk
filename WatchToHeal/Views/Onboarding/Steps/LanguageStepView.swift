import SwiftUI

struct LanguageStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    let options = ["Love them (World Cinema)", "Fine if the movie is good", "Avoid if possible"]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Subtitles?")
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.appText)
                Text("Be honest, this helps us recommend better.")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.top, 40)
            
            VStack(spacing: 16) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        viewModel.subtitlePreference = option
                    }) {
                        Text(option)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.subtitlePreference == option ? Color.appPrimary : Color.clear, lineWidth: 2)
                            )
                    }
                }
            }
            .padding()
            
            Spacer()
            
            Button(action: { viewModel.moveToNextStep() }) {
                Text("Next")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.subtitlePreference != nil ? Color.appPrimary : Color.gray)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .disabled(viewModel.subtitlePreference == nil)
            .padding([.horizontal, .bottom])
        }
    }
}
