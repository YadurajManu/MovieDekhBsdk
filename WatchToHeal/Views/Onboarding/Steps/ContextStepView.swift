import SwiftUI

struct ContextStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Pick a night. Pick a movie.")
                .font(.title2)
                .bold()
                .foregroundColor(.appText)
                .padding(.top, 40)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(viewModel.contextOptions, id: \.self) { context in
                        Button(action: {
                            viewModel.selectedContext = context
                        }) {
                            Text(context)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(viewModel.selectedContext == context ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(viewModel.selectedContext == context ? Color.appPrimary : Color.appCardBackground)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
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
                    .background(viewModel.selectedContext != nil ? Color.appPrimary : Color.gray)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .disabled(viewModel.selectedContext == nil)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}
