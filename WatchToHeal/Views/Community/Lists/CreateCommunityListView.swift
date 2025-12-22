import SwiftUI

struct CreateCommunityListView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = CommunityListsViewModel()
    @State private var showMoviePicker = false
    @State private var showCelebration = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Premium Header
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appTextSecondary)
                    
                    Spacer()
                    
                    Text("CREATE NEW LIST")
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundColor(.appPrimary)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveList()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appPrimary)
                    .disabled(viewModel.title.isEmpty || viewModel.isSaving)
                    .opacity(viewModel.title.isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Input Fields
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TITLE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.appPrimary)
                                
                                TextField("e.g. Cinema Masterpieces", text: $viewModel.title)
                                    .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 32))
                                    .foregroundColor(.appText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                
                                Divider().background(Color.white.opacity(0.1))
                            }
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("DESCRIPTION")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.appPrimary)
                                
                                TextEditor(text: $viewModel.description)
                                    .frame(height: 80)
                                    .font(.system(size: 16))
                                    .scrollContentBackground(.hidden)
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(12)
                                    .foregroundColor(.appText)
                            }
                            
                            // Ranked Toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("RANKED LIST")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(.white)
                                    Text("Large numbers will appear next to movies")
                                        .font(.system(size: 11))
                                        .foregroundColor(.appTextSecondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $viewModel.isRanked)
                                    .toggleStyle(SwitchToggleStyle(tint: .appPrimary))
                                    .labelsHidden()
                            }
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
                            
                            // Tags Input (Simulation for now)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TAGS")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.appPrimary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(["#MustWatch", "#Classic", "#BingeMode", "#Masterpiece"], id: \.self) { tag in
                                            Button(action: {
                                                if viewModel.tags.contains(tag) {
                                                    viewModel.tags.removeAll { $0 == tag }
                                                } else {
                                                    viewModel.tags.append(tag)
                                                }
                                            }) {
                                                Text(tag)
                                                    .font(.system(size: 12, weight: .bold))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(viewModel.tags.contains(tag) ? Color.appPrimary : Color.white.opacity(0.05))
                                                    .foregroundColor(viewModel.tags.contains(tag) ? .black : .white.opacity(0.6))
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Movie Curation Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("MOVIES")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.appPrimary)
                                
                                Spacer()
                                
                                Button(action: { showMoviePicker = true }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus")
                                        Text("Add Movie")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.appPrimary))
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            if viewModel.selectedMovies.isEmpty {
                                EmptyListView { showMoviePicker = true }
                            } else {
                                draggableMovieList
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
            
            if viewModel.isSaving {
                Color.black.opacity(0.6).ignoresSafeArea()
                ProgressView("Curating your masterpiece...")
                    .tint(.appPrimary)
                    .foregroundColor(.white)
            }
            
            if showCelebration {
                LottieView(name: "congratulation") {
                    // Animation finished
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $showMoviePicker) {
            MoviePickerView(
                suggestions: viewModel.suggestions,
                selectedMovies: viewModel.selectedMovies,
                onToggle: { movie in
                    viewModel.toggleSelection(movie)
                }
            )
        }
        .onAppear {
            Task {
                await viewModel.fetchSuggestions()
            }
        }
        .alert("Error", isPresented: .init(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private var draggableMovieList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.selectedMovies) { movie in
                HStack(spacing: 16) {
                    if let url = movie.posterURL {
                        CachedAsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.appCardBackground
                        }
                        .frame(width: 40, height: 60)
                        .cornerRadius(6)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(movie.displayName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.appText)
                        Text(movie.year)
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if let index = viewModel.selectedMovies.firstIndex(where: { $0.id == movie.id }) {
                            viewModel.selectedMovies.remove(at: index)
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04)))
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func saveList() {
        guard let profile = appViewModel.userProfile else { return }
        Task {
            let success = await viewModel.createList(ownerId: profile.id, ownerName: profile.name)
            if success {
                withAnimation { showCelebration = true }
                // Delay dismissal to show confetti
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                dismiss()
            }
        }
    }
}

struct EmptyListView: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: "film.stack")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.1))
                Text("Your collection is empty.\nTap to add your first movie.")
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .background(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.05), style: StrokeStyle(lineWidth: 1, dash: [4])))
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    CreateCommunityListView()
        .environmentObject(AppViewModel())
}
