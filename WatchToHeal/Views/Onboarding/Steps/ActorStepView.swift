import SwiftUI

struct ActorStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
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
                    Text("WHOSE MOVIES DO YOU ENJOY?")
                        .font(.system(size: 14, weight: .black))
                        .kerning(2)
                        .foregroundColor(.appPrimary)
                    
                    Text("Pick any actors or directors you love. If you're not sure, feel free to skip.")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 24)
                .padding(.bottom, 24)
                
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.appPrimary)
                    
                    TextField("Search actors, directors, or creators...", text: $viewModel.actorSearchQuery)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .tint(.appPrimary)
                        .onChange(of: viewModel.actorSearchQuery) { query in
                            viewModel.searchPeople(query: query)
                        }
                        .autocapitalization(.none)
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                if viewModel.isLoading && viewModel.actorSearchQuery.isEmpty {
                     Spacer()
                     ProgressView().tint(.appPrimary)
                     Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        let peopleToShow = !viewModel.actorSearchQuery.isEmpty ? viewModel.searchedPeople : viewModel.popularActors
                        
                        if peopleToShow.isEmpty && !viewModel.actorSearchQuery.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.fill.questionmark")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.1))
                                Text("No creators found")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(.top, 60)
                        } else {
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(peopleToShow) { person in
                                    let isSelected = viewModel.selectedActors.contains(person.id)
                                    
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            viewModel.toggleActor(id: person.id)
                                        }
                                    }) {
                                        VStack(spacing: 12) {
                                            ZStack(alignment: .bottomTrailing) {
                                                CachedAsyncImage(url: person.profileURL) { image in
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                } placeholder: {
                                                    Circle().fill(Color.white.opacity(0.05))
                                                }
                                                .frame(width: 90, height: 90)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 3)
                                                )
                                                .grayscale(isSelected ? 0 : 0.4)
                                                .scaleEffect(isSelected ? 0.95 : 1.0)
                                                
                                                if isSelected {
                                                    ZStack {
                                                        Circle()
                                                            .fill(Color.appPrimary)
                                                            .frame(width: 24, height: 24)
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 12, weight: .black))
                                                            .foregroundColor(.black)
                                                    }
                                                    .transition(.scale.combined(with: .opacity))
                                                }
                                            }
                                            
                                            Text(person.name)
                                                .font(.system(size: 12, weight: .black))
                                                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .frame(height: 32, alignment: .top)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.top, 8)
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
                    let hasSelection = !viewModel.selectedActors.isEmpty
                    
                    Text(hasSelection ? "CONTINUE" : "SKIP FOR NOW")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(hasSelection ? .black : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(hasSelection ? Color.appPrimary : Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: hasSelection ? Color.appPrimary.opacity(0.3) : .clear, radius: 10, y: 5)
                }
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
