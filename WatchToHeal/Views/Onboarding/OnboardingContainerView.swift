import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("STEP \(viewModel.currentStep.rawValue + 1) OF \(OnboardingStep.allCases.count)")
                                .font(.system(size: 10, weight: .black))
                                .kerning(1)
                                .foregroundColor(.appPrimary)
                            
                            // Progress Segments
                            HStack(spacing: 4) {
                                ForEach(0..<OnboardingStep.allCases.count, id: \.self) { index in
                                    Capsule()
                                        .fill(index <= viewModel.currentStep.rawValue ? Color.appPrimary : Color.white.opacity(0.1))
                                        .frame(height: 6)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        
                        if viewModel.currentStep == .personalDetails {
                            Spacer()
                            Button(action: {
                                appViewModel.signOut()
                            }) {
                                Text("EXIT")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.white.opacity(0.4))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                        } else {
                            Spacer()
                            Button(action: {
                                viewModel.moveToPreviousStep()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(Color.white.opacity(0.05)))
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                
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
