import SwiftUI

struct NameAgeInputView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            // Visual Anchor - Subtle Top Gradient to fill negative space
            LinearGradient(
                stops: [
                    .init(color: .appPrimary.opacity(0.15), location: 0),
                    .init(color: .clear, location: 0.4)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .frame(height: 300)
            
            VStack(spacing: 0) {
                // Header & Microcopy
                VStack(alignment: .leading, spacing: 12) {
                    Text("TAKES ONLY 10 SECONDS")
                        .font(.system(size: 10, weight: .black))
                        .kerning(1)
                        .foregroundColor(.appPrimary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Let's get to know you")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.appText)
                        
                        Text("This helps us tailor your movie recommendations to your taste.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .lineSpacing(4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
                .padding(.bottom, 48)
                
                // Inputs
                VStack(spacing: 24) {
                    // Name Input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("WHAT SHOULD WE CALL YOU?")
                            .font(.system(size: 10, weight: .black))
                            .kerning(1)
                            .foregroundColor(.white.opacity(0.4))
                        
                        TextField("", text: $viewModel.name)
                            .placeholder(when: viewModel.name.isEmpty) {
                                Text("Name")
                                    .foregroundColor(.white.opacity(0.2))
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appText)
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    
                    // Age Input
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("HOW OLD ARE YOU?")
                                .font(.system(size: 10, weight: .black))
                                .kerning(1)
                                .foregroundColor(.white.opacity(0.4))
                            Spacer()
                            Text("For age-appropriate suggestions")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.appPrimary.opacity(0.6))
                        }
                        
                        TextField("", text: $viewModel.age)
                            .placeholder(when: viewModel.age.isEmpty) {
                                Text("Age")
                                    .foregroundColor(.white.opacity(0.2))
                            }
                            .keyboardType(.numberPad)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appText)
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                }
                
                Spacer()
                
                // Bottom Actions
                VStack(spacing: 20) {
                    Text("You can always update these in settings later")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                    
                    // Next Button
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        viewModel.moveToNextStep()
                    }) {
                        Text("CONTINUE")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(viewModel.isStep1Valid ? .black : .white.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(viewModel.isStep1Valid ? Color.appPrimary : Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: viewModel.isStep1Valid ? Color.appPrimary.opacity(0.3) : .clear, radius: 10, y: 5)
                    }
                    .disabled(!viewModel.isStep1Valid)
                    
                    Button(action: { 
                        // Skip logic or just move next
                        viewModel.moveToNextStep() 
                    }) {
                        Text("Skip for now")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(.bottom, 10)
                }
            }
            .padding(.horizontal, 24)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
