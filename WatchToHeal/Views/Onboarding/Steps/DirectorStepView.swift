import SwiftUI

struct DirectorStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Do any of these directors excite you?")
                    .font(.title3)
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.appText)
                Text("Tap the ones you know and love.")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.top)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.appTextSecondary)
                
                TextField("Search directors...", text: $viewModel.actorSearchQuery)
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
            
            if viewModel.isLoading && viewModel.searchedPeople.isEmpty {
                 Spacer()
                 ProgressView()
                 Spacer()
            } else {
                ScrollView {
                    // shared search results or suggestions.
                    // For directors, we might not have a "popular directors" list pre-fetched in ViewModel
                    // So we rely on Search mainly, or show nothing initially.
                    // But to be "aesthetic" and "vibe", let's show searchedPeople only if searching.
                    
                    if viewModel.actorSearchQuery.isEmpty {
                        VStack(spacing: 20) {
                            Text("Search for your favorite directors\n(e.g. Christopher Nolan, Greta Gerwig)")
                                .multilineTextAlignment(.center)
                                .font(.system(size: 14))
                                .foregroundColor(.appTextSecondary.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)
                        }
                    } else if viewModel.searchedPeople.isEmpty {
                         Text("No results found")
                            .foregroundColor(.appTextSecondary)
                            .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(viewModel.searchedPeople) { person in
                                Button(action: {
                                    viewModel.toggleDirector(id: person.id)
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
                                                .stroke(viewModel.selectedDirectorIds.contains(person.id) ? Color.appPrimary : Color.clear, lineWidth: 3)
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
