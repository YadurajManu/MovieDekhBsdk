import SwiftUI

struct EraStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    let eras = ["90s Classics", "Early 2000s", "Post-2015", "Old School (B&W)"]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Which era pulls you in?")
                .font(.title2)
                .bold()
                .foregroundColor(.appText)
                .padding(.top, 40)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(eras, id: \.self) { era in
                            Button(action: {
                                viewModel.selectedEra = era
                            }) {
                                HStack {
                                    Text(era)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Spacer()
                                    if viewModel.selectedEra == era {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.appPrimary)
                                    }
                                }
                                .padding(24)
                                .background(
                                    ZStack {
                                        // Dynamic background based on era could go here
                                        Color.appCardBackground
                                        if viewModel.selectedEra == era {
                                            Color.appPrimary.opacity(0.1)
                                        }
                                    }
                                )
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(viewModel.selectedEra == era ? Color.appPrimary : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            
            Button(action: { viewModel.moveToNextStep() }) {
                Text("Next")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.selectedEra != nil ? Color.appPrimary : Color.gray)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .disabled(viewModel.selectedEra == nil)
            .padding([.horizontal, .bottom])
        }
    }
}
