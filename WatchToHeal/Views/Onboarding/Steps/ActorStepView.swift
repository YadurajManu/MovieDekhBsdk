import SwiftUI

struct ActorStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Whose movies do you usually enjoy?")
                .font(.title3)
                .bold()
                .multilineTextAlignment(.center)
                .foregroundColor(.appText)
                .padding(.top)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.appTextSecondary)
                
                TextField("Search actors, directors...", text: $viewModel.actorSearchQuery)
                    .foregroundColor(.appText)
                    .onChange(of: viewModel.actorSearchQuery) { query in
                        viewModel.searchPeople(query: query)
                    }
                    .autocapitalization(.none)
            }
            .padding(12)
            .background(Color.appCardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
            
            if viewModel.isLoading && !viewModel.popularActors.isEmpty {
                 // Initial load loading
                 Spacer()
                 ProgressView()
                 Spacer()
            } else {
                ScrollView {
                    let peopleToShow = !viewModel.actorSearchQuery.isEmpty ? viewModel.searchedPeople : viewModel.popularActors
                    
                    if peopleToShow.isEmpty && !viewModel.actorSearchQuery.isEmpty {
                        Text("No results found")
                            .foregroundColor(.appTextSecondary)
                            .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(peopleToShow) { person in
                                Button(action: {
                                    viewModel.toggleActor(id: person.id)
                                }) {
                                    VStack {
                                        CachedAsyncImage(url: person.profileURL) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Circle().fill(Color.gray.opacity(0.3))
                                        }
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(viewModel.selectedActors.contains(person.id) ? Color.appPrimary : Color.clear, lineWidth: 3)
                                        )
                                        
                                        Text(person.name)
                                            .font(.caption)
                                            .foregroundColor(.appTextSecondary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            
            Button(action: { viewModel.moveToNextStep() }) {
                Text("Next")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appPrimary)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .padding([.horizontal, .bottom])
        }
    }
}
