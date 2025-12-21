import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack {
                // Header (Back Button & Progress)
                HStack(spacing: 16) {
                    if viewModel.currentStep != .personalDetails {
                        Button(action: {
                            viewModel.moveToPreviousStep()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.appText)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                    } else {
                        Button(action: {
                            appViewModel.signOut()
                        }) {
                            Text("Exit")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.appTextSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                    }
                    
                    // Progress Bar
                    HStack(spacing: 4) {
                        ForEach(0..<OnboardingStep.allCases.count, id: \.self) { index in
                            Rectangle()
                                .fill(index <= viewModel.currentStep.rawValue ? Color.appPrimary : Color.appCardBackground)
                                .frame(height: 4)
                                .cornerRadius(2)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                // Steps
                TabView(selection: $viewModel.currentStep) {
                    NameAgeInputView(viewModel: viewModel)
                        .tag(OnboardingStep.personalDetails)
                    
                    RecognitionStepView(viewModel: viewModel)
                        .tag(OnboardingStep.recognition)
                    
                    PolarityStepView(viewModel: viewModel)
                        .tag(OnboardingStep.polarity)
                    
                    ContextStepView(viewModel: viewModel)
                        .tag(OnboardingStep.context)
                    
                    ActorStepView(viewModel: viewModel)
                        .tag(OnboardingStep.actors)
                    
                    DirectorStepView(viewModel: viewModel)
                        .tag(OnboardingStep.directors)
                    
                    VibeStepView(viewModel: viewModel)
                        .tag(OnboardingStep.vibe)
                    
                    EraStepView(viewModel: viewModel)
                        .tag(OnboardingStep.era)
                    
                    LanguageStepView(viewModel: viewModel)
                        .tag(OnboardingStep.language)
                        
                    CompetitionStepView(viewModel: viewModel)
                        .tag(OnboardingStep.competition)
                    
                    RecommendationRevealView(viewModel: viewModel) {
                        viewModel.saveResults()
                        appViewModel.completeOnboarding()
                    }
                    .tag(OnboardingStep.result)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
            }
        }
    }
}
