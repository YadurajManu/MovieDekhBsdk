import SwiftUI

struct AdminPollCreateView: View {
    @Environment(\.dismiss) var dismiss
    var onCreated: () -> Void
    
    @State private var question: String = ""
    @State private var pollType: PollType = .text
    @State private var expiresAt: Date = Date().addingTimeInterval(86400 * 3) // Default 3 days
    
    struct PollOption: Identifiable {
        let id = UUID()
        var text: String
        var movieId: Int?
        var posterPath: String?
        var secondaryInfo: String?
    }
    
    @State private var options: [PollOption] = [PollOption(text: ""), PollOption(text: "")]
    @State private var isSubmitting = false
    
    // Search related
    @State private var searchText = ""
    @State private var searchResults: [Movie] = []
    @State private var activeSearchIndex: Int? = nil
    
    var isFormValid: Bool {
        !question.isEmpty && options.count >= 2 && options.allSatisfy { !$0.text.isEmpty }
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                header
                formContent
                publishButton
            }
        }
        .overlay {
            if let index = activeSearchIndex {
                movieSearchOverlay(for: index)
            }
        }
    }
    
    private var backgroundGradient: some View {
        MeshGradient(width: 3, height: 3, points: [
            [0, 0], [0.5, 0], [1, 0],
            [0, 0.5], [0.5, 0.5], [1, 0.5],
            [0, 1], [0.5, 1], [1, 1]
        ], colors: [
            .black, .black, .black,
            Color(hex: "050505"), .black, Color(hex: "0A0A0A"),
            Color.appPrimary.opacity(0.1), .black, .black
        ])
        .ignoresSafeArea()
    }
    
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appPrimary)
            }
            
            Spacer()
            
            Text("NEW PULSE")
                .font(.system(size: 14, weight: .black))
                .tracking(3)
                .foregroundColor(.appText)
            
            Spacer()
            
            Text("Cancel").opacity(0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
    
    private var formContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                typeAndExpirySection
                questionSection
                optionsSection
            }
            .padding(24)
        }
    }
    
    private var typeAndExpirySection: some View {
        VStack(spacing: 20) {
            Picker("Poll Type", selection: $pollType) {
                Text("Text Debate").tag(PollType.text)
                Text("Movie Battle").tag(PollType.movie)
            }
            .pickerStyle(.segmented)
            .colorMultiply(.appPrimary)
            
            DatePicker("Ends On", selection: $expiresAt, displayedComponents: [.date, .hourAndMinute])
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appText)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
        }
    }
    
    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THE DEBATE")
                .font(.system(size: 11, weight: .black))
                .tracking(2)
                .foregroundColor(.appPrimary)
            
            ZStack(alignment: .topLeading) {
                if question.isEmpty {
                    Text("What's the community's take on...")
                        .font(.system(size: 16))
                        .foregroundColor(.appTextSecondary.opacity(0.4))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }
                
                TextEditor(text: $question)
                    .frame(height: 100)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(20)
                    .foregroundColor(.appText)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
        }
    }
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("VOTING CHOICES")
                    .font(.system(size: 11, weight: .black))
                    .tracking(2)
                    .foregroundColor(.appPrimary)
                Spacer()
                Button(action: { 
                    withAnimation(.spring()) {
                        options.append(PollOption(text: "")) 
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.appPrimary)
                }
            }
            
            ForEach($options) { $option in
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        if pollType == .movie {
                            Button(action: { 
                                activeSearchIndex = options.firstIndex(where: { $0.id == option.id })
                            }) {
                                if let poster = option.posterPath {
                                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w92\(poster)")) { img in
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.white.opacity(0.1)
                                    }
                                    .frame(width: 44, height: 60)
                                    .cornerRadius(8)
                                } else {
                                    Image(systemName: "film.fill")
                                        .foregroundColor(.appPrimary)
                                        .frame(width: 44, height: 60)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        TextField(pollType == .movie ? "Search movie..." : "Enter option", text: $option.text)
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(16)
                            .foregroundColor(.appText)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        
                        if options.count > 2 {
                            Button(action: { 
                                if let index = options.firstIndex(where: { $0.id == option.id }) {
                                    withAnimation(.spring()) {
                                        options.remove(at: index)
                                    }
                                }
                            }) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red.opacity(0.6))
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(Color.red.opacity(0.1)))
                            }
                        }
                    }
                    
                    if let secondary = option.secondaryInfo {
                        Text(secondary)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, pollType == .movie ? 56 : 16)
                    }
                }
            }
        }
    }
    
    private func movieSearchOverlay(for index: Int) -> some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack {
                HStack {
                    TextField("Search movies...", text: $searchText)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { newValue in
                            searchMovies(query: newValue)
                        }
                    
                    Button("Done") {
                        activeSearchIndex = nil
                        searchText = ""
                        searchResults = []
                    }
                    .foregroundColor(.appPrimary)
                }
                .padding()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults, id: \.id) { movie in
                            Button(action: {
                                options[index].text = movie.displayName
                                options[index].movieId = movie.id
                                options[index].posterPath = movie.posterPath
                                options[index].secondaryInfo = String(movie.displayDate.prefix(4))
                                activeSearchIndex = nil
                                searchText = ""
                                searchResults = []
                            }) {
                                HStack(spacing: 16) {
                                    if let poster = movie.posterPath {
                                        AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w92\(poster)")) { img in
                                            img.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.white.opacity(0.1)
                                        }
                                        .frame(width: 50, height: 75)
                                        .cornerRadius(8)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(movie.displayName)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                        if !movie.displayDate.isEmpty {
                                            Text(movie.displayDate.prefix(4))
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func searchMovies(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        Task {
            do {
                let movies = try await TMDBService.shared.searchMovies(query: query)
                await MainActor.run {
                    self.searchResults = movies
                }
            } catch {
                print("Search error: \(error)")
            }
        }
    }
    
    private var publishButton: some View {
        VStack(spacing: 12) {
            Button(action: createPoll) {
                HStack(spacing: 12) {
                    if isSubmitting {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "bolt.fill")
                        Text("ACTIVATE GLOBAL PULSE")
                    }
                }
                .font(.system(size: 14, weight: .black))
                .tracking(1)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(isFormValid ? Color.appPrimary : Color.white.opacity(0.1))
                .cornerRadius(30)
                .shadow(color: isFormValid ? Color.appPrimary.opacity(0.3) : .clear, radius: 15)
            }
            .disabled(!isFormValid || isSubmitting)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
    
    private func createPoll() {
        isSubmitting = true
        let pollOptions = options.map { 
            PollOptionData(
                text: $0.text,
                movieId: $0.movieId,
                posterPath: $0.posterPath,
                secondaryInfo: $0.secondaryInfo
            )
        }
        
        let newPoll = MoviePoll(
            id: nil,
            question: question,
            options: pollOptions,
            votes: Array(repeating: 0, count: pollOptions.count),
            votedUserIds: [],
            createdAt: Date(),
            expiresAt: expiresAt,
            isFinalized: false,
            type: pollType,
            creatorId: nil,
            creatorName: nil,
            creatorUsername: nil,
            creatorPhotoURL: nil,
            likedUserIds: [],
            category: pollType == .movie ? "Battle" : "Official",
            engagementScore: 0.0,
            lastActivityAt: Date(),
            globalMovieId: nil,
            globalMovieTitle: nil
        )
        
        Task {
            do {
                try await FirestoreService.shared.createPoll(poll: newPoll)
                await MainActor.run {
                    onCreated()
                    dismiss()
                }
            } catch {
                print("Error creating poll: \(error)")
                isSubmitting = false
            }
        }
    }
}
