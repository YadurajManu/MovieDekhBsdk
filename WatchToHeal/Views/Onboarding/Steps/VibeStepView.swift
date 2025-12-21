import SwiftUI

struct VibeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    private let groups: [(String, [String])] = [
        ("EMOTIONAL TONE", ["Dark", "Hopeful", "Comfort", "Romantic", "Funny", "Nostalgic"]),
        ("SENSORY EXPERIENCE", ["Weird", "Mind-bending", "Adrenaline", "Intellectual"])
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            // Visual Anchor
            LinearGradient(
                stops: [
                    .init(color: .appPrimary.opacity(0.1), location: 0),
                    .init(color: .clear, location: 0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .frame(height: 300)
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("PICK THE VIBE FOR RIGHT NOW")
                        .font(.system(size: 14, weight: .black))
                        .kerning(2)
                        .foregroundColor(.appPrimary)
                    
                    Text("Select all that match your current mood. This helps us find the perfect movie for your night.")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 24)
                .padding(.bottom, 24)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        ForEach(groups, id: \.0) { title, options in
                            VStack(alignment: .leading, spacing: 16) {
                                Text(title)
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.white.opacity(0.3))
                                    .padding(.horizontal, 4)
                                
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                    ForEach(options, id: \.self) { vibe in
                                        let isSelected = viewModel.selectedVibes.contains(vibe)
                                        
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                viewModel.toggleVibe(vibe)
                                            }
                                        }) {
                                            Text(vibe.uppercased())
                                                .font(.system(size: 13, weight: .black))
                                                .kerning(1)
                                                .foregroundColor(isSelected ? .black : .white)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 56)
                                                .background(isSelected ? Color.appPrimary : Color.white.opacity(0.03))
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(isSelected ? Color.appPrimary : Color.white.opacity(0.05), lineWidth: 1)
                                                )
                                                .scaleEffect(isSelected ? 0.98 : 1.0)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            
            // Footer
            VStack {
                Spacer()
                Button(action: { 
                    withAnimation {
                        viewModel.moveToNextStep()
                    }
                }) {
                    Text("CONTINUE")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(viewModel.isStep7Valid ? .black : .white.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.isStep7Valid ? Color.appPrimary : Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: viewModel.isStep7Valid ? Color.appPrimary.opacity(0.3) : .clear, radius: 10, y: 5)
                }
                .disabled(!viewModel.isStep7Valid)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0), .black.opacity(0.8), .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
