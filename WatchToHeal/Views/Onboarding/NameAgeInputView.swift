import SwiftUI

struct NameAgeInputView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Let's get to know you")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.appText)
                
                Text("We'll personalize your experience based on your details.")
                    .font(.system(size: 16))
                    .foregroundColor(.appTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
            
            // Inputs
            VStack(spacing: 24) {
                // Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("What should we call you?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                    
                    TextField("", text: $viewModel.name)
                        .placeholder(when: viewModel.name.isEmpty) {
                            Text("Enter your name")
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.appText)
                        .padding()
                        .frame(height: 54)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                
                // Age Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("How old are you?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                    
                    TextField("", text: $viewModel.age)
                        .placeholder(when: viewModel.age.isEmpty) {
                            Text("Enter your age")
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .keyboardType(.numberPad)
                        .font(.system(size: 16))
                        .foregroundColor(.appText)
                        .padding()
                        .frame(height: 54)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
            }
            
            Spacer()
            
            // Next Button
            Button(action: {
                // Dismiss keyboard
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                viewModel.moveToNextStep()
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(viewModel.isStep1Valid ? Color.appPrimary : Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!viewModel.isStep1Valid)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
